package JSONSchema::ObjectModel::Ref {
  use MooseX::DataModel;
  use MooseX::StrictConstructor;

  key ref => (isa => 'Str', required => 1, location => '$ref');
}
package JSONSchema::ObjectModel::Definition {
  use MooseX::DataModel;
  use MooseX::StrictConstructor;

  use Moose::Util::TypeConstraints;

  subtype 'JSONSchema::ObjectModel::AdditionalProperties',
       as 'Any';

  coerce 'JSONSchema::ObjectModel::AdditionalProperties',
    from 'HashRef',
     via {
       if (ref($_) eq 'HASH') {
         JSONSchema::ObjectModel::Definition->new($_);
       } else {
use Data::Dumper;
print Dumper($_);
die "X";
       }
     };

  key contentEncoding => (isa => 'Str');
  # sites_slots_virtualNetworkConnections_gateways has this name property
  key name => (isa => 'JSONSchema::ObjectModel::Definition');
  key x_ms_azure_resource => (isa => 'Bool', location => 'x-ms-azure-resource');
  key x_ms_enum => (isa => 'HashRef', location => 'x-ms-enum');
  key additionalItems => (isa => 'Bool');
  key readOnly => (isa => 'Bool');

  key ref => (isa => 'Str', location => '$ref');
  key type => (isa => 'Str');
  key format => (isa => 'Str');
  key default => (isa => 'Any');

  array required => (isa => 'Str');

  # for an object
  object properties => (isa => 'JSONSchema::ObjectModel::Definition');
  key additionalProperties => (isa => 'JSONSchema::ObjectModel::AdditionalProperties');

  # for a number
  key minimum => (isa => 'Int');
  key maximum => (isa => 'Int');
  key exclusiveMinumum => (isa => 'Bool');

  # for a string
  array enum => (isa => 'Any');
  key maxLength => (isa => 'Int');
  key minLength => (isa => 'Int');
  key pattern => (isa => 'Str');

  # for an array
  key items => (isa => 'JSONSchema::ObjectModel::Definition');
  key maxItems => (isa => 'Int');
  key minItems => (isa => 'Int');
  key uniqueItems => (isa => 'Bool');

  array oneOf => (isa => 'JSONSchema::ObjectModel::Definition');
  array anyOf => (isa => 'JSONSchema::ObjectModel::Definition');
  array allOf => (isa => 'JSONSchema::ObjectModel::Definition');

  key description => (isa => 'Str');

  no MooseX::DataModel;
}
package JSONSchema::ObjectModel {
  use MooseX::DataModel;
  use MooseX::StrictConstructor;

  key id => (isa => 'Str', required => 1);
  key schema => (isa => 'Str', required => 1, location => '$schema');
  key title => (isa => 'Str');
  key description => (isa => 'Str');

  object resourceDefinitions => (isa => 'JSONSchema::ObjectModel::Definition');
  object definitions => (isa => 'JSONSchema::ObjectModel::Definition');

}
1;
