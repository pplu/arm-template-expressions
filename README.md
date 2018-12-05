# NAME

AzureARM - Object model of Azure ARM templates

# SYNOPSIS

    # best practice is to obtain an AzureARM with the AzureARM parser
    use AzureARM::Parser;
    my $parser = AzureARM::Parser->new;
    my $arm = $parser->from_json('{ ... }');

    say "This template has ", $arm->ResourceCount, " resources";
    say "This template has the following variables: ", join ' ', $arm->VariableNames;

# DESCRIPTION

Object of the AzureARM type  an Azure ARM template, converting it into an [AzureARM](https://metacpan.org/pod/AzureARM)
object to introspect it

# ATTRIBUTES

## schema

string containing the '$schema' element of the template (string)

## contentVersion

string containing the contentVersion element of the template (string)

## resources

arrayref of AzureARM::Resource objects

## ResourceCount

number of resources in the template

## ResourceList

list of resources in the template

## parameters

hashref of AzureARM::Template::Parameter objects

## ParameterCount

number of parameters in the template

## ParameterNames

list of names of parameters

## Parameter($name)

accesses the parameter of name $name. Returns an AzureARM::Template::Parameter object

## variables

hashref of AzureARM::Value objects. Keys are the names of the variables.

## VariableCount

number of variables declared

## VariableNames

list of the names of the variables declared

## Variable($name)

returns the AzureARM::Value object that corresponds to the variable named $name

## outputs

hashref of AzureARM::Template::Output objects. Keys are the names of the outputs

## OutputCount

number of outputs declared

## OutputNames

list of the names of the outputs declared

## Output($name)

returns the AzureARM::Template::Output object that corresponds to the output named $name

# AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

# COPYRIGHT and LICENSE

(c) 2017 CAPSiDE S.L.

This code is distributed under the Apache v2 License
