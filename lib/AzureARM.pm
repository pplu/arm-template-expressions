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

  sub as_hashref {
    my $self = shift;
    return $self->Value;
  }
}
package AzureARM::Value::String {
  use Moose;
  extends 'AzureARM::Value';
  has '+Value' => (
    isa => 'Str'
  );

  sub as_hashref {
    my $self = shift;
    return $self->Value;
  }
}
package AzureARM::Value::Hash {
  use Moose;
  extends 'AzureARM::Value';
  has '+Value' => (isa => 'HashRef');

  sub as_hashref {
    my $self = shift;
    return $self->Value;
  }
}
package AzureARM::Value::Array {
  use Moose;
  extends 'AzureARM::Value';
  has '+Value' => (isa => 'ArrayRef');

  sub as_hashref {
    my $self = shift;
    return [ map { $_->Value } @{ $self->Value } ];
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
      (defined $self->mode)?(mode => $self->mode):(),
      (defined $self->batchSize)?(batchSize => $self->batchSize):(),
    }
  }
}
package AzureARM::ResourceIdentity {
  use Moose;
  use Moose::Util::TypeConstraints qw/enum/;
  enum 'AzureARM::ResourceIdentity::Types' => [ 'systemAssigned', 'SystemAssigned' ];

  has type => (is => 'ro', isa => 'AzureARM::ResourceIdentity::Types');

  sub as_hashref {
    my $self = shift;
    return {
      type => $self->type
    }
  }
}
package AzureARM::Resource {
  use Moose;
  use feature 'postderef';

  has condition => (is => 'ro', isa => 'AzureARM::Expression::FirstLevel');
  has apiVersion => (is => 'ro', isa => 'Str', required => 1);
  has type => (is => 'ro', isa => 'Str', required => 1);
  has name => (is => 'ro', isa => 'Str', required => 1);
  has location => (is => 'ro', isa => 'Str');
  has tags => (is => 'ro', isa => 'HashRef'); 
  has comments => (is => 'ro', isa => 'Str');
  has copy => (is => 'ro', isa => 'AzureARM::ResourceCopy');
  has dependsOn => (is => 'ro', isa => 'ArrayRef[Str]');
  has properties => (is => 'ro', isa => 'AzureARM::Value::Hash|AzureARM::Expression::FirstLevel');
  has resourceGroup => (is => 'ro', isa => 'AzureARM::Value::String|AzureARM::Expression::FirstLevel');
  has id => (is => 'ro', isa => 'AzureARM::Value::String|AzureARM::Expression::FirstLevel');
  has identity => (is => 'ro', isa => 'AzureARM::ResourceIdentity');
  has resources => (
    is => 'ro',
    isa => 'ArrayRef[AzureARM::Resource]',
    traits => [ 'Array' ],
    handles => {
      ResourceCount => 'count',
      ResourceList => 'elements',
    }
  );
  has kind => (is => 'ro', isa => 'Str');
  has sku => (is => 'ro', isa => 'AzureARM::Value::Hash');
  has plan => (is => 'ro', isa => 'AzureARM::Value::Hash|AzureARM::Expression::FirstLevel');
  has zones => (is => 'ro', isa => 'AzureARM::Value::Array|AzureARM::Expression::FirstLevel');

  sub as_hashref {
    my $self = shift;

    return {
      (defined $self->condition)?(condition => $self->condition->as_hashref):(),
      apiVersion => $self->apiVersion,
      type => $self->type,
      name => $self->name,
      (defined $self->location)?(location => $self->location):(),
      (defined $self->tags)?(tags => $self->tags):(),
      (defined $self->comments)?(comments => $self->comments):(),
      (defined $self->copy)?(copy => $self->copy->as_hashref):(),
      (defined $self->dependsOn)?(dependsOn => $self->dependsOn):(),
      (defined $self->properties)?(properties => $self->properties->as_hashref):(),
      (defined $self->id)?(id => $self->id->as_hashref):(),
      (defined $self->identity)?(identity => $self->identity->as_hashref):(),
      (defined $self->resourceGroup)?(resourceGroup => $self->resourceGroup->as_hashref):(),
      (defined $self->resources)?(resources => [ map { $_->as_hashref } $self->ResourceList ]):(),
      (defined $self->kind)?(kind => $self->kind):(),
      (defined $self->sku)?(sku => $self->sku->as_hashref):(),
      (defined $self->plan)?(plan => $self->plan->as_hashref):(),
      (defined $self->zones)?(zones => $self->zones->as_hashref):(),
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
  our $VERSION = '0.01';
  #ABSTRACT: Parse an AzureARM JSON into an object model
  use Moose;
  use feature 'postderef';

  has schema => (is => 'ro', isa => 'Str'); #, required => 1);
  has contentVersion => (is => 'ro', isa => 'Str'); #, required => 1);

  has resources => (
    is => 'ro',
    isa => 'ArrayRef[AzureARM::Resource]',
    traits => [ 'Array' ],
    handles => {
      ResourceCount => 'count',
      ResourceList => 'elements',
    }
  );
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
    $hashref->{ resources } = [ map {
      $_->as_hashref
    } $self->ResourceList ];

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
        my $path = "resources.$i";
        push @$resources, $self->_parse_resource($resource, $path);
      }
      push @args, resources => $resources;
    }
    
    $class->new(@args);
  }

  sub _parse_resource {
    my ($self, $resource, $path) = @_;
    my $condition = $resource->{ condition };

    if (defined $condition) {
      my $parsed = $self->parse_expression($condition);
      AzureARM::ParseException->throw(path => "$path.condition", error => "Could not parse expression $resource->{condition}") if (not defined $parsed);
      $resource->{ condition } = $parsed;
    }

    if (defined $resource->{ copy }) {
      my $copy = $resource->{ copy };

      my $original_count = $copy->{ count };
      $copy->{ count } = $self->parse_expression($original_count) if (defined $original_count);
      $copy->{ count } = AzureARM::Value::Integer->new(Value => $original_count) if (not defined $copy->{ count });

      $resource->{ copy } = AzureARM::ResourceCopy->new($copy);
    }

    $resource->{ sku }  = AzureARM::Value::Hash->new(Value => $resource->{ sku  }) if (defined $resource->{ sku  });
    $resource->{ identity } = AzureARM::ResourceIdentity->new($resource->{ identity }) if (defined $resource->{ identity });

    if (defined $resource->{ plan }) {
      if (ref($resource->{ plan }) eq 'HASH') {
        $resource->{ plan } = AzureARM::Value::Hash->new(Value => $resource->{ plan });
      } else {
        my $parsed = $self->parse_expression($resource->{ plan });
        AzureARM::ParseException->throw(path => "$path.properties", error => "Could not parse expression $resource->{plan}") if (not defined $parsed);
        $resource->{ plan } = $parsed;
      }
    }

    if (defined $resource->{ zones }) {
      if (ref($resource->{ zones }) eq 'ARRAY') {
        my @vals = map { AzureARM::Value::String->new(Value => $_) } @{ $resource->{ zones } };
        $resource->{ zones } = AzureARM::Value::Array->new(Value => \@vals);
      } else {
        my $parsed = $self->parse_expression($resource->{ zones });
        AzureARM::ParseException->throw(path => "$path.properties", error => "Could not parse expression $resource->{zones}") if (not defined $parsed);
        $resource->{ zones } = $parsed;
      }
    }

    if (defined $resource->{ resourceGroup }) {
      my $parsed = $self->parse_expression($resource->{ resourceGroup });
      $parsed = $resource->{ resourceGroup } if (not defined $parsed);
      $resource->{ resourceGroup } = $parsed;
    }

    if (defined $resource->{ id }) {
      my $parsed = $self->parse_expression($resource->{ id });
      $parsed = $resource->{ id } if (not defined $parsed);
      $resource->{ id } = $parsed;
    }

    if (defined $resource->{ properties }) {
      if (ref($resource->{ properties }) eq 'HASH') {
        $resource->{ properties } = AzureARM::Value::Hash->new(Value => $resource->{ properties });
      } else {
        my $parsed = $self->parse_expression($resource->{ properties });
        AzureARM::ParseException->throw(path => "$path.properties", error => "Could not parse expression $resource->{properties}") if (not defined $parsed);
        $resource->{ properties } = $parsed;
      }
    }

    if (defined $resource->{ resources }) {
      if (ref($resource->{ resources }) eq 'ARRAY') {
        my $resources = [];
        my $i = 0;
        foreach my $resource ($resource->{ resources }->@*) {
          my $path = "$path.resources.$i";
          push @$resources, $self->_parse_resource($resource, $path);
        }
        $resource->{ resources } = $resources;
      } else {
        my $parsed = $self->parse_expression($resource->{ resources });
        AzureARM::ParseException->throw(path => "$path.resources", error => "Could not parse expression $resource->{resources}") if (not defined $parsed);
        $resource->{ resources } = $parsed;
      }
    }
    
    return AzureARM::Resource->new($resource);
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
