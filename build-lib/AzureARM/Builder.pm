package AzureARM::Builder::Property {
  use Moose;
  use Data::Dumper;

  has schema => (is => 'ro', isa => 'JSONSchema::ObjectModel::Definition');
  has resource => (is => 'ro', isa => 'AzureARM::Builder::Resource', required => 1);
  has name => (is => 'ro', isa => 'Str', required => 1);
  has required => (is => 'ro', isa => 'Bool', required => 1);

  has is_object => (is => 'ro', isa => 'Bool', lazy => 1, default => sub { shift->schema->type eq 'object' });

  our $expression_url = 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#/definitions/expression';

  has can_be_expression => (is => 'ro', isa => 'Bool', lazy => 1, default => sub {
    my $self = shift;

    return defined $self->schema->oneOf && 1 == grep { defined $_->ref and $_->ref eq $expression_url } @{ $self->schema->oneOf };
  });

  has type_raw => (is => 'ro', isa => 'JSONSchema::ObjectModel::Definition', lazy => 1, default => sub {
    my $self = shift;

    if (defined $self->schema->oneOf) {
      my @list = grep { $_->ref ne $expression_url } @{ $self->schema->oneOf };
      return $list[0];
    } else {
      return $self->schema;
    }
  });

  has type => (is => 'ro', isa => 'JSONSchema::ObjectModel::Definition', lazy => 1, default => sub {
    my $self = shift;
      return $self->resource->resolve_path($self->type_raw->ref) if (defined $self->type_raw->ref);
      return $self->type_raw;
  });

  sub perl_type {
    my $self = shift;

    my $type;
    if (defined $self->type->type) {
      $type = $self->type->type;
    } elsif (defined $self->type->enum) {
      $type = 'enum';
    } else {
      die "No type for object " . $self->name . ' ' . Dumper($self->type);
    }

    if ($type eq 'object') {
      my $type_name = $self->type_raw->ref;
      $type_name =~ s|^#/definitions/||;
      return $type_name;
    }

    my $t = {
      string => 'Str',
      enum => 'Str',
    }->{ $type };

    die "No mapping for $type" if (not defined $t);

    return $t;
  }
}
package AzureARM::Builder::Resource {
  use Moose;
  with 'AzureARM::Builder::TemplateProcessor';

  has base_schema => (is => 'ro', isa => 'JSONSchema::ObjectModel', required => 1);
  has resource_path => (is => 'ro', isa => 'Str', required => 1);

  sub resolve_path {
    my ($self, $path) = @_;
    if ($path =~ m|^/resourceDefinitions/(.*)|) {
      my $def_name = $1;
      my $res = $self->base_schema->resourceDefinitions->{ $def_name };
      die "Can't find resource definition $def_name" if (not defined $res);
      return $res;
    } elsif ($path =~ m|^#/definitions/(.*)|) {
      my $def_name = $1;
      my $res = $self->base_schema->definitions->{ $def_name };
      die "Can't find definition $def_name" if (not defined $res);
      return $res;
    }
    die "Don't know how to resolve $path";
  }

  has schema => (is => 'ro', lazy => 1, isa => 'Defined', default => sub {
    my $self = shift;
    $self->resolve_path($self->resource_path);
  });

  has properties => (is => 'ro', lazy => 1, isa => 'HashRef[AzureARM::Builder::Property]', builder => '_build_properties');
  sub property {
    my ($self, $prop) = @_;
    my $p = $self->properties->{ $prop };
    die "Can't find property $prop" if (not defined $p);
    return $p;
  }
  sub property_list {
    my $self = shift;
    sort keys %{ $self->properties }
  }

  sub _build_properties {
    my $self = shift;
    my $props = {};
    foreach my $property (keys %{ $self->schema->properties }) {
      my $required = grep { $_ eq $property } @{ $self->schema->required };
      $props->{ $property } = AzureARM::Builder::Property->new(
        required => $required,
        name => $property,
        schema => $self->schema->properties->{ $property },
        resource => $self,
      );
    }
    return $props;
  }

  has base_namespace => (is => 'ro', isa => 'ArrayRef[Str]', default => sub { [ 'AzureARM', 'Resource' ] });

  has namespace => (is => 'ro', isa => 'ArrayRef[Str]', lazy => 1, default => sub {
    my $self = shift;
    my $name = $self->schema->properties->{ type }->enum->[0];
    my @namespace = map { split /\./, $_ } split /\//, $name;
    return \@namespace;
  });

  has perl_package => (is => 'ro', isa => 'Str', lazy => 1, default => sub {
    my $self = shift;
    join '::', @{ $self->base_namespace }, @{ $self->namespace };
  });

  sub build {
    my $self = shift;
    $self->process_template('azure_resource');
  }

}
package AzureARM::Builder {
  use Moose;
  use Mojo::UserAgent::Cached;
  use JSON::MaybeXS;
  use feature 'postderef';
  use v5.10;
  use JSONSchema::ObjectModel;

  has url => (
    is => 'ro',
    default => 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json'
  );

  has root_json => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub {
      my $self = shift;
      $self->get_struct_from_url($self->url);
    }
  );

  has ua => (
    is => 'ro',
    default => sub {
      Mojo::UserAgent::Cached->new(
        local_dir => './cache'
      );
    }
  );

  sub get_struct_from_url {
    my ($self, $url) = @_;
    my $body = $self->ua->get($url)->result->body;
    return decode_json($body);
  }

  sub get_object_model_for {
    my ($self, $url) = @_;
    my $json = $self->get_struct_from_url($url);
    return JSONSchema::ObjectModel->new($json);
  }

  has model_metadata => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    builder => '_build_model_metadata'
  );
  sub model_metadata_list { sort keys %{ shift->model_metadata } }
  sub model {
    my ($self, $model) = @_;
    my $r = $self->model_metadata->{ $model };
    die "Can't find model $model" if (not defined $r);
    return $r
  }

  sub _build_model_metadata {
    my $self = shift;
    my $mdata = {};
    foreach my $type_of_resource (@{ $self->root_json->{ properties }->{ resources }->{ items }->{ oneOf } }) {
      foreach my $resource (@{ $type_of_resource->{ allOf }->[ 1 ]->{ oneOf } }) {
        my $r_ref = $resource->{ '$ref' };
        my ($url, $resource_path) = (split /#/, $r_ref, 2);
        $mdata->{ $r_ref } = {
          resource_base => $type_of_resource->{ allOf }->[ 0 ],
          resource_url => $url,
          resource_path => $resource_path,
        };
      }
    }
    return $mdata;
  }

  sub build_all {
    my $self = shift;

    my @errors;
    foreach my $model ($self->model_metadata_list) {
      say "Processing $model";

      eval {
        $self->build_one($model);
      };
      if ($@) {
        print $@;
        push @errors, "Error processing $model";
      }
    }
    say "Errors: ";
    say $_ for @errors;
  }

  sub build_one {
    my ($self, $modelname) = @_;

    my $md = $self->model($modelname);
    my $model = $self->get_object_model_for($md->{ resource_url });
    my $b = AzureARM::Builder::Resource->new(
      base_schema => $model,
      resource_path => $md->{ resource_path },
    );
    $b->build;
  }
}
1;
