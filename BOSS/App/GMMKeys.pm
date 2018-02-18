package BOSS::App::GMMKeys;

use PerlLib::SwissArmyKnife;

use Moose;
use Net::DBus;
use Net::DBus::Reactor;

has 'AppName' => (is => 'rw', isa => 'Str', default => sub { "defaultApp" });
has 'DBus' => (is => 'rw', isa => 'Net::DBus', default => sub { Net::DBus->find });
has 'Service' => (is => 'rw', isa => 'Maybe[Net::DBus::RemoteService]', lazy => 1, default => undef);
has 'Object' => (is => 'rw', isa => 'Maybe[Net::DBus::RemoteObject]', lazy => 1, default => undef);
has 'ExampleCommands' =>
  (
   is => 'rw',
   isa => 'HashRef',
   default => sub {
     return
       {
	Previous        => 'PrevSong',
	Next		=> 'NextSong',
	Play		=> 'PlayPause',
	Stop		=> 'Stop',
       }
     },
  );
has 'Commands' => (is => 'rw', isa => 'Maybe[HashRef]', lazy => 1, default => undef);

our $myself;

sub callback {
  my ($app,$key) = @_;
  print Dumper(\@_);
  return unless $app eq $myself->AppName;
  if (my $cmd = $myself->Commands->{$key}) {
    if (ref($cmd) eq "CODE") {
      $cmd->();
    } else {
      print Dumper($cmd);
    }
  } else {
    warn "gnome_mmkeys : unknown key : $key\n";
  }
  $myself->Stop;
  $myself->Start;
}

sub DBusDispatcher {
    my ($reactor,$type,$fd) = @{$_[2]};
    return 0 unless $reactor->{fds}->{$type}->{$fd}->{enabled};
    $reactor->{fds}->{$type}->{$fd}->{callback}->invoke;
    $_->invoke foreach $reactor->_dispatch_hook();
    return 1;
}

sub BUILD {
  my ($self, $args) = @_;
  my %args = %{$args || {}};
  $myself = $self;

  $self->Service($self->DBus->get_service('org.gnome.SettingsDaemon'));
  $self->Object($self->Service->get_object('/org/gnome/SettingsDaemon/MediaKeys'));
  eval {
    $self->Object->connect_to_signal(MediaPlayerKeyPressed => \&callback);
  };

  if ($@) {
    my $error = $@;
    # try with old path (for gnome version until ~2.20  <2.22)
    $self->Object($self->Service->get_object('/org/gnome/SettingsDaemon'));
    eval { $self->Object->connect_to_signal(MediaPlayerKeyPressed => \&callback); };
    die $error if $@;		#die with the original error
  }
  print SeeDumper({Commands => $self->Commands});


  # Set up a GTK-compatible Reactor, based on gmusicbrowser
  my $reactor = Net::DBus::Reactor->main();
  my %types = (read => 'in', write => 'out', exception => 'err');
  foreach my $type ( keys %{$reactor->{fds}} ) {
    my $gtktype = $types{$type} or die;
    foreach my $fd ( keys %{$reactor->{fds}->{$type}} ) {
      Glib::IO->add_watch($fd, $gtktype, \&DBusDispatcher,
			  [$reactor, $type, $fd]);
    }
  }
  my $timeout = $reactor->add_timeout(1, Net::DBus::Callback->new(method => sub {}));
  $reactor->step;
  $reactor->remove_timeout($timeout);
  1;

}

sub Start {
  my ($self, $args) = @_;
  my %args = %{$args || {}};
  # print SeeDumper({Ref => ref($self->Object)});
  $self->Object->GrabMediaPlayerKeys($self->AppName,0);
}

sub Stop {
  my ($self, $args) = @_;
  my %args = %{$args || {}};
  # print SeeDumper({Ref => ref($self->Object)});
  $self->Object->ReleaseMediaPlayerKeys($self->AppName);
}

1;
