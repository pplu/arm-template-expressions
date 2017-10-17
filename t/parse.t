#!/usr/bin/env perl

use strict;
use warnings;
use feature 'postderef';

use Test::More;
use Test::Exception;
use File::Find;
use Path::Class::File;
use JSON::MaybeXS;

File::Find::find({wanted => \&wanted}, 't/azure-examples/');

my @files;
sub wanted {
    /^azuredeploy\.json\z/s
    && push @files, $File::Find::name;
}

use AzureARM;

foreach my $file_name (@files) {
  diag($file_name);
  my $file = Path::Class::File->new($file_name);
  my $content = $file->slurp;
  my $origin = decode_json($content);
  my $arm;

  lives_ok sub { $arm = AzureARM->from_hashref($origin) }, "Parsed $file";

  cmp_ok($arm->VariableCount,  '==', keys %{ $origin->{ variables }  // {} }, 'Got the same number of variables');
  cmp_ok($arm->ParameterCount, '==', keys %{ $origin->{ parameters } // {} }, 'Got the same number of parameters');
  cmp_ok($arm->OutputCount,    '==', keys %{ $origin->{ outputs }    // {} }, 'Got the same number of outputs');

  my $generated = $arm->as_hashref;

  is_deeply($generated->{ parameters }, $origin->{ parameters }, 'Got the same parameters once parsed');
  is_deeply($generated->{ outputs }, $origin->{ outputs }, 'Got the same outputs once parsed');

  cmp_ok(keys %{ $generated->{ variables } // {} }, '==', keys %{ $origin->{ variables } // {} }, 'Got the same number of variables');
  foreach my $var (keys $generated->{ variables }->%*) {
    equiv_expression($generated->{ variables }->{ $var }, $origin->{ variables }->{ $var }, "Var $var is equivalent once parsed");
  }
  #$arm->variables
}

sub equiv_expression {
  my ($expr1, $expr2, $text) = @_;
  $expr1 =~ s/\s//g;
  $expr2 =~ s/\s//g;
  cmp_ok($expr1, 'eq', $expr2, $text); 
}

done_testing;
