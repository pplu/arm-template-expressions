#!/usr/bin/env perl

use strict;
use warnings;
use feature 'postderef';

use Test::More;
use Test::Exception;
use File::Find;
use Path::Class::File;
use JSON::MaybeXS;

my @files;

if (@ARGV) {
  @files = @ARGV;
} else {
  File::Find::find({wanted => \&wanted}, 't/azure-examples/');
  sub wanted {
      /^azuredeploy\.json\z/s
      && push @files, $File::Find::name;
  }
}

use AzureARM::Parser;

my $p = AzureARM::Parser->new;

my $compare_str = sub {
  my ($gen, $ori) = @_;

  if (not defined $gen and not defined $ori) {
    pass "generated and original are undefined";
  } elsif (defined $gen and not defined $ori) {
    fail "generated is $gen and original is undefined";
  } elsif (not defined $gen and defined $ori) {
    fail "generated is not defined and original $ori";
  } else {
    cmp_ok($gen, 'eq', $ori);
  }
};

my $compare_deeply = sub {
  my ($gen, $ori) = @_;
  is_deeply($gen, $ori);
};

foreach my $file_name (@files) {
  diag($file_name);
  my $file = Path::Class::File->new($file_name);
  my $content = $file->slurp;
  my $origin = decode_json($content);
  my $arm;

  lives_ok sub { $arm = $p->from_json($content) }, "Parsed $file_name";

  cmp_ok($arm->VariableCount,  '==', keys %{ $origin->{ variables }  // {} }, 'Got the same number of variables');
  cmp_ok($arm->ParameterCount, '==', keys %{ $origin->{ parameters } // {} }, 'Got the same number of parameters');
  cmp_ok($arm->OutputCount,    '==', keys %{ $origin->{ outputs }    // {} }, 'Got the same number of outputs');
  cmp_ok($arm->ResourceCount,  '==', @{ $origin->{ resources } }, 'Got the same number of resources');

  my $generated = $arm->as_hashref;

  my $resource_compare = {
    copy => sub {
      my ($gen, $ori) = @_;
      $compare_str->($gen->{name}, $ori->{name});
      equiv_expression($gen->{count}, $ori->{count});
      $compare_str->($gen->{mode}, $ori->{mode});
      $compare_str->($gen->{batchSize}, $ori->{batchSize});
    },
    name => $compare_str,
    type => $compare_str,
    properties => $compare_deeply,
    apiVersion => $compare_str,
    location => $compare_str,
    dependsOn => $compare_deeply,
    kind => $compare_str,
    id => $compare_str,
    resourceGroup => $compare_str,
    comments => $compare_str,
    sku => $compare_deeply,
    identity => $compare_deeply,
    plan => $compare_deeply,
    tags => $compare_deeply,
    zones => sub {
      my ($gen, $ori) = @_;
      if (ref($gen) eq 'ARRAY') {
        is_deeply($gen, $ori);
      } else {
        equiv_expression($gen, $ori, "Expressions are equivalent");
      }
    },
    condition => sub { my ($gen, $ori) = @_; equiv_expression($gen, $ori, "Expressions are equivalent"); },
    resources => sub {
      my ($gen, $ori) = @_;
      my $i = 0;
      return if (not defined $gen and not defined $ori);
      foreach my $i (1..@$gen) {
        is_deeply($gen->[$i], $ori->[$i]);
      }
    },
  };

  cmp_ok($generated->{ resources }->@*, '==', $origin->{ resources }->@*, 'Got the same resources once parsed');
  for (my $i=0; $i <= $generated->{ resources }->@*; $i++) {
    my $generated_r = $generated->{ resources }->[$i];
    my $origin_r    = $origin->{ resources }->[$i];

use Data::Dumper;
    my $seen = { map { ($_ => 0) } keys %$generated_r };
    cmp_ok(keys %$generated_r, '==', keys %$origin_r, "Equal number of attributes resource $i");
    foreach my $k (keys %$resource_compare) {
      $resource_compare->{ $k }->($generated_r->{ $k }, $origin_r->{ $k });
      delete $seen->{ $k };
    }
    cmp_ok(keys %$seen, '==', 0, 'Compared all attributes ' . (join ',', keys %$seen));
  }

  is_deeply($generated->{ parameters }, $origin->{ parameters }, 'Got the same parameters once parsed');

  cmp_ok(keys %{ $generated->{ outputs } // {} }, '==', keys %{ $origin->{ outputs } // {} }, 'Got the same number of outputs');
  foreach my $out (keys $generated->{ outputs }->%*) {
    equiv_expression($generated->{ outputs }->{ $out }->{ value }, $origin->{ outputs }->{ $out }->{ value }, "Output $out value is equivalent once parsed");
    cmp_ok($generated->{ outputs }->{ $out }->{ type }, 'eq', $origin->{ outputs }->{ $out }->{ type }, "Output $out type is equivalent once parsed");
  }

  cmp_ok(keys %{ $generated->{ variables } // {} }, '==', keys %{ $origin->{ variables } // {} }, 'Got the same number of variables');
  foreach my $var (keys $generated->{ variables }->%*) {
    equiv_expression($generated->{ variables }->{ $var }, $origin->{ variables }->{ $var }, "Var $var is equivalent once parsed");
  }
  #$arm->variables
}

sub equiv_expression {
  my ($expr1, $expr2, $text) = @_;
  if (not defined $expr1 and not defined $expr1) {
    ok(1, $text);
    return;
  } elsif (defined $expr1 xor defined $expr2) {
    ok(0, $text);
    return;
  }

  $expr1 =~ s/\s//g;
  $expr2 =~ s/\s//g;
  if (ref($expr1) eq 'HASH' or ref($expr1) eq 'ARRAY') {
    is_deeply($expr1, $expr2, $text);
  } else {
    cmp_ok($expr1, 'eq', $expr2, $text); 
  }
}

done_testing;
