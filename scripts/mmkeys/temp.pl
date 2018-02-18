#!/usr/bin/perl -w

use BOSS::App::DBus;
use BOSS::App::GMMKeys;

use Gtk2;

my @cmd = ('Play');

my $loop;
eval
  {
    require 'BOSS::App::DBus';
    require 'BOSS::App::DBus::Object';
    my $bus = $BOSS::App::DBus::bus || die;
    my $service = $bus->get_service($DBus_id || 'org.frdcsa.clear') || die;
    my $object = $service->get_object('/org/frdcsa/clear', 'org.frdcsa.clear') || die;
    # $object->RunCommand($_) for @cmd;
  };

my $running;
if ($@) {
  $running= "";
} else {
  $running = "using DBus id=$DBus_id";
}
print $running."\n";

my $mmkeys = BOSS::App::GMMKeys->new
  (
   AppName => 'org.frdcsa.clear',
   Commands =>
   {
    Previous	        => \&CommandBackward,
    Next		=> \&CommandForward,
    Play		=> \&CommandPause,
   },
  );
$mmkeys->Start();

Gtk2->main();

sub MyMainLoop {
  # check for user input
}

sub CommandBackward {
  print "Backward\n";
}

sub CommandForward {
  print "Forward\n";
}

sub CommandPause {
  print "Pause\n";
}

