#!/usr/bin/env perl

$::RD_TRACE=1;

use AzureARM;
use Test::More;
use Data::Dumper;

my $arm = AzureARM->new;

{
  my $expression = "A String";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::String');
  cmp_ok($exp->Value, 'eq', 'A String');
}

{
  my $expression = "[variables('var1')]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::Function');
  cmp_ok($exp->Function, 'eq', 'variables');
}

{
  my $expression = "[concat(variables('var1'), '-POSTFIX')]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM::Expression::Function');
  cmp_ok($exp->Function, 'eq', 'concat');
  isa_ok($exp->Parameters->[0], 'AzureARM::Expression::Function');
  cmp_ok($exp->Parameters->[0]->Function, 'eq', 'variables');
  isa_ok($exp->Parameters->[1], 'AzureARM::Expression::String');
  cmp_ok($exp->Parameters->[1]->Value, 'eq', '-POSTFIX');
}


{
  my $expression = "[greaterOrEquals(parameters('firstInt'), parameters('secondInt') )]";
  diag($expression);
  my $exp = $arm->parse_expression($expression);
  isa_ok($exp, 'AzureARM');
  print Dumper($exp);
}

{
  my $exp = $arm->parse_expression("[createArray(1, 2, 3)]");
  isa_ok($exp, 'AzureARM');
  print Dumper($exp);
}

{
  my $exp = $arm->parse_expression("[subscription()]");
  isa_ok($exp, 'AzureARM');
  print Dumper($exp);
}

#TODO:
#"[uniqueString(subscription().subscriptionId)]"

done_testing;
