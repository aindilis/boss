package BOSS::ICodebase;

use Classify::Releaser;
use KBS::Client;
use Manager::Dialog qw ( Approve Message ApproveCommand
                         ApproveCommands PrintList Choose QueryUser
                         SubsetSelect );

use MyFRDCSA;
use PerlLib::Chase;
use PerlLib::EasyPersist;
use PerlLib::List;
use PerlLib::MySQL;
use PerlLib::SwissArmyKnife;
use UniLang::Util::TempAgent;

use Data::Dumper;
use Dir::List;
use File::Stat qw/:stat/;
use IO::File;
use Sort::Versions;
use XML::Simple;

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK =

qw(ICodebaseP GetInformation GetDescriptions GetDescriptions2
 GetSystems GetPerlModuleLinks);

use Carp;

=head1 NAME

  BOSS::ICodebase - Functions to manipulate internal codebases

=head1 SYNOPSIS

  BOSS::ICodebase::Create(ProjectDir => `pwd`);
  BOSS::ICodebase::Package(@systems);

=head1 DESCRIPTION

This  module  provides  functions  that manipulate  MyFRDCSA  internal
codebases.

=cut

my $assertedknowledge;

sub GetSystems {
  my %args = @_;
  my @dirs = $args{Dirs} ? @{$args{Dirs}} :
    (Dir("internal codebases"),Dir("minor codebases"),Dir("internal codebases")."/source-hatchery");
  my $systems = {};
  foreach my $dir (@dirs) {
    foreach my $key (split /\n/,`ls -1 $dir`) {
      $systems->{$key} = "$dir/$key";
    }
  }
  return $systems;
}

sub ICodebaseP {
  my @systems = keys %{GetSystems()};
  my @topackage;
  foreach my $system (@_) {
    push @topackage, $system if ListContainsElement(Element => $system,
						    List => \@systems);
  }
  return @topackage;
}

sub GetInformation {
  my $internalcodebasedir = Dir("internal codebases");
  my $minorcodebasedir = Dir("minor codebases");
  my $system = shift;
  if (ICodebaseP($system)) {
    my $file;
    if (-f "$internalcodebasedir/$system/frdcsa/FRDCSA.xml") {
      $file = "$internalcodebasedir/$system/frdcsa/FRDCSA.xml";
    } elsif (-f "$internalcodebasedir/source-hatchery/$system/frdcsa/FRDCSA.xml") {
      $file = "$internalcodebasedir/source-hatchery/$system/frdcsa/FRDCSA.xml";
    } elsif (-f "$minorcodebasedir/$system/frdcsa/FRDCSA.xml") {
      $file = "$minorcodebasedir/$system/frdcsa/FRDCSA.xml";
    }
    if ($file) {
      my $t = XMLin($file);
      return $t;
    }
  }
}

sub GetDescriptions {
  my @applications = split /\n/,`ls /var/lib/myfrdcsa/codebases/internal/`;
  my @choices;

  # my $descriptionhashfile = "$UNIVERSAL::systemdir/data/system-descriptions";
  # my $descriptionhashfile = "/var/lib/myfrdcsa/codebases/internal/boss/data/system-descriptions";
  my $internalcodebasedir = Dir("internal codebases");
  my $descriptionhashfile = "$internalcodebasedir/boss/data/system-descriptions";

  my $descriptions = {};
  if (-f $descriptionhashfile) {
    my $c = `cat $descriptionhashfile`;
    $descriptions = eval $c;
  }

  my $changes = 0;
  foreach my $application (@applications) {
    my $info;
    my $desc;
    if (! exists $descriptions->{$application}) {
      $info = GetInformation($application);
      $desc = ref $info->{"short-description"} eq "" ? $info->{"short-description"} : "";
      $desc =~ s/^\s*(.*?)\s*$/$1/s;
      $descriptions->{$application} = $desc;
      $changes = 1;
    } else {
      $desc = $descriptions->{$application};
    }
  }

  if ($changes) {
    my $OUT;
    open(OUT,">$descriptionhashfile") and print OUT Dumper($descriptions) and close(OUT);
  }
  return $descriptions;
}

