package BOSS;

use BOSS::ICodebase;
use BOSS::Maintenance;
use BOSS::Config;
use MyFRDCSA;
use PerlLib::Util qw(Date);

use Data::Dumper;

use strict;
use Carp;
use vars qw($VERSION);

$VERSION = '1.00';

use Class::MethodMaker new_with_init => 'new',
  get_set => [ qw / Conf / ];

sub init {
  my ($self,%args) = (shift,@_);
  my $specification = "
	stat		Project statistics

	create		Create new ICodebase(s) for satisfying certain requirements
	framework	Create OO Perl application framework
	framework-moose	Create an OO Moose Perl application framework
	promote		Promote ICodebase(s) to main archive from source-hatchery
	newrelease	Create a new release of a codebase

	combine		Combine ICodebases
	modernize	Modernize ICodebase(s) to meet latest standards
	updatelinks	Update ICodebase(s) global Perl symlinks

	document	Document ICodebase(s)
	statistics	Compile statistics for ICodebase(s)
	activity	Determine activity for ICodebase(s)
	metrics		Compute metrics for ICodebase(s)
	grep		Grep through ICodebase(s)
	quick_grep	Grep through ICodebase(s) quickly
        search		Fast search through ICodebase(s) using Namazu
	-c <lines>	Add a context to the search
        updatedb	Update the search index
	etags		Update the etags DB for Emacs and Perl code

	capabilities	List capabilities of ICodebase(s)
	add		Add capabilities to a ICodebase
	remove		Remove capabilities to a ICodebase
	transfer	Transfer capabilities to a different ICodebase
	cluster		Redistribute capabilities between ICodebases

	incase		Package ICodebase(s)

	scrub		Remove any personal information from ICodebase(s)
	svnimport	Import ICodebase(s) into a subversion repository

	delete		Delete an ICodebase
	demote		Demote ICodebase(s) to source-hatchery from main archive

	maintenance_daily	Perform daily maintenance

	data		Create data dir for this codebase

	list_modules	List all perl modules
	list_scripts	List all perl scripts
	list_elisp	List all Emacs Lisp files

	-y		AutoApprove

	<items>...	Items to be acted upon
";

  $self->Conf(BOSS::Config->new
		(
		 Spec => $specification,
		));
  $UNIVERSAL::systemdir = ConcatDir(Dir("internal codebases"),"boss");
}

sub Execute {
  my ($self,%args) = (shift,@_);
  my $conf = $self->Conf->CLIConfig;
  my %map = (
	     stat => sub {system "/var/lib/myfrdcsa/codebases/internal/boss/scripts/stat.pl"},
	     create => \&BOSS::ICodebase::Create,
	     delete => \&BOSS::ICodebase::Delete,
	     promote => \&BOSS::ICodebase::Promote,
	     demote => \&BOSS::ICodebase::Demote,
	     newrelease => \&BOSS::ICodebase::CreateNewRelease,
	     updatelinks => \&BOSS::ICodebase::UpdateLinks,
	     modernize => \&BOSS::ICodebase::Modernize,
	     package => \&BOSS::ICodebase::Package,
	     metrics => \&BOSS::ICodebase::Metrics,
	     framework => \&BOSS::ICodebase::Framework,
	     'framework-moose' => \&BOSS::ICodebase::FrameworkMoose,
	     svnimport => \&BOSS::ICodebase::SVNImport,
	     grep => \&BOSS::ICodebase::Grep,
	     quick_grep => \&BOSS::ICodebase::QuickGrep,
	     search => \&BOSS::ICodebase::Search,
	     updatedb => \&BOSS::ICodebase::UpdateDB,
	     etags => \&BOSS::ICodebase::Etags,
	     capabilities => \&BOSS::ICodebase::Capabilities,
	     incase => \&BOSS::ICodebase::InCase,
	     maintenance_daily => \&BOSS::Maintenance::Execute,
	     list_modules => \&BOSS::ICodebase::ListModules,
	     list_scripts => \&BOSS::ICodebase::ListScripts,
	     list_elisp => \&BOSS::ICodebase::ListElisp,
	    );

  my $logfile = $UNIVERSAL::systemdir."/data/boss-operations.log";
  my $OUT;
  open(OUT,">>$logfile") or warn "cannot open operations log: <$logfile>\n";
  foreach my $key (keys %$conf) {
    next if $key =~ /^(_|<items>|-y)/;
    if (exists $map{$key}) {
#       foreach my $item (@{$conf->{'<items>'}}) {
#       &{$map{$key}}($item);
#       }
      if ($key eq "updatelinks") {
	&{$map{$key}}(Codebases => $conf->{'<items>'});
      } else {
	&{$map{$key}}(@{$conf->{'<items>'}});
      }
      print OUT join(", ",(Date(),$key,@{$conf->{'<items>'}}))."\n";
    } else {
      if ($key ne "-c") {
	print "Sorry, <$key> not implemented yet\n";
      }
    }
  }
  close(OUT);
}

1;
