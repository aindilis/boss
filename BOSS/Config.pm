#############################################################################
#
# BOSS::Config
# Application Configuration Management
# Copyright(c) 2004, Andrew John Dougherty (ajd@frdcsa.org)
# Distribute under the GPL
#
############################################################################

package BOSS::Config;

use strict;
use Carp;
use Config::General;
use Getopt::Declare;

use vars qw($VERSION);
$VERSION = '1.00';
use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / Config RCConfig RCFile ConfFile CLIConfig Specs Clipboard /

  ];

sub init {
  my ($self,%args) = @_;
  $self->ConfFile($args{ConfFile});
  $self->ParseCLIOptions(%args) unless $args{AbeyCLI};
  $self->ParseConfigFile(%args) unless $args{AbeyConfig};
  if ($args{Clipboard}) {
    my $res = `xclip -o`;
    $self->Clipboard($res);
  }
}

sub ParseCLIOptions {
  my ($self,%args) = @_;
  # parse CLI options
  # $spec =~ s/\&lt/\</g;
  # $spec =~ s/\&gt/\>/g;
  my $spec = $args{Spec};
  $self->CLIConfig(Getopt::Declare->new($spec));
}

sub ParseConfigFile {
  my ($self,%args) = @_;
  # parse config file
  # $self->RCFile($self->Readable($self->ConfFile) || "");
  $self->RCFile($self->ConfFile);
  if (defined $self->RCFile) {
    $self->Config(new Config::General($self->RCFile));
    $self->RCConfig($self->Config->{DefaultConfig});
  }
}

sub Readable {
  return $_[0] if -r $_[0];
}

sub IsEmpty {
  my ($self,%args) = @_;
  foreach my $key (keys %{$self->CLIConfig}) {
    return 0 if $key !~ /^_/;
  }
  return 1;
}

sub GetArrayForRepeatedTerm {
  my ($self,%args) = @_;
  my $conf = $self->CLIConfig;
  my $term = $args{Term};
  my @list;
  my $ref = ref($conf->{$term});
  if ($ref eq 'ARRAY') {
    push @list, @{$conf->{$term}};
  } else {
    push @list, $conf->{$term};
  }
  return \@list;
}

1;