sub GetDescriptions2 {
  my @applications = split /\n/,`ls /var/lib/myfrdcsa/codebases/internal/`;
  my @choices;

  # my $descriptionhashfile = "$UNIVERSAL::systemdir/data/system-descriptions";
  # my $descriptionhashfile = "/var/lib/myfrdcsa/codebases/internal/boss/data/system-descriptions";
  my $internalcodebasedir = Dir("internal codebases");
  my $descriptionhashfile = "$internalcodebasedir/boss/data/system-descriptions2";

  my $descriptions = {};
  if (-f $descriptionhashfile) {
    my $c = `cat $descriptionhashfile`;
    $descriptions = eval $c;
  }

  my $changes = 0;
  foreach my $application (@applications) {
    my $info;
    my $desc;
    if (! exists $descriptions->{$application}) {
      $info = GetInformation($application);
      my $shortdesc = ref $info->{"short-description"} eq "" ? $info->{"short-description"} : "";
      my $acronym = ref $info->{"acronym-expansion"} eq "" ? $info->{"acronym-expansion"} : "";
      $shortdesc ||= $acronym;
      $shortdesc =~ s/^\s*(.*?)\s*$/$1/s;
      my $mediumdesc = ref $info->{"medium-description"} eq "" ? $info->{"medium-description"} : "";
      $mediumdesc =~ s/^\s*(.*?)\s*$/$1/gm;
      my $longdesc = ref $info->{"long-description"} eq "" ? $info->{"long-description"} : "";
      $longdesc =~ s/^\s*(.*?)\s*$/$1/gm;
      $descriptions->{$application} =
	{
	 Short => $shortdesc,
	 Medium => $mediumdesc,
	 Long => $longdesc,
	};
      $changes = 1;
    } else {
      $desc = $descriptions->{$application};
    }
  }

  if ($changes) {
    my $OUT;
    open(OUT,">$descriptionhashfile") and print OUT Dumper($descriptions) and close(OUT);
  }
  return $descriptions;
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

sub CreateNewRelease {
  my @tocreatenewrelease = ICodebaseP(@_);
  if (@tocreatenewrelease) {
    print PrintList(List => \@tocreatenewrelease,
		    Format => "simple");
    print "\n";
    if (Approve("Create new releases of these systems?")) {
      CreateNewReleaseForSystems(Systems => \@tocreatenewrelease);
    }
  }
}

sub Promote {
  # if a system is in the source hatchery, promote it to be more general
  # my @topromote = ICodebaseP(@_);
  my @topromote = @_;
  if (@topromote) {
    print PrintList(List => \@topromote,
		    Format => "simple");
    print "\n";
    if (Approve("Promote these systems?")) {
      PromoteSystems(Systems => \@topromote);
    }
  }
}

sub Demote {
  # if a system is not in the source hatchery, demote it to there
  my @todemote = ICodebaseP(@_);
  if (@todemote) {
    print PrintList(List => \@todemote,
		    Format => "simple");
    print "\n";
    if (Approve("Demote these systems?")) {
      DemoteSystems(Systems => \@todemote);
    }
  }
}

sub Delete {
  # if a system is in the source hatchery, promote it to be more general
  my @todelete = ICodebaseP(@_);
  if (@todelete) {
    print PrintList(List => \@todelete,
		    Format => "simple");
    print "\n";
    if (Approve("Are you absolutely sure you wish to remove this(these) codebase(s)?") and
	Approve("Are you again, absolutely positive of this?")) {
      DeleteSystems(Systems => \@todelete);
    }
  }
}

sub Rename {
  # simply create a new, copy  files, do substitution on all important
  # files, and then delete old
}

# sub UpdateLinksToLatest {
#   # if a system is in the source hatchery, promote it to be more general
# }

sub Framework {
  my @tocreatenewrelease = ICodebaseP(@_);
  if (@tocreatenewrelease) {
    print PrintList(List => \@tocreatenewrelease,
		    Format => "simple");
    print "\n";
    if (Approve("Create OO Perl framework for these systems?")) {
      CreateFramework(Systems => \@tocreatenewrelease);
    }
  }
}

sub FrameworkMoose {
  my @tocreatenewrelease = ICodebaseP(@_);
  if (@tocreatenewrelease) {
    print PrintList(List => \@tocreatenewrelease,
		    Format => "simple");
    print "\n";
    if (Approve("Create OO Moose Perl framework for these systems?")) {
      CreateFrameworkMoose(Systems => \@tocreatenewrelease);
    }
  }
}

sub SVNImport {
  my @tocreatenewrelease = ICodebaseP(@_);
  if (@tocreatenewrelease) {
    print PrintList(List => \@tocreatenewrelease,
		    Format => "simple");
    print "\n";
    if (Approve("Import these systems into a subversion repository?")) {
      SVNImportImpl(Systems => \@tocreatenewrelease);
    }
  }
}

sub LoadAssertedKnowledge {
  my $tempagent = UniLang::Util::TempAgent->new;
  my $assertedknowledge = {};
  my $message = $tempagent->MyAgent->QueryAgent
    (
     Receiver => "KBS",
     Contents => "all-asserted-knowledge",
     Data => {_DoNotLog => 1},
    );
  my $c = $message->Contents;
  $VAR1 = undef;
  eval $c;
  my $rel = $VAR1;
  $VAR1 = undef;
  foreach my $entry (@$rel) {
    foreach my $item (@$entry) {
      if ($item =~ /^\d+$/) {
	if (! exists $assertedknowledge->{$item}) {
	  $assertedknowledge->{$item} = [];
	}
	push @{$assertedknowledge->{$item}}, $entry;
      }
    }
  }

  # FIXME: query FreeKBS2 knowledge, such as from the context:
  # Org::FRDCSA::PSE2

  return $assertedknowledge;
}


sub Capabilities {
  # list all the capabilities of a system
  my @to = ICodebaseP(@_);
  my $seen = {};
  # my $declassifier = Classify::Releaser->new;
  my @ret;
  my $systems = GetSystems;
  if (! defined $assertedknowledge) {
    $assertedknowledge = LoadAssertedKnowledge;
  }
  if (@to) {
    my $sql = PerlLib::MySQL->new
      (DBName => "unilang");
    #     print PrintList(List => \@to,
    #		    Format => "simple");
    foreach my $name (@to) {
      my $ret = $sql->Do
	(Statement => "select *,UNIX_TIMESTAMP(Date) from messages where (Sender='UniLang-Client' or Sender='Manager' or Sender='Recovery-FRDCSA') and Contents like '\%$name\%'");
      my @cap;
      foreach my $key (sort {$ret->{$a}->{'UNIX_TIMESTAMP(Date)'}
			       <=> $ret->{$b}->{'UNIX_TIMESTAMP(Date)'}} keys %$ret) {
	my $desc = $ret->{$key}->{Contents};
	if ($desc =~ /\b$name\b/i) {
	  if (defined $desc and length($desc) < 1000) {
	    if (! exists $seen->{$desc}) {
	      $seen->{$desc} = 1;
	      my $ok = 1;
	      if ($desc =~ /^(\w+)[-,]/) {
		# determine whether this is not a system name
		if (exists $systems->{lc($1)}) {
		  $ok = 0;
		}
	      }
 	      if ($ok) { # and $declassifier->ApproveForGeneralRelease(Item => $desc)) {
		if (exists $assertedknowledge->{$key}) {
		  push @cap, {
			      Desc => $desc,
			      Knowledge => $assertedknowledge->{$key},
			     };
		} else {
		  push @cap, {
			      Desc => $desc,
			     };
		}
	      }
	    }
	  }
	}
      }
      # print "$name\n";
      print Dumper(\@cap);
      push @ret, \@cap;
    }
    # $declassifier->PrintEntities;
  }
  return \@ret;
}

sub OldCapabilities {
  # if a system is in the source hatchery, promote it to be more general
  print Dumper(@_);
  my @to = ICodebaseP(@_);
  if (@to) {
    my $sql = PerlLib::MySQL->new
      (DBName => "score");
    print PrintList(List => \@to,
		    Format => "simple");
    foreach my $name (@to) {
      my $ret = $sql->Do
	(Statement => "select * from goals where Description like '\%$name\%'");
      my @cap;
      foreach my $key (keys %$ret) {
	my $desc = $ret->{$key}->{Description};
	if (defined $desc and length($desc) < 300) {
	  push @cap, $desc;
	}
      }
      print "$name\n";
      print Dumper(\@cap);
    }
  }
}


######################################################################

sub PromoteSystems {
  my %args = @_;
  my @systems = @{$args{Systems}};
  my $targetdir = Dir("internal codebases");
  my $releasedir = Dir("releases");
  my $sourcedir = ConcatDir($targetdir,"source-hatchery");
  foreach my $system (@systems) {
    if (-d "$sourcedir/$system-0.1") {
      my @v = sort { versioncmp($b, $a) }  map {s/^.+?-([0-9\.]+)$/$1/ and $_} split (/\n/,`ls $sourcedir/$system-* | grep -E '$system-[0-9\.]+'`);
      my $gv = shift @v;
      ApproveCommands(Method => "parallel",
		      Commands =>
		      ["mkdir $releasedir/$system-0.1",
		       "mv $sourcedir/$system-* $releasedir",
		       "ln -s $releasedir/$system-$gv/$system-$gv $targetdir/$system"]);
    } else {
      ApproveCommands(Method => "parallel",
		      Commands =>
		      ["mkdir $releasedir/$system-0.1",
		       "mv $sourcedir/$system $releasedir/$system-0.1/$system-0.1",
		       "ln -s $releasedir/$system-0.1/$system-0.1 $targetdir/$system"]);
    }
  }
}

sub GetVersion {
  my $system = shift;
  $system =~ s|.+-([0-9\.]+)$|$1|;
  return $system;
}

sub GetLatestVersion {
  my ($system,$releasedir) = (shift,shift);
  print $releasedir."\n";
  my $contents = `ls $releasedir | grep $system`;
  my @dirs = grep(/.+-([0-9\.]+)$/,split (/\n/,$contents));
  my @v = sort { versioncmp($b, $a) } map GetVersion($_), @dirs;
  return shift @v;
}

sub CreateNewReleaseForSystems {
  my %args = @_;
  my @systems = @{$args{Systems}};
  my $targetdir = Dir("internal codebases");
  my $releasedir = Dir("releases");
  my $sourcedir = ConcatDir($targetdir,"source-hatchery");
  my @versions = ();
  foreach my $s (@systems) {
    my $v = GetLatestVersion($s,$releasedir);
    my @v = split /\./,$v;
    for (my $i = 0; $i < @v; ++$i) {
      my @c = @v;
      for (my $j = 0; $j < $i; ++$j) {
	$c[scalar @c - $j - 1] = "0";
      }
      ++$c[scalar @c - $i - 1];
      push @versions, join(".",@c);
    }
    Message(Message => "Current latest version is $v");
    Message(Message => "Please choose new release version");
    my $nv = Choose(@versions);
    ApproveCommands(Method => "parallel",
		    Commands =>
		    ["mkdir $releasedir/$s-$nv",
		     "cp -ar $releasedir/$s-$v/$s-$v $releasedir/$s-$nv/$s-$nv",
		     "rm $targetdir/$s",
		     "ln -s $releasedir/$s-$nv/$s-$nv $targetdir/$s"]);
  }
}


sub DemoteSystems {
  my %args = @_;
  my @systems = @{$args{Systems}};
  my $targetdir = Dir("internal codebases");
  my $releasedir = Dir("releases");
  my $sourcedir = ConcatDir($targetdir,"source-hatchery");
  foreach my $system (@systems) {
    ApproveCommands(Method => "parallel",
		    Commands =>
		    ["mv $releasedir/$system-* $sourcedir",
		     "rm $targetdir/$system"]);
  }
}

sub DeleteSystems {
  my %args = @_;
  my @systems = @{$args{Systems}};
  my $targetdir = Dir("internal codebases");
  my $releasedir = Dir("releases");
  my $sourcedir = ConcatDir($targetdir,"source-hatchery");
  foreach my $system (@systems) {
    ApproveCommands(Method => "parallel",
		    Commands =>
		    ["mv $releasedir/$system-* /tmp",
		     "rm $targetdir/$system"]);
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

sub GetPerlModuleLinks {
  my %args = @_;
  my $codebase = $args{Codebase};
  my $codebasedir = $args{CodebaseDir};
  my $linkdir;
  my $dir = "$codebasedir/$codebase";
  if (-d $dir) {
    foreach my $file (split /\n/,`ls $dir`) {
      if ($file =~ /^$codebase$/i and $file ne $codebase) {
	$linkdir = $file;
      }
    }
  }
  if (! $linkdir) {
    $linkdir = QueryUser("What is the OO Perl stuff called?: (eg. UniLang)");
  }
  my $perldir = "/usr/share/perl5";
  return {
	  CodebaseDir => $dir,
	  PerlDir => $perldir,
	  LinkModule => "$perldir/$linkdir.pm",
	  LinkDirectory => "$perldir/$linkdir",
	  SourceModule => "$dir/$linkdir.pm",
	  SourceDirectory => "$dir/$linkdir",
	 };
}

sub UpdateLinks {
  print "Updating Perl Symlinks for system:\n";
  my %args = @_;
  foreach my $codebase (ICodebaseP(@{$args{Codebases}})) {
    my $ret = GetPerlModuleLinks
      (
       Codebase => $codebase,
       CodebaseDir => $args{CodebaseDir} || GetCodebaseDir(),
      );
    my $perldir = $ret->{PerlDir};
    my $dir = $ret->{CodebaseDir};
    my @cs;
    if (-e $ret->{LinkDirectory}) {
      Message(Message => "Already linked: ".$ret->{LinkDirectory});
    } else {
      push @cs, "sudo ln -s ".$ret->{SourceDirectory}." $perldir";
    }
    if (-e $ret->{LinkModule}) {
      Message(Message => "Already linked: ".$ret->{LinkModule});
    } else {
      push @cs, "sudo ln -s ".$ret->{SourceModule}." $perldir";
    }
    if (@cs) {
      ApproveCommands(Commands => \@cs,
		      Method => "parallel");
    }
  }
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

sub Statistics {
  # This  program  generates  daily  statistics for  our  projects,  for
  # instance, how many current packages  there are, of what type.  To be
  # perfectly honest, this function would be better performed as part of
  # a knowledge  base.  We should, to  the extent possible,  rely on KBs
  # for everything.
  my $hash = {};
  foreach my $file (split /\n/, `cat perlfiles`) {
    if (! -d $file) {
      my $contents = `cat $file`;
      if (! exists $hash->{$contents}) {
	$hash->{$contents} = 1;

	my $stat = stat($file);
	if ($stat->ctime > 1096519146) { # 1101879200) {
	  #       if ($stat->ctime > 1085977994) {
	  my $copy = $file;
	  $copy =~ s#\/##g;
	  my $command = "cp $file copies/copies/$copy";
	  print "$command\n";
	  # system $command;
	}

	#	print "month ";
	#       }
	#       print $file."\n";

      }
    }
  }
}

sub Grep {
  my %args = @_;
  my $regex = $args{Regex} ||
    $UNIVERSAL::boss->Conf->CLIConfig->{'<items>'} ||
    QueryUser("What is you regex?");
  my $itemset = ["scripts","modules"];
  my $featureset = ["filenames","descriptions","contents"];
  my $descriptions;
  my @items = $args{Items} ||
    SubsetSelect
      (Set => $itemset);
  my @features = $args{Features} ||
    SubsetSelect
      (Set => $featureset);

  my @files;
  foreach my $item (@items) {
    if ($item eq "scripts") {
      push @files, @{FindAllScripts()};
    } elsif ($item eq "modules") {
      push @files, @{FindAllModules()};
    }
  }
  foreach my $feature (@features) {
    if ($feature eq "filenames") {
      foreach my $f (@files) {
	if ($f =~ /$regex/) {
	  GrepAdd([$f]);
	}
      }
    } elsif ($feature eq "descriptions") {
      if (! $descriptions) {
	$descriptions = eval `cat /var/lib/myfrdcsa/codebases/internal/architect/data/descriptions.pl`;
      }
      foreach my $f (@files) {
	if (exists $descriptions->{$f}) {
	  if ($descriptions->{$f} =~ /$regex/) {
	    GrepAdd([$f,$descriptions->{$f}]);
	  }
	}
      }
    } elsif ($feature eq "contents") {
      foreach my $f (@files) {
	my $c = `cat "$f"`;
	if ($c =~ /$regex/) {
	  foreach my $l (split /\n/,$c) {
	    if ($l =~ /$regex/) {
	      GrepAdd([$f,$l]);
	    }
	  }
	}
      }
    }
  }
}

sub QuickGrep {
  my @args = @_;
  my $regex = $args[0] ||
    $UNIVERSAL::boss->Conf->CLIConfig->{'<items>'} ||
    QueryUser("What is you regex?");
  # system "cd /var/lib/myfrdcsa/codebases/minor && find .";
  print "<$regex>\n";

  system "cd /var/lib/myfrdcsa/codebases && grep-R-emacs ".shell_quote($regex)." && grep-R-perl ".shell_quote($regex);
}

sub Search {
  # fix this whole mechanism
  my @searches = @_;
  my $regex = $searches[0] || QueryUser("What is you regex?");
  if (0) {
    my $itemset = ["scripts","modules"];
    my $featureset = ["filenames","descriptions","contents"];
    my $descriptions;
    my @items = $args{Items} ||
      SubsetSelect
	(Set => $itemset);
    my @features = $args{Features} ||
      SubsetSelect
	(Set => $featureset);
  }
  # just do the namazu stuff here
  my $command = "/var/lib/myfrdcsa/codebases/internal/boss/scripts/namazu/my-nmzgrep ".
    shell_quote($regex)." -f /var/lib/myfrdcsa/codebases/internal/boss/scripts/namazu/namazurc";
  print $command."\n";
  my $res = `$command`;
  if (exists $UNIVERSAL::boss->Conf->CLIConfig->{'-c'}) {
    my $context = $UNIVERSAL::boss->Conf->CLIConfig->{'-c'};
    my $filenames = {};
    foreach my $line (split /\n/, $res) {
      if ($line =~ /^(.+?):/) {
	$filenames->{$1}++;
      }
    }
    foreach my $filename (sort keys %$filenames) {
      print "$filename:\n";
      my $command = "grep -C $context -E ".shell_quote($regex)." ".shell_quote($filename);
      system $command; # print Dumper({Command => $command});
      print "\n\n\n=======================================================================\n\n\n";
    }
  } else {
    print $res;
  }
}

sub UpdateDB {
  # use task1 to get a list of all of the files to search
  # actually, I think boss already has something like this
  my $persist = PerlLib::EasyPersist->new;
  my $overwrite = 1;
  my $scripts = $persist->Get
    (
     Command => "`boss list_scripts`",
     Overwrite => $overwrite,
    );

  my $modules = $persist->Get
    (
     Command => "`boss list_modules`",
     Overwrite => $overwrite,
    );

  my $elisp = $persist->Get
    (
     Command => "`boss list_elisp`",
     Overwrite => $overwrite,
    );

  # print Dumper([$scripts,$modules]);
  die "No success (1)\n" unless ($scripts->{Success} and $modules->{Success});

  my $fh = IO::File->new;
  if (! -d "/var/lib/myfrdcsa/codebases/internal/boss/data/namazu/") {
    system "mkdir -p /var/lib/myfrdcsa/codebases/internal/boss/data/namazu/";
  }
  $fh->open("> /var/lib/myfrdcsa/codebases/internal/boss/data/namazu/target") or die "cannot open target\n";
  print $fh $scripts->{Result};
  foreach my $line (split /\n/, $modules->{Result}) {
    print $fh "/usr/share/perl5/$line\n"
  }
  print $fh $elisp->{Result};

  $fh->close;
  # now build the file for namazu to take as input, then build the index
  ApproveCommands
    (
     Commands => ["cd /var/lib/myfrdcsa/codebases/internal/boss/data/namazu && mknmz -a -F target -f /var/lib/myfrdcsa/codebases/internal/boss/scripts/namazu/mknmzrc"],
     AutoApprove => exists $UNIVERSAL::boss->Conf->CLIConfig->{'-y'},
    );
}

sub Etags {
  # use task1 to get a list of all of the files to search
  # actually, I think boss already has something like this
  # first rm the tags table
  # make list of all files that should be etagged
  my $tagsfile = "$UNIVERSAL::systemdir/data/TAGS";

  SafelyRemove
    (
     Items => [$tagsfile],
     AutoApprove => exists $UNIVERSAL::boss->Conf->CLIConfig->{'-y'},
    );

  # now update the perl tags
  my $persist = PerlLib::EasyPersist->new;
  my $overwrite = 1;
  my $scripts = $persist->Get
    (
     Command => "`boss list_scripts`",
     Overwrite => $overwrite,
    );

  my $modules = $persist->Get
    (
     Command => "`boss list_modules`",
     Overwrite => $overwrite,
    );
  die "No success (2)\n" unless ($scripts->{Success} and $modules->{Success});
  my $results = $scripts->{Result}."\n";
  foreach my $line (split /\n/, $modules->{Result}) {
    $results .= "/usr/share/perl5/$line\n"
  }
  my ($fh,$filename) = tempfile( DIR => "/tmp", SUFFIX => ".txt" );
  print $fh $results;
  $fh->close();

  print "Making Perl TAGS\n";
  # first get all the FRDCSA files

  my $c = "cat ".shell_quote($filename)." | etags -o ".shell_quote($tagsfile)." -a -l perl -";
  print "$c\n";
  system $c;

  SafelyRemove
    (
     Items => [$filename],
     AutoApprove => exists $UNIVERSAL::boss->Conf->CLIConfig->{'-y'},
    );

  # now list emacs files

  # now update the emacs tags
  $overwrite = 1;
  my $elisp = $persist->Get
    (
     Command => "`boss list_elisp`",
     Overwrite => $overwrite,
    );

  die "No success (3)\n" unless ($elisp->{Success});
  $results = $elisp->{Result};
  my ($fh2,$filename2) = tempfile( DIR => "/tmp", SUFFIX => ".txt" );
  print $fh2 $results;
  $fh2->close();

  print "Making Elisp TAGS\n";
  # first get all the FRDCSA files

  $c = "cat ".shell_quote($filename2)." | etags -o ".shell_quote($tagsfile)." -a -l lisp -";
  print "$c\n";
  system $c;

  SafelyRemove
    (
     Items => [$filename2],
     AutoApprove => exists $UNIVERSAL::boss->Conf->CLIConfig->{'-y'},
    );
}

sub GrepAdd {
  my $l = shift;
  print Dumper($l);
}

sub FindAllScripts {
  my @process;
  my $systems = GetSystems;
  foreach my $sys (keys %$systems) {
    my $sdir = $systems->{$sys}."/scripts";
    if (-d $sdir) {
      foreach my $s (split /\n/, `ls "$sdir"`) {
	if (-f "$sdir/$s" and $s !~ /[\~\#]$/) {
	  my $f = "$sdir/$s";
	  my $res = `file "$f"`;
	  if ($res =~ /\bperl.{0,10}script\b/i) {
	    push @process, $f;
	    # print "$f\n";
	  }
	}
      }
    }
  }
  return \@process;
}

sub FindAllModules {
  my $sdir = "/usr/share/perl5";
  foreach my $item (split /\n/, `ls "$sdir"`) {
    my $chased = chase("$sdir/$item");
    # print "$chased\n";
    if ($chased =~ q|myfrdcsa[\.0-9-]*/codebases|) {
      if (-d "$sdir/$item") {
	foreach my $s (split /\n/, `find "$sdir/$item" -follow`) {
	  if (-f "$s" and $s =~ /\.pm$/i) {
	    push @process, "$s";
	    # print "$s\n";
	  }
	}
      } elsif (-f "$sdir/$item") {
	push @process, "$sdir/$item";
	# print "$sdir/$item\n";
      }
    }
  }
  return \@process;
}

sub FindAllElisp {
  my $systems = GetSystems;
  my @process;
  foreach my $sys (keys %$systems) {
    my $sdir = $systems->{$sys};
    if (-d $sdir) {
      foreach my $s (split /\n/, `find "$sdir"`) {
	if ($s =~ /\.el$/ and -f "$s" and $s !~ /[\~\#]$/) {
	  my $f = $s;
	  push @process, $f;
	  next;
	  my $res = `file "$f"`;
	  if ($res =~ /\bLisp\/Scheme program text\b/) {
	    push @process, $f;
	    # print "$f\n";
	  } else {
	    print "ERROR: $res\n";
	  }
	}
      }
    }
    $sdir = $sdir."/frdcsa/emacs";
    if (-d $sdir) {
      foreach my $s (split /\n/, `find "$sdir"`) {
	if ($s =~ /\.el$/ and -f $s and $s !~ /[\~\#]$/) {
	  push @process, $s;
	  next;
	  my $res = `file "$s"`;
	  if ($res =~ /\bLisp\/Scheme program text\b/) {
	    push @process, $s;
	  } else {
	    print "ERROR: $res\n";
	  }
	}
      }
    }
  }
  return \@process;
}

sub CreateFramework {
  my (%args) = (@_);
  my @completed;
  foreach my $sys (@{$args{Systems}}) {
    # find out what directory to put it in
    my $icodebasedir = GetCodebaseDir();
    print "<$sys>\n";

    # find out what the thing should be called
    my $sysname = QueryUser("What should the systems be called?");

    # copy the thing into a temporary directory
    if (ApproveCommands
	(Commands =>
	 [
	  "rm -rf /tmp/boss",
	  "mkdir /tmp/boss",
	  "cp -ar /var/lib/myfrdcsa/codebases/internal/boss/templates/oo-perl-application/* /tmp/boss"
	 ],
	 Method => "parallel")) {
      # make changes to the codebase files
      # foreach my $file (split /\n/,`find /tmp/boss`) {
      foreach my $file (split /\n/,`ls /tmp/boss`) {
	if (-f "/tmp/boss/$file") {
	  my $c = `cat "/tmp/boss/$file"`;
	  $c =~ s/APP/$sysname/g;
	  my $lcsysname = lc($sysname);
	  $c =~ s/app/$lcsysname/g;
	  my $OUT;
	  open (OUT,">/tmp/boss/$file") or die "ouch\n";
	  print OUT $c;
	  close (OUT);
	}
      }
      # make changes to the file names
      my @commands;
      foreach my $file (split /\n/,`ls /tmp/boss`) {
	my $ofile = $file;
	$ofile =~ s/APP/$sysname/;
	my $lcsysname = lc($sysname);
	$ofile =~ s/app/$lcsysname/;
	if ($file ne $ofile) {
	  push @commands, "mv \"/tmp/boss/$file\" \"/tmp/boss/$ofile\"";
	}
      }
      if (ApproveCommands
	  (Commands => \@commands,
	   Method => "parallel")) {
	@commands = ();
	# test  whether  files   are  already  present  (smart  copy),
	# otherwise copy them into directory
	my @tocopy;
	my @possiblycopy;
	foreach my $file (split /\n/, `ls /tmp/boss`) {
	  if (! -f "$icodebasedir/$sys/$file") {
	    push @tocopy, $file;
	  } else {
	    push @possiblycopy, $file;
	  }
	}
	if (@possiblycopy) {
	  if (Approve(Dumper(@possiblycopy)."\nOverwrite these files?")) {
	    push @tocopy, @possiblycopy;
	  }
	}
	foreach my $file (@tocopy) {
	  push @commands, "mv \"/tmp/boss/$file\" \"$icodebasedir/$sys/$file\"";
	}
	if (ApproveCommands
	    (Commands => \@commands,
	     Method => "parallel")) {
	  # run script to update links
	  push @completed, $sys;
	}
      }
    }
  }
  UpdateLinks
    (
     Codebases => \@completed,
     CodebaseDir => $icodebasedir,
    );
}

sub CreateFrameworkMoose {
  my (%args) = (@_);
  my @completed;
  foreach my $sys (@{$args{Systems}}) {
    # find out what directory to put it in
    my $icodebasedir = GetCodebaseDir();
    print "<$sys>\n";

    # find out what the thing should be called
    my $sysname = QueryUser("What should the systems be called?");

    # copy the thing into a temporary directory
    if (ApproveCommands
	(Commands =>
	 [
	  "rm -rf /tmp/boss",
	  "mkdir /tmp/boss",
	  "cp -ar /var/lib/myfrdcsa/codebases/internal/boss/templates/moose-application/* /tmp/boss"
	 ],
	 Method => "parallel")) {
      # make changes to the codebase files
      # foreach my $file (split /\n/,`find /tmp/boss`) {
      foreach my $file (split /\n/,`ls /tmp/boss`) {
	if (-f "/tmp/boss/$file") {
	  my $c = `cat "/tmp/boss/$file"`;
	  $c =~ s/APP/$sysname/g;
	  my $lcsysname = lc($sysname);
	  $c =~ s/app/$lcsysname/g;
	  my $OUT;
	  open (OUT,">/tmp/boss/$file") or die "ouch\n";
	  print OUT $c;
	  close (OUT);
	}
      }
      # make changes to the file names
      my @commands;
      foreach my $file (split /\n/,`ls /tmp/boss`) {
	my $ofile = $file;
	$ofile =~ s/APP/$sysname/;
	my $lcsysname = lc($sysname);
	$ofile =~ s/app/$lcsysname/;
	if ($file ne $ofile) {
	  push @commands, "mv \"/tmp/boss/$file\" \"/tmp/boss/$ofile\"";
	}
      }
      if (ApproveCommands
	  (Commands => \@commands,
	   Method => "parallel")) {
	@commands = ();
	# test  whether  files   are  already  present  (smart  copy),
	# otherwise copy them into directory
	my @tocopy;
	my @possiblycopy;
	foreach my $file (split /\n/, `ls /tmp/boss`) {
	  if (! -f "$icodebasedir/$sys/$file") {
	    push @tocopy, $file;
	  } else {
	    push @possiblycopy, $file;
	  }
	}
	if (@possiblycopy) {
	  if (Approve(Dumper(@possiblycopy)."\nOverwrite these files?")) {
	    push @tocopy, @possiblycopy;
	  }
	}
	foreach my $file (@tocopy) {
	  push @commands, "mv \"/tmp/boss/$file\" \"$icodebasedir/$sys/$file\"";
	}
	if (ApproveCommands
	    (Commands => \@commands,
	     Method => "parallel")) {
	  # run script to update links
	  push @completed, $sys;
	}
      }
    }
  }
  UpdateLinks
    (
     Codebases => \@completed,
     CodebaseDir => $icodebasedir,
    );
}

sub ComputeActivity {
  my $d1 = shift;
  my $dir = Dir::List->new();
  my $dirinfo = $dir->dirinfo($d1);

  foreach my $f2 (keys %{$dirinfo->{files}}) {
    print $dirinfo->{files}->{$f2}->{last_modified}."\n";
  }
}

sub Backup {

}

sub Document {
  my (%args) = (@_);
  my @completed;
  foreach my $sys (@{$args{Systems}}) {
    # find out what directory to put it in
    my $icodebasedir = GetCodebaseDir();
    print "<$sys>\n";

    # find out what the thing should be called
    my $sysname = QueryUser("What should the systems be called?");
    my $firstname = $args{FirstName} || "Andrew"; # QueryUser("LastName?");
    my $lastname = $args{LastName} || "Dougherty"; # QueryUser("LastName?");

    # copy the thing into a temporary directory
    if (ApproveCommands
	(Commands =>
	 [
	  "rm -rf /tmp/boss",
	  "mkdir /tmp/boss",
	  "cp -ar /var/lib/myfrdcsa/codebases/internal/boss/templates/docbook/* /tmp/boss"
	 ],
	 Method => "parallel")) {
      # make changes to the codebase files
      foreach my $file (split /\n/,`ls /tmp/boss`) {
	if (-f "/tmp/boss/$file") {
	  my $c = `cat "/tmp/boss/$file"`;
	  $c =~ s/MANUAL/$sysname/g;
	  $c =~ s/TITLE/$sysname/g;
	  $c =~ s/SYSTEM/$sysname/g;
	  $c =~ s/FIRSTNAME/$firstname/g;
	  $c =~ s/LASTNAME/$lastname/g;

	  my $OUT;
	  open (OUT,">/tmp/boss/$file") or die "ouch\n";
	  print OUT $c;
	  close (OUT);
	}
      }
      # make changes to the file names
      my @commands;
      foreach my $file (split /\n/,`ls /tmp/boss`) {
	my $ofile = $file;
	$ofile =~ s/manual/$sysname/;
	if ($file ne $ofile) {
	  push @commands, "mv \"/tmp/boss/$file\" \"/tmp/boss/$ofile\"";
	}
      }
      push @commands, "mkdirhier $icodebasedir/$sys/doc || true";
      if (ApproveCommands
	  (Commands => \@commands,
	   Method => "parallel")) {
	@commands = ();
	# test  whether  files   are  already  present  (smart  copy),
	# otherwise copy them into directory
	my @tocopy;
	my @possiblycopy;

	foreach my $file (split /\n/, `ls /tmp/boss`) {
	  if (! -f "$icodebasedir/$sys/doc/$file") {
	    push @tocopy, $file;
	  } else {
	    push @possiblycopy, $file;
	  }
	}
	if (@possiblycopy) {
	  if (Approve(Dumper(@possiblycopy)."\nOverwrite these files?")) {
	    push @tocopy, @possiblycopy;
	  }
	}
	foreach my $file (@tocopy) {
	  push @commands, "mv \"/tmp/boss/$file\" \"$icodebasedir/$sys/$file\"";
	}
	if (ApproveCommands
	    (Commands => \@commands,
	     Method => "parallel")) {
	  # run script to update links
	  push @completed, $sys;
	}
      }
    }
  }
  UpdateLinks
    (
     Codebases => \@completed,
     CodebaseDir => $icodebasedir,
    );
}

sub SVNImportImpl {
  my (%args) = (@_);
  my @completed;
  my $icodebasedir = GetCodebaseDir();
  my $username = $args{UserName} || "root";
  my $host = $args{Host} || "128.237.157.53";
  my $repository = $args{Repository} || "/usr/local/svnroot";
  foreach my $sys (@{$args{Systems}}) {
    my $codebasedir = $args{CodebaseDir} || "$icodebasedir/$sys";
    my $c = "svn import -m \"Initial import\" $codebasedir svn+ssh://$username\@$host:$repository/$sys";
    ApproveCommands(Commands => [$c]);
  }
}

sub ScrubImpl {
  my (%args) = (@_);
  # scrub clean an internal codebase directory
}

sub ObtainLatestReleaseInformation {
  my $h = {};
  foreach my $line (split /\n/,`ls -alrt /var/lib/myfrdcsa/codebases/internal`) {
    if ($line =~ /^.*?\s+(\w+) -> (.*)$/) {
      my $a = $1;
      my $b = $2;
      $b =~ /.*\/(.*)$/;
      my $c = $1;
      $h->{$a} = {
		  Release => $b,
		  Head => $c,
		  External => "/var/lib/myfrdcsa/codebases/external/$c",
		  Sandbox => "/var/lib/myfrdcsa/sandbox/$c/$c",
		 };
    }
  }
  return $h;
}

sub InCase {
  my @tocreatenewrelease = ICodebaseP(@_);
  my $hash = ObtainLatestReleaseInformation;
  foreach my $system (@tocreatenewrelease) {
    # obtain the release data
    my $h = $hash->{$system};

    # copy the files to their new sandbox location, touch the external
    # dir
    my $overwrite = 1;
    if (-d "/var/lib/myfrdcsa/sandbox/$h->{Head}") {
      # determine whether to overwrite
      if (Approve("Overwrite this installation?")) {
	ApproveCommands
	  (
	   Commands => [
			"rm -rf \"/var/lib/myfrdcsa/sandbox/$h->{Head}\"",
		       ],
	   Method => "parallel",
	  );
      } else {
	$overwrite = 0;
      }
    }
    if ($overwrite) {
      ApproveCommands
	(
	 Commands => [
		      "mkdirhier \"/var/lib/myfrdcsa/sandbox/$h->{Head}\"",
		      "cp -ar \"$h->{Release}\" \"/var/lib/myfrdcsa/sandbox/$h->{Head}\"",
		      "mkdir \"$h->{External}\"",
		     ],
	 Method => "parallel",
	);

      # do we delete the original debian file if it exists?
      if (-d $h->{Sandbox}."/debian") {
	ApproveCommands
	  (Commands => ["rm -rf ".$h->{Sandbox}."/debian"]);
      }
      if (-f $h->{Sandbox}."/Makefile") {
	ApproveCommands
	  (Commands => ["rm -rf ".$h->{Sandbox}."/Makefile"]);
      }
    }

    # get the small and medium descriptions of the packages

    # run packager
    ApproveCommands
      (
       Commands => [
		    "packager $system",
		   ],
       Method => "parallel",
      );
  }
}

sub ListModules {
  print join("\n",map {s/^\/usr\/share\/perl5\/// and $_} @{FindAllModules()});
}

sub ListScripts {
  print join("\n",@{FindAllScripts()});
}

sub ListElisp {
  print join("\n",@{FindAllElisp()});
}

sub GetCodebaseDir {
  Dir(Choose("internal codebases", "minor codebases","source hatchery"));
}

1;
