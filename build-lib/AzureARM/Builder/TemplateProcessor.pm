package AzureARM::Builder::TemplateProcessor;
  use Moose::Role;
  use FindBin;
  use Template;
  use File::Slurp;
  use Path::Class;

  has _tt => (is => 'ro', isa => 'Template', default => sub {
    Template->new(
      INCLUDE_PATH => "$FindBin::Bin/../templates",
      INTERPOLATE => 0,
    );
  });

  has output_dir => (
    is => 'ro',
    isa => 'Str',
    default => 'auto-lib/'
  );

  sub process_template {
    my ($self, $template_file, $vars) = @_;

    #$self->log->debug('Processing template \'' . $template_file . '\'');

    $vars = {} if (not defined $vars);
    my $output = '';
    $self->_tt->process(
      $template_file,
      { c => $self, %$vars },
      \$output
    ) or die "Error processing template " . $self->_tt->error;

    #$self->log->debug('Output from template: ' . $output);

    my $outfile = $self->perl_package;
    $outfile =~ s/\:\:/\//g;
    $outfile .= '.pm';

    #$self->log->info("Naming it $outfile");
    my $f = file($self->output_dir, $outfile);

    $f->parent->mkpath;

    #TODO: ensure that the dir of the file exists
    write_file($f, $output);
  }

1;
