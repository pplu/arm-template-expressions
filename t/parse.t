#!/usr/bin/env perl

use strict;
use warnings;

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

use Data::Dumper;
print Dumper(\@files);

use AzureARM;
foreach my $file_name (@files) {
  diag($file_name);
  my $file = Path::Class::File->new($file_name);
  my $content = $file->slurp;
  my $struct = decode_json($content);
  my $arm;
  lives_ok sub { $arm = AzureARM->from_hashref($struct) }, "Parsed $file";
  cmp_ok($arm->VariableCount, '==', keys %{ $struct->{ variables } // {} }, 'Got the same number of variables');

  #$arm->variables
}

done_testing;
