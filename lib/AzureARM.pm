package AzureARM::Expression {
  use Moose;
  has Value => (
    is => 'ro',
    isa => 'AzureARM::Expression',
    #required => 1
  );
}
package AzureARM::Expression::Array {
  use Moose;
  extends 'AzureARM::Expression';
  has '+Value' => (isa => 'ArrayRef[AzureARM::Expression]');
}
package AzureARM::Expression::Function {
  use Moose;
  extends 'AzureARM::Expression';
  has 'Function' => (is => 'ro', isa => 'Str', required => 1);
  has 'Parameters' => (is => 'ro', isa => 'ArrayRef[AzureARM::Expression]');
  has '+Value' => (isa => '');
}
package AzureARM::Expression::String {
  use Moose;
  extends 'AzureARM::Expression';
  has '+Value' => (isa => 'Str');
}
package AzureARM::Expression::Integer {
  use Moose;
  extends 'AzureARM::Expression';
  has '+Value' => (isa => 'Str');
}
package AzureARM {
  use Moose;
  use feature 'postderef';

  has variables => (
    is => 'ro',
    isa => 'HashRef[AzureARM::Expression]',
  );

  sub from_hashref {
    my ($class, $hashref) = @_;
    my $self = $class->new;

    my $variables;
    if (defined $hashref->{ variables }) {
      $variables = {};
      foreach my $var_name (keys $hashref->{ variables }->%*) {
        $variables->{ $var_name } = $self->parse_expression(
          $hashref->{ variables }->{ $var_name }
        );
      }
    }
    
    $class->new(variables => $variables);
  }

  sub parse_expression {
    my ($self, $string) = @_;
   
    if (my $tree = $self->_parser->startrule($string)) {
      return $tree;
    } else {
      return AzureARM::Expression::String->new(
        Value => $string
      );
    }
  }

  use Parse::RecDescent;

  our $grammar = q#
startrule: '[' functioncall ']' 
 { $return = $item{ functioncall } }
functioncall: functionname '(' parameter(s? /,/) ')'
 { $return = AzureARM::Expression::Function->new(Parameters => $item{'parameter(s?)'}, Function => $item{ functionname }) }
stringliteral: /'\w+'/
 { $return = AzureARM::Expression::String->new(Value => $item{ __PATTERN1__ } ) }
numericliteral: /\d+/
 { $return = AzureARM::Expression::String->new(Value => $item{ __PATTERN1__ } ) }
functionname: /\w+/
 { $return = $item{ __PATTERN1__ } }
parameter: stringliteral | numericliteral | functioncall
 { $return = ($item{ stringliteral } or $item{ numericliteral } or $item{ functioncall }) }
#;

  has _parser => (is => 'ro', lazy => 1, default => sub {
    my $rd = Parse::RecDescent->new($grammar);
    die "Can't build RecDescent parser" if (not defined $rd);
    return $rd;
  });

}
1;
