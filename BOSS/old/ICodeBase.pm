package BOSS::ICodebase;

use MyFRDCSA;
use PerlLib::List;
use Manager::Dialog qw ( Approve Message ApproveCommand
                         ApproveCommands PrintList );
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw (ICodebaseP);

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

sub ICodebaseP {
  my $internalcodebasedir = Dir("internal codebases");
  my @systems = split /\n/,`ls -1 $internalcodebasedir $internalcodebasedir/source-hatchery`;
  my @topackage;
  foreach my $system (@_) {
    push @topackage, $system if ListContainsElement(Element => $system,
						    List => \@systems);
  }
  return @topackage;
}

sub Create {
  # prompt for description add to DOAP
  # won't necessarily exist before, so can't use ICodebaseP
  #Message "Trying to retrieve information about the capabilities from UniLang.";
  #Message "Checking whether similar capabilities exist on massive sources.list";
  #Message "apt-cache search ";
  # should have it created in the icodebase-hatchery
  # for  now,  simply  copy  files into  appropriate  directory,  asking
  # permission to do so first, also, cp with backups.

  my $ic = MyFRDCSA::Dir("internal codebases");
  my $templatedir = $ic."/boss/templates/internal-codebase";

  #   my $projectdirectory = `pwd`;
  #   if ($projectdirectory !~ /^$ic/) {
  #     Message(Message => "Must be in the codebases directory to create a new project.");
  #     croak();
  #   }
  # determine appropriate directory
  # chomp $projectdirectory;
  # chdir $projectdirectory;
  #  my $project_name = $projectdirectory;
  #  $project_name =~ s|.*/([^/]+)/?$|$1|;

  foreach my $project_name (@_) {
    # check that it is a valid dir name (doesn't contain bad characters)
    if (Approve("Create ICodebase $project_name?")) {
      my $targetdir = "$ic/source-hatchery/$project_name";
      ApproveCommands
	(Commands =>
	 [
	  "mkdir $targetdir",
	  "cp -a --backup=numbered --reply=yes ${templatedir}/* $targetdir"
	 ]);
      system "emacsclient $targetdir/frdcsa/FRDCSA.xml";
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
}

sub Promote {
  # if a system is in the source hatchery, promote it to be more general
  my @topromote = ICodebaseP(@_);
  if (@topromote) {
    print PrintList(List => \@topromote,
		    Format => "simple");
    print "\n";
    if (Approve("Promote these systems?")) {
      PromoteSystems(Systems => \@topromote);
    }
  }
}

sub PromoteSystems {
  my %args = @_;
  my @systems = @{$args{Systems}};
  my $targetdir = Dir("internal codebases");
  my $releasedir = Dir("releases");
  my $sourcedir = ConcatDir($targetdir,"source-hatchery");
  foreach my $system (@systems) {
    ApproveCommands(Method => "parallel",
		    Commands =>
		    ["mkdir $releasedir/$system-0.1",
		     "mv $sourcedir/$system $releasedir/$system-0.1/$system-0.1",
		     "ln -s $releasedir/$system-0.1/$system-0.1 $targetdir/$system"]);
  }
}

sub Package {
  my @topackage = ICodebaseP(@_);
  if (@topackage) {
    print PrintList(List => \@topackage,
		    Format => "simple");
    print "\n";
    if (Approve("Package these systems?")) {
      PackageSystems(Systems => \@topackage);
    }
  }
}

sub PackageSystems {
  my %args = @_;
  my @systems = @{$args{Systems}};
  my $date = `date "+%Y%m%d"`;
  chomp $date;
  chdir Dir("internal codebases");
  foreach my $system (@systems) {
    my $releases = Dir("releases");
    my $tmptgz = "/tmp/$system-$date.tgz";
    ApproveCommands(Method => "parallel",
		    Commands =>
		    ["predator -d $releases -s $releases $system"]);
  }
}

sub Modernize {
  print "Modernizing system:\n";
  foreach my $system (ICodebaseP(@_)) {
    print "$system\n";
  }
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

sub Document {

}

1;
