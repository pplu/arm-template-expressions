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

on develop => sub {
  requires 'Dist::Zilla';
  requires 'Dist::Zilla::Plugin::Git::GatherDir';
  requires 'Dist::Zilla::Plugin::Git::Push';
  requires 'Dist::Zilla::Plugin::Git::Tag';
  requires 'Dist::Zilla::Plugin::Prereqs::FromCPANfile';
  requires 'Dist::Zilla::Plugin::RunExtraTests';
  requires 'Dist::Zilla::Plugin::VersionFromMainModule';
  requires 'Dist::Zilla::PluginBundle::Git';
};
