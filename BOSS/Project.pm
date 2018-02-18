package BOSS::Project;

use MyFRDCSA;
use PerlLib::List;
use Manager::Dialog qw ( Approve Message ApproveCommand
                         ApproveCommands PrintList );

use Carp;
use strict;

=head1 NAME

  BOSS::ICodebase - Functions to manipulate internal codebases

=head1 SYNOPSIS

  BOSS::ICodebase::Create(ProjectDir => `pwd`);
  BOSS::ICodebase::Package(@systems);

=head1 DESCRIPTION

This  module  provides  functions  that manipulate  MyFRDCSA  internal
codebases.

=cut

sub Create {
  my %args = @_;

  #Message "Checking whether similar capabilities exist on massive sources.list\n";
  #Message "apt-cache search ";

  # for  now,  simply  copy  files into  appropriate  directory,  asking
  # permission to do so first, also, cp with backups.
  my $ic = MyFRDCSA::Dir("projects");
  my $templatedir = $ic."/boss/templates/project";
  my $projectdirectory = $args{ProjectDir} || `pwd`;
  if ($projectdirectory !~ /^$ic/) {
    Message(Message => "Must be in the projects directory to create a new project.");
    croak();
  }
  # determine appropriate directory
  chomp $projectdirectory;
  chdir $projectdirectory;
  my $project_name = $projectdirectory;
  $project_name =~ s|.*/([^/]+)/?$|$1|;
  print "<$project_name>\n";
  if (Approve("Should we copy the project template into $projectdirectory?")) {
    ApproveCommand("cp -a --backup=numbered --reply=yes ${templatedir}/* $projectdirectory");
    if (0) {			# we don't do it this way anymore
      # now go ahead and replace the files titled project-name.* with the actual name
      my $files = `find . | grep "project-name"`;
      foreach my $file (split(/\n/,$files)) {
	my $newfile = $file;
	$newfile =~ s/project-name/project-$project_name/;
	print  "mv $file $newfile\n";
	system "mv $file $newfile";
      }
    }
  }
}

sub Modernize {
  # code to parse the frdcsa file of a given project and figure out
  # what fields are missing, etc, and which ones are new, and if new,
  # approve their integration into the main system.

  # update the FRDCSA.xml file

  # upgrade version type, should have an FRDCSA version variable
}

sub Metrics {
  my (%args) = (@_);
  my (%dirs, @files) = (%{$args{Dirs}}, @{$args{Files}});

  foreach my $file (split /\n/,`cat metrics`) {
    push @files, $file;
    my $dir = $file;
    $dir =~ s|^(.*)/.*$|$1|;
    $dirs{$dir} = $dir;
  }

  foreach my $dir (keys %dirs) {
    print "mkdirhier cache/$dir\n";
    system "mkdirhier cache/$dir";
  }

  foreach my $file (@files) {
    print "cp ../$file cache/$file\n";
    system "cp ../$file cache/$file";
  }
}

sub Statistics {
  # This  program  generates  daily  statistics for  our  projects,  for
  # instance, how many current packages  there are, of what type.  To be
  # perfectly honest, this function would be better performed as part of
  # a knowledge  base.  We should, to  the extent possible,  rely on KBs
  # for everything.
}

sub ConvertControl {
  # convert all control files to FRDCSA.xml
  chdir MyFRDCSA::Dir("projects");
  foreach my $dir (split /\n/,`ls`) {
    print "<$dir>\n";
    if (-f "$dir/control") {
      my $description = `cat $dir/control`;
      my $OUT;
      if (! -d "$dir/frdcsa") {
	mkdir "$dir/frdcsa";
      }
      if (! -f "$dir/frdcsa/FRDCSA.xml") {
	open(OUT,">$dir/frdcsa/FRDCSA.xml") or
	  die "can't open $dir/frdcsa/FRDCSA.xml.";
	print OUT "<system>
  <title>$dir</title>
  <acronym-expansion></acronym-expansion>

  <short-description>
  </short-description>
  <medium-description>
  </medium-description>
  <long-description>
   $description
  </long-description>
  <links>
    <link></link>
  </links>
</system>";
	close OUT;
      }
    }
  }
}

1;
