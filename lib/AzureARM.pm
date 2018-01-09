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
  no warnings 'experimental::postderef';

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
  no warnings 'experimental::postderef';

  has Properties => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, traits => [ 'Array' ], handles => { NumProperties => 'count' });
  has On => (is => 'ro', isa => 'AzureARM::Expression', required => 1);

  sub as_string {
    my $self = shift;
    my $str = $self->On->as_string;
    $str .= (join '', $self->Properties->@*) if ($self->NumProperties > 0);
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
package AzureARM::Template::Parameter {
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
package AzureARM::Template::Output {
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
  use MooseX::StrictConstructor;
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
  use MooseX::StrictConstructor;
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
  use MooseX::StrictConstructor;
  use feature 'postderef';
  no warnings 'experimental::postderef';

  has condition => (is => 'ro', isa => 'AzureARM::Expression::FirstLevel');
  has apiVersion => (is => 'ro', isa => 'Str', required => 1);
  has type => (is => 'ro', isa => 'Str', required => 1);
  has name => (is => 'ro', isa => 'Str', required => 1);
  has location => (is => 'ro', isa => 'Str');
  has tags => (is => 'ro', isa => 'AzureARM::Value::Hash|AzureARM::Expression::FirstLevel'); 
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
      (defined $self->tags)?(tags => $self->tags->as_hashref):(),
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
package AzureARM {
  our $VERSION = '0.01';
  #ABSTRACT: Parse an AzureARM JSON into an object model
  use Moose;
  use feature 'postderef';
  no warnings 'experimental::postderef';

  has schema => (is => 'ro', isa => 'Str', required => 1);
  has contentVersion => (is => 'ro', isa => 'Str', required => 1);

  has resources => (
    is => 'ro',
    isa => 'ArrayRef[AzureARM::Resource]',
    traits => [ 'Array' ],
    default => sub { [] },
    handles => {
      ResourceCount => 'count',
      ResourceList => 'elements',
    }
  );
  has parameters => (
    is => 'ro',
    isa => 'HashRef[AzureARM::Template::Parameter]',
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
    isa => 'HashRef[AzureARM::Template::Output]',
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

    $hashref->{ '$schema' } = $self->schema;
    $hashref->{ contentVersion } = $self->contentVersion;

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
}
1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

AzureARM - Object model of Azure ARM templates

=head1 SYNOPSIS

  # best practice is to obtain an AzureARM with the AzureARM parser
  use AzureARM::Parser;
  my $parser = AzureARM::Parser->new;
  my $arm = $parser->from_json('{ ... }');

  say "This template has ", $arm->ResourceCount, " resources";
  say "This template has the following variables: ", join ' ', $arm->VariableNames;

=head1 DESCRIPTION

Object of the AzureARM type  an Azure ARM template, converting it into an L<AzureARM>
object to introspect it

=head1 ATTRIBUTES

=head2 schema

string containing the '$schema' element of the template (string)

=head2 contentVersion

string containing the contentVersion element of the template (string)

=head2 resources

arrayref of AzureARM::Resource objects

=head2 ResourceCount

number of resources in the template

=head2 ResourceList

list of resources in the template

=head2 parameters

hashref of AzureARM::Template::Parameter objects

=head2 ParameterCount

number of parameters in the template

=head2 ParameterNames

list of names of parameters

=head2 Parameter($name)

accesses the parameter of name $name. Returns an AzureARM::Template::Parameter object

=head2 variables

hashref of AzureARM::Value objects. Keys are the names of the variables.

=head2 VariableCount

number of variables declared

=head2 VariableNames

list of the names of the variables declared

=head2 Variable($name)

returns the AzureARM::Value object that corresponds to the variable named $name

=head2 outputs

hashref of AzureARM::Template::Output objects. Keys are the names of the outputs

=head2 OutputCount

number of outputs declared

=head2 OutputNames

list of the names of the outputs declared

=head2 Output($name)

returns the AzureARM::Template::Output object that corresponds to the output named $name

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

=head1 COPYRIGHT and LICENSE

(c) 2017 CAPSiDE S.L.

This code is distributed under the Apache v2 License

=cut
