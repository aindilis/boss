package BOSS::ICodeBases;

use Manager::Dialog qw
  ( Approve Message ApproveCommand Choose ApproveCommands PrintList );
use MyFRDCSA;
use PerlLib::List;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw (ICodebaseP);

use Data::Dumper;

use strict;

use vars qw/ $VERSION /;
$VERSION = '1.00';
use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / Location ICodeBases / ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->Location($args{Location} || Dir("releases"));
  # read in the metadata file
  # don't bother for now, just list the directories
  $self->ICodeBases($args{ICodeBases} || {});
  $self->ReIndex;
}

sub ReIndex {
  my ($self,%args) = (shift,@_);
  my @dirs = ( $self->Location );
  my $regex = "(" . (join "|", map MyFRDCSA::Head($_), @dirs) . ")\$";
  my $mydirs = join " ", @dirs;
  foreach my $directory (split /\n/, `find $mydirs -maxdepth 1 -printf "%h/%f\n"`) {
    if ($directory !~ /$regex/) {
      # split it into a version and a codebase
      my $file = Predator::Util::File->new(Filename => $directory);
      my $version = $file->ExtractVersion;
      my $codebasename = $file->ExtractCodeBase;
      my $codebase;
      if (exists $self->ICodeBases->{$codebasename}) {
	$codebase = $self->ICodeBases->{$codebasename};
      } else {
	$codebase = Predator::CodeBase->new(Name => $codebasename,
					    Location => $directory);
	$self->AddCodeBase(CodeBase => $codebase);
      }
      if ($version) {
	if (exists $codebase->Releases->{$version}) {
	  Message(Message => "Release already exists");
	} else {
	  $codebase->AddRelease(Release => Predator::Release->new(CodeBase => $codebase,
								  Version => $version,
								  Location => $directory));
	}
      }
    }
  }
}

sub ListICodeBases {
  my ($self,%args) = (shift,@_);
  return map {$self->ICodeBases->{$_}} sort keys %{$self->ICodeBases};
}

sub AddICodeBase {
  my ($self,%args) = (shift,@_);
  if ($args{CodeBase}->Name) {
    if (! exists $self->ICodeBases->{$args{CodeBase}->Name} ) {
      $self->ICodeBases->{$args{CodeBase}->Name} = $args{CodeBase};
    } else {
      Message(Message => "Cannot create a duplicate codebase.");
      Message(Message => $args{CodeBase}->Name);
    }
  }
}

sub SearchICodeBases {
  my ($self,%args) = (shift,@_);
  my $regex = $args{Regex};
  my @matches;
  foreach my $codebase ($self->ListICodeBases) {
    my $name = $codebase->Name;
    if ($name =~ /$regex/) {
      push @matches, $codebase->Name;
    }
  }
  if (@matches) {
    Message(Message => "Select CodeBase");
    my $name2 = Choose(@matches);
    if ($name2 && exists $self->ICodeBases->{$name2}) {
      return $self->ICodeBases->{$name2};
    }
  } else {
    Message (Message=>"No Matches");
  }
  return;
}

1;
