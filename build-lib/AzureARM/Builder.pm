package AzureARM::Builder::Resource {
  use Moose;
  with 'AzureARM::Builder::TemplateProcessor';

  has base_schema => (is => 'ro', isa => 'JSONSchema::ObjectModel', required => 1);
  has resource_path => (is => 'ro', isa => 'Str', required => 1);

  sub resolve_path {
    my ($self, $path) = @_;
    if ($path =~ m|^/resourceDefinitions/(.*)|) {
      my $def_name = $1;
      return $self->base_schema->resourceDefinitions->{ $def_name };
    }
  }

  has schema => (is => 'ro', lazy => 1, isa => 'Defined', default => sub {
    my $self = shift;
    $self->resolve_path($self->resource_path);
  });

  sub namespace { 'AzureARM::Resource' }

  sub name {
    my $self = shift;
    my $name = $self->schema->properties->{ type }->enum->[0];
    $name =~ s/\./::/g;
    $name =~ s/\//::/g;
    return $name;
  }

  sub perl_package {
    my $self = shift;
    sprintf "%s::%s", $self->namespace, $self->name;
  }

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
    foreach my $resource (keys %{ $self->model_metadata }) {
      say "Processing $resource";

      eval {
        my $md = $self->model_metadata->{ $resource };
        my $model = $self->get_object_model_for($md->{ resource_url });
        my $b = AzureARM::Builder::Resource->new(
          base_schema => $model,
          resource_path => $md->{ resource_path },
        );
        $b->build;
      };
      if ($@) {
        print $@;
        push @errors, "Error processing $resource";
      }
    }
    say "Errors: ";
    say $_ for @errors;
  }
}
1;
