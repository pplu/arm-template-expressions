package AzureARM::Parser::Exception {
  use Moose;
  extends 'Throwable::Error';

  has path => (is => 'ro', isa => 'Str', required => 1);
  has error => (is => 'ro', isa => 'Str', required => 1);

  has message => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    sprintf "Error on %s: %s", $self->path, $self->error;
  });
}
package AzureARM::Parser {
  use Moose;
  use feature 'postderef';
  use AzureARM;
  use Parse::RecDescent;

  sub from_json {
    my ($class, $json) = @_;
    require JSON::MaybeXS;
    $class->from_hashref(JSON::MaybeXS::decode_json($json));
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
        #eval {
          $parameters->{ $param_name } = AzureARM::Template::Parameter->new($hashref->{ parameters }->{ $param_name });
        #};
        #if ($@) { AzureARM::ParseException->throw(path => "parameters.$param_name", error => $@->message) }
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
          $outputs->{ $param_name } = AzureARM::Template::Output->new(%$output, value => $parsed);
        } else {
          $outputs->{ $param_name } = AzureARM::Template::Output->new(%$output, value => AzureARM::Value->new(Value => $orig_value));
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
        push @$resources, $self->parse_resource($resource, $path);
      }
      push @args, resources => $resources;
    }
    
    AzureARM->new(@args);
  }

  sub parse_resource {
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
          push @$resources, $self->parse_resource($resource, $path);
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

  has _grammar => (is => 'ro', default => q#
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
#);

  has _parser => (is => 'ro', lazy => 1, default => sub {
    my $self = shift;
    my $rd = Parse::RecDescent->new($self->_grammar);
    die "Can't build RecDescent parser" if (not defined $rd);
    return $rd;
  });

}
1;
