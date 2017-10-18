#!/usr/bin/env perl

#$::RD_TRACE=1;

use strict;
use warnings;
use AzureARM;
use Test::More;
use Data::Dumper;

my $arm = AzureARM->new;

{
  my $expression = "[variables('var1')]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::FirstLevel');
  cmp_ok($exp->as_string, 'eq', $expression);
  $exp = $exp->Value;
  isa_ok($exp, 'AzureARM::Expression::Function');
  cmp_ok($exp->Function, 'eq', 'variables');
}

{
  my $expression = "[concat(variables('var1'), '-POSTFIX')]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::FirstLevel');
  cmp_ok($exp->as_string, 'eq', $expression);
  $exp = $exp->Value;
  isa_ok($exp, 'AzureARM::Expression::Function');
  cmp_ok($exp->Function, 'eq', 'concat');
  isa_ok($exp->Parameters->[0], 'AzureARM::Expression::Function');
  cmp_ok($exp->Parameters->[0]->Function, 'eq', 'variables');
  isa_ok($exp->Parameters->[1], 'AzureARM::Expression::String');
  cmp_ok($exp->Parameters->[1]->Value, 'eq', '-POSTFIX');
}


{
  my $expression = "[greaterOrEquals(parameters('firstInt'), parameters('secondInt'))]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::FirstLevel');
  cmp_ok($exp->as_string, 'eq', $expression);
  $exp = $exp->Value;
  isa_ok($exp, 'AzureARM::Expression::Function');
  cmp_ok($exp->Function, 'eq', 'greaterOrEquals');
  isa_ok($exp->Parameters->[0], 'AzureARM::Expression::Function');
  cmp_ok($exp->Parameters->[0]->Function, 'eq', 'parameters');
  cmp_ok($exp->Parameters->[0]->Parameters->[0]->Value, 'eq', 'firstInt');
  isa_ok($exp->Parameters->[1], 'AzureARM::Expression::Function');
  cmp_ok($exp->Parameters->[1]->Function, 'eq', 'parameters');
  cmp_ok($exp->Parameters->[1]->Parameters->[0]->Value, 'eq', 'secondInt');
}

{
  my $expression = "[createArray(1, 2, 3)]"; 
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::FirstLevel');
  cmp_ok($exp->as_string, 'eq', $expression);
  $exp = $exp->Value;
  isa_ok($exp, 'AzureARM::Expression::Function');
  cmp_ok($exp->Function, 'eq', 'createArray');
  isa_ok($exp->Parameters->[0], 'AzureARM::Expression::Integer');
  cmp_ok($exp->Parameters->[0]->Value, '==', 1);
  isa_ok($exp->Parameters->[1], 'AzureARM::Expression::Integer');
  cmp_ok($exp->Parameters->[1]->Value, '==', 2);
  isa_ok($exp->Parameters->[2], 'AzureARM::Expression::Integer');
  cmp_ok($exp->Parameters->[2]->Value, '==', 3);
}

{
  my $expression = "[subscription()]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::FirstLevel');
  cmp_ok($exp->as_string, 'eq', $expression);
  $exp = $exp->Value;
  isa_ok($exp, 'AzureARM::Expression::Function');
  cmp_ok($exp->Function, 'eq', 'subscription');
}

{
  my $expression = "[subscription().subscriptionId]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::FirstLevel');
  cmp_ok($exp->as_string, 'eq', $expression);
  $exp = $exp->Value;
  isa_ok($exp, 'AzureARM::Expression::AccessProperty');
  is_deeply($exp->Properties, [ 'subscriptionId' ]);
  cmp_ok($exp->On->Function, 'eq', 'subscription');
}

{
  my $expression = "[resourceGroup().name]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::FirstLevel');
  cmp_ok($exp->as_string, 'eq', $expression);
  $exp = $exp->Value;
  isa_ok($exp, 'AzureARM::Expression::AccessProperty');
  is_deeply($exp->Properties, [ 'name' ]);
  cmp_ok($exp->On->Function, 'eq', 'resourceGroup');
}

{
  my $expression = "[reference('xxx').dnsSettings.fqdn]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::FirstLevel');
  cmp_ok($exp->as_string, 'eq', $expression);
  $exp = $exp->Value;
  isa_ok($exp, 'AzureARM::Expression::AccessProperty');
  is_deeply($exp->Properties, [ 'dnsSettings', 'fqdn' ]);
  cmp_ok($exp->On->Function, 'eq', 'reference');
  cmp_ok($exp->On->Parameters->[0]->Value, 'eq', 'xxx');
}

{
  my $expression = "[reference('xxx').instanceView.statuses[0].message]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::FirstLevel');
  cmp_ok($exp->as_string, 'eq', $expression);
  $exp = $exp->Value;
  isa_ok($exp, 'AzureARM::Expression::AccessProperty');
  is_deeply($exp->Properties, [ 'instanceView', 'statuses[0]', 'message' ]);
  cmp_ok($exp->On->Function, 'eq', 'reference');
  cmp_ok($exp->On->Parameters->[0]->Value, 'eq', 'xxx');
}

done_testing;
