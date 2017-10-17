package AzureARM::Value {
  use Moose;
   has Value => (
    is => 'ro',
  );

  sub as_hashref {
    my $self = shift;
    return $self->Value;
  }
}
package AzureARM::Expression {
  use Moose;
  extends 'AzureARM::Value';
  has '+Value' => (
    isa => 'AzureARM::Expression',
  );
}
package AzureARM::Expression::Array {
  use Moose;
  extends 'AzureARM::Expression';
  has '+Value' => (isa => 'ArrayRef[AzureARM::Expression]');
}
package AzureARM::Expression::FirstLevel {
  use Moose;
  extends 'AzureARM::Expression';

  has '+Value' => (isa => 'AzureARM::Expression');
  
  sub as_string {
    my $self = shift;
    return '[' . $self->Value->as_string . ']';
  }

  sub as_hashref {
    my $self = shift;
    return $self->as_string;
  }
}
package AzureARM::Expression::Function {
  use Moose;
  extends 'AzureARM::Expression';
  use feature 'postderef';

  has 'Function' => (is => 'ro', isa => 'Str', required => 1);
  has 'Parameters' => (is => 'ro', isa => 'ArrayRef[AzureARM::Expression]');
  has '+Value' => (isa => '');

  sub as_string {
    my $self = shift;
    return join '', $self->Function, '(', (join ', ', map { $_->as_string } $self->Parameters->@*), ')'
  };
}
package AzureARM::Expression::String {
  use Moose;
  extends 'AzureARM::Expression';
  has '+Value' => (isa => 'Str');

  sub as_string {
    my $self = shift;
    return "'" . $self->Value . "'";
  }
}
package AzureARM::Expression::Integer {
  use Moose;
  extends 'AzureARM::Expression';
  has '+Value' => (isa => 'Str');

  sub as_string {
    my $self = shift;
    return $self->Value;
  }
}
package AzureARM {
  use Moose;
  use feature 'postderef';

  has variables => (
    is => 'ro',
    isa => 'HashRef[AzureARM::Value]',
    traits => [ 'Hash' ],
    handles => {
      VariableCount => 'count',
      VariableNames => 'keys',
      Variable => 'accessor',
    }
  );

  sub as_hashref {
    my $self = shift;
    my $hashref = {};
    if (defined $self->variables) {
      my $v = $hashref->{ variables } = {};
      foreach my $k ($self->VariableNames) {
        $v->{ $k } = $self->Variable($k)->as_hashref;
      }
    }
    return $hashref;
  }

  sub from_hashref {
    my ($class, $hashref) = @_;
    my $self = $class->new;

    my @args;

    my $variables;
    if (defined $hashref->{ variables }) {
      $variables = {};
      foreach my $var_name (keys $hashref->{ variables }->%*) {
        $variables->{ $var_name } = $self->parse_expression(
          $hashref->{ variables }->{ $var_name }
        );
      }
      push @args, variables => $variables;
    }
    
    $class->new(@args);
  }

  sub parse_expression {
    my ($self, $string) = @_;
   
    if (my $tree = $self->_parser->startrule($string)) {
      return $tree;
    } else {
      return AzureARM::Value->new(
        Value => $string
      );
    }
  }

  use Parse::RecDescent;

  our $grammar = q#
startrule: '[' functioncall ']' 
 { $return = AzureARM::Expression::FirstLevel->new(Value => $item{ functioncall }) }
functioncall: functionname '(' parameter(s? /,/) ')'
 { $return = AzureARM::Expression::Function->new(Parameters => $item{'parameter(s?)'}, Function => $item{ functionname }) }
stringliteral: /'/ /[^']+/ /'/
 { $return = AzureARM::Expression::String->new(Value => $item{ __PATTERN2__ } ) }
numericliteral: /\d+/
 { $return = AzureARM::Expression::Integer->new(Value => $item{ __PATTERN1__ } ) }
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
