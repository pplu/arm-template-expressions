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
package AzureARM::Value::Integer {
  use Moose;
  extends 'AzureARM::Value';
  has '+Value' => (
    isa => 'Int'
  );
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
package AzureARM::Expression::AccessProperty {
  use Moose;
  extends 'AzureARM::Expression';
  use feature 'postderef';

  has Properties => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, traits => [ 'Array' ], handles => { NumProperties => 'count' });
  has On => (is => 'ro', isa => 'AzureARM::Expression', required => 1);

  sub as_string {
    my $self = shift;
    my $str = $self->On->as_string;
    $str .= '.' . (join '.', $self->Properties->@*) if ($self->NumProperties > 0);
    return $str;
  }
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
package AzureARM::Parameter {
  use Moose;
  use MooseX::StrictConstructor;
  use Moose::Util::TypeConstraints qw/enum/;

  enum 'AzureARM::Parameter::Types', [qw/string String SecureString securestring int Int bool Bool object secureObject array/ ];

  has type => (is => 'ro', required => 1, isa => 'AzureARM::Parameter::Types');
  has defaultValue => (is => 'ro');
  has allowedValues => (is => 'ro', isa => 'ArrayRef');
  has minValue => (is => 'ro', isa => 'Int');
  has maxValue => (is => 'ro', isa => 'Int');
  has minLength => (is => 'ro', isa => 'Int');
  has maxLength => (is => 'ro', isa => 'Int');
  has metadata => (is => 'ro');

  sub as_hashref {
    my $self = shift;
    return {
      map { ($_ => $self->$_) } grep { defined $self->$_ } map { $_->name } $self->meta->get_all_attributes
    }
  }
}
package AzureARM::Output {
  use Moose;
  use MooseX::StrictConstructor;

  has type => (is => 'ro', required => 1, isa => 'AzureARM::Parameter::Types');
  has value => (is => 'ro', required => 1, isa => 'AzureARM::Expression::FirstLevel|AzureARM::Value');

  sub as_hashref {
    my $self = shift;
    return {
      type => $self->type,
      value => $self->value->as_hashref,
    }
  }
}
package AzureARM::ResourceCopy {
  use Moose;
  use Moose::Util::TypeConstraints qw/enum/;
  enum 'AzureARM::ResourceCopy::Modes' => [ 'serial', 'parallel' ];
  has name => (is => 'ro', isa => 'Str', required => 1);
  has count => (is => 'ro', isa => 'AzureARM::Expression::FirstLevel|AzureARM::Value::Integer', required => 1);
  has mode => (is => 'ro', isa => 'AzureARM::ResourceCopy::Modes');
  has batchSize => (is => 'ro', isa => 'AzureARM::Value::Integer');

  sub as_hashref {
    my $self = shift;
    return {
      name => $self->name,
      count => $self->count->as_hashref,
      mode => $self->mode,
      batchSize => $self->batchSize,
    }
  }
}
package AzureARM::Resource {
  use Moose;

  has condition => (is => 'ro', isa => 'AzureARM::Expression::FirstLevel');
  has apiVersion => (is => 'ro', isa => 'Str', required => 1);
  has type => (is => 'ro', isa => 'Str', required => 1);
  has name => (is => 'ro', isa => 'Str', required => 1);
  has location => (is => 'ro', isa => 'Str');
  has tags => (is => 'ro', isa => 'HashRef'); 
  has comments => (is => 'ro', isa => 'Str');
  has copy => (is => 'ro', isa => 'AzureARM::ResourceCopy');
  has dependsOn => (is => 'ro', isa => 'ArrayRef[Str]');

  #properties
  #resources

  sub as_hashref {
    my $self = shift;
    return {
      condition => $self->condition->as_hashref,
      apiVersion => $self->apiVersion,
      type => $self->type,
      name => $self->name,
      location => $self->location,
      tags => $self->tags,
      comments => $self->comments,
      dependsOn => $self->dependsOn,
    }
  }
}
package AzureARM::ParseException {
  use Moose;
  extends 'Throwable::Error';

  has path => (is => 'ro', isa => 'Str', required => 1);
  has error => (is => 'ro', isa => 'Str', required => 1);

  has message => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    sprintf "Error on %s: %s", $self->path, $self->error;
  });
}
package AzureARM {
  use Moose;
  use feature 'postderef';

  has schema => (is => 'ro', isa => 'Str'); #, required => 1);
  has contentVersion => (is => 'ro', isa => 'Str'); #, required => 1);

  has parameters => (
    is => 'ro',
    isa => 'HashRef[AzureARM::Parameter]',
    traits => [ 'Hash' ],
    handles => {
      ParameterCount => 'count',
      ParameterNames => 'keys',
      Parameter => 'accessor',
    }
  );
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
  has outputs => (
    is => 'ro',
    isa => 'HashRef[AzureARM::Output]',
    traits => [ 'Hash' ],
    handles => {
      OutputCount => 'count',
      OutputNames => 'keys',
      Output => 'accessor',
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
    if (defined $self->parameters) {
      my $v = $hashref->{ parameters } = {};
      foreach my $k ($self->ParameterNames) {
        $v->{ $k } = $self->Parameter($k)->as_hashref;
      }
    }
    if (defined $self->outputs) {
      my $v = $hashref->{ outputs } = {};
      foreach my $k ($self->OutputNames) {
        $v->{ $k } = $self->Output($k)->as_hashref;
      }
    }
    return $hashref;
  }

  sub from_hashref {
    my ($class, $hashref) = @_;
    my $self = $class->new;

    my @args;

    push @args, schema => $hashref->{ '$schema' };
    push @args, contentVersion => $hashref->{ contentVersion };

    if (defined $hashref->{ parameters }) {
      my $parameters = {};
      foreach my $param_name (keys $hashref->{ parameters }->%*) {
        eval {
          $parameters->{ $param_name } = AzureARM::Parameter->new($hashref->{ parameters }->{ $param_name });
        };
        if ($@) { AzureARM::ParseException->throw(path => "parameters.$param_name", error => $@->message) }
      }
      push @args, parameters => $parameters;
    }
    if (defined $hashref->{ outputs }) {
      my $outputs = {};
      foreach my $param_name (keys $hashref->{ outputs }->%*) {
        my $output = $hashref->{ outputs }->{ $param_name };
        my $orig_value = $output->{ value };
        my $parsed = $self->parse_expression($output->{ value });
        if (defined $parsed) {
          $outputs->{ $param_name } = AzureARM::Output->new(%$output, value => $parsed);
        } else {
          $outputs->{ $param_name } = AzureARM::Output->new(%$output, value => AzureARM::Value->new(Value => $orig_value));
        }
      }
      push @args, outputs => $outputs;
    }
    if (defined $hashref->{ variables }) {
      my $variables = {};
      foreach my $var_name (keys $hashref->{ variables }->%*) {
        my $expr = $self->parse_expression($hashref->{ variables }->{ $var_name });
        if (defined $expr) {
          $variables->{ $var_name } = $expr;
        } else {
          $variables->{ $var_name } = AzureARM::Value->new(Value => $hashref->{ variables }->{ $var_name });
        }
      }
      push @args, variables => $variables;
    }
    if (defined $hashref->{ resources }) {
      my $resources = [];
      my $i = 0;
      foreach my $resource ($hashref->{ resources }->@*) {
        my $condition = $resource->{ condition };

        if (defined $condition) {
          my $parsed = $self->parse_expression($condition);
          AzureARM::ParseException->throw(path => "resources.$i.condition", error => "Could not parse expression $resource->{condition}") if (not defined $parsed);
          $resource->{ condition } = $parsed;
        }

        if (defined $resource->{ copy }) {
          my $copy = $resource->{ copy };

          my $original_count = $copy->{ count };
          $copy->{ count } = $self->parse_expression($original_count) if (defined $original_count);
          $copy->{ count } = AzureARM::Value::Integer->new(Value => $original_count) if (not defined $copy->{ count });

          $resource->{ copy } = AzureARM::ResourceCopy->new($copy);
        }
        
        push @$resources, AzureARM::Resource->new($resource);
      }
      push @args, resources => $resources;
    }
    
    $class->new(@args);
  }

  sub parse_expression {
    my ($self, $string) = @_;
   
    if (my $tree = $self->_parser->startrule($string)) {
      return $tree;
    } else {
      return undef;
    }
  }

  use Parse::RecDescent;

  our $grammar = q#
startrule: '[' functioncall ']' 
  { $return = AzureARM::Expression::FirstLevel->new(Value => $item{ functioncall }) }
functioncall: functionname '(' parameter(s? /,/) ')' property_access(s?)
  {
    my $function = AzureARM::Expression::Function->new(Parameters => $item{'parameter(s?)'}, Function => $item{ functionname });
    if (@{ $item{ 'property_access(s?)' } } > 0) {
      $return = AzureARM::Expression::AccessProperty->new(Properties => $item{ 'property_access(s?)' }, On => $function);
    } else {
      $return = $function;
    }
  }
property_access: '.' propaccess
 { $return = $item{ propaccess } }
propaccess: /\w+(?:\\[\\d+\\]|)/ 
 { $return = $item{ __PATTERN1__ } }
stringliteral: /'([^']*)'/
 {
   my $str = substr($item{ __PATTERN1__ }, 1, length($item{ __PATTERN1__ })-2);
   $return = AzureARM::Expression::String->new(Value => $str) 
 }
numericliteral: /-?\d+/
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
