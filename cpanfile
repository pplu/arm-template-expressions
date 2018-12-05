requires 'perl', '5.020';
requires 'Moose';
requires 'Parse::RecDescent';
requires 'MooseX::StrictConstructor';
requires 'Throwable::Error';
requires 'JSON::MaybeXS';

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
  requires 'File::Find';
  requires 'Path::Class';
};

on develop => sub {
  requires 'Mojo::UserAgent::Cached';
  requires 'MooseX::DataModel';
  requires 'Throwable::Error';
  requires 'Template';
  requires 'File::Slurp';
};
