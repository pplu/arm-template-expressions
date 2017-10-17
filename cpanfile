requires 'Moose';
requires 'Parse::RecDescent';
requires 'MooseX::StrictConstructor';
requires 'Throwable::Error';

on test => sub {
  requires 'Test::More';
  requires 'Test::Exception';
  requires 'File::Find';
  requires 'Path::Class';
  requires 'JSON::MaybeXS';
};
