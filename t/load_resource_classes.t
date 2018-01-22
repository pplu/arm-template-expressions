#!/usr/bin/env perl

use Test::More;
use Module::Find;
use AzureARM::Parser;

use lib '../auto-lib';

my @modules = Module::Find::findallmod 'AzureARM::Resource';

foreach my $mod (@modules) {
  AzureARM::Parser->load_resource_class($mod);
  ok(1, "Load $mod");
}

done_testing;
