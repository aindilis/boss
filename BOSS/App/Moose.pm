package BOSS::App::Moose;

use Moose;
use Moose::Util::TypeConstraints;

use BOSS::Config;
use MyFRDCSA qw(ConcatDir Dir);
use PerlLib::SwissArmyKnife;
use UniLang::Agent::Agent;
use UniLang::Util::Message;

has 'Specification' =>
  (
   is => 'ro',
   isa => 'Str',
   default => sub {
     '
	-u [<host> <port>]	Run as a UniLang agent

	-w			Require user input before exiting
';
   },
  );

has 'ConfFile' => ( is => 'rw', isa => 'Str', default => sub { "" } );

has 'Conf' =>
  (
   is => 'ro',
   isa => 'BOSS::Config',
   lazy => 1,
   default => sub {
     my ($self) = @_;
     BOSS::Config->new
	(
	 Spec => $self->Specification,
	 ConfFile => $self->ConfFile,
	);
   },
  );

has 'SystemName' => ( is => 'ro', isa => 'Str', required => 1 );

enum 'CodebaseType', [qw(internal minor)];

has 'CodebaseType' =>
  (
   is => 'ro',
   isa => 'CodebaseType',
  );

has 'ShortSystemDir' =>
  (
   is => 'ro',
   isa => 'Str',
   lazy => 1,
   default => sub {
     my ($self) = @_;
     $self->SystemName;
   },
  );

has 'SystemDir' =>
  (
   is => 'ro',
   isa => 'Str',
   lazy => 1,
   default => sub { 
     my ($self) = @_;
     ConcatDir( Dir( $self->CodebaseType . " codebases" ), $self->ShortSystemName );
   }
  );

has 'Agent' =>
  (
   is => 'ro',
   isa => 'Maybe[UniLang::Agent::Agent]',
   lazy => 1,
   default => sub {
     my ($self) = @_;
     my $conf = $self->Conf->CLIConfig;
     if (exists $conf->{'-u'}) {
       my $agent = UniLang::Agent::Agent->new
	   (Name => $self->SystemName,
	    ReceiveHandler => \&Receive);
       $agent->Register
	 (Host => defined $conf->{-u}->{'<host>'} ?
	  $conf->{-u}->{'<host>'} : "localhost",
	  Port => defined $conf->{-u}->{'<port>'} ?
	  $conf->{-u}->{'<port>'} : "9000");
       return $agent;
     }
   },
  );

has 'Receiver' =>
  (
   is => 'ro',
   isa => 'CodeRef',
   default => sub {
     my ($self) = @_;
     sub {
       my %args = @_;
       $self->ProcessMessage
	 (Message => $args{Message});
     }
   },
  );

sub ProcessMessage {
  my ($self,%args) = @_;
  my $m = $args{Message};
  my $it = $m->Contents;
  if ($it) {
    if ($it =~ /^echo\s*(.*)/) {
      $self->Agent->SendContents
	(Contents => $1,
	 Receiver => $m->{Sender});
    } elsif ($it =~ /^(quit|exit)$/i) {
      $self->Agent->Deregister;
      exit(0);
    }
  }
}

sub Execute {
  my ($self,%args) = @_;
  my $conf = $self->Conf->CLIConfig;
  if (exists $conf->{'-u'}) {
    # enter in to a listening loop
    while (1) {
      $self->Agent->Listen(TimeOut => 10);
    }
  }
  if (exists $conf->{'-w'}) {
    Message(Message => "Press any key to quit...");
    my $t = <STDIN>;
  }
}

no Moose;
1;
