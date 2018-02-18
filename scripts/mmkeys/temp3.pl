#!/usr/bin/perl -w

use BOSS::App::DBus;
use BOSS::App::GMMKeys;


use Gtk3 -init;
# my $window = Gtk3::Window->new ('toplevel');
# my $button = Gtk3::Button->new ('Quit');
# $button->signal_connect (clicked => sub { Gtk3::main_quit });
# $window->add ($button);
# $window->show_all;

my $mmkeys = BOSS::App::GMMKeys->new
  (
   AppName => 'org.frdcsa',
   Commands =>
   {
    Previous	        => \&CommandBackward,
    Next		=> \&CommandForward,
    Play		=> \&CommandPause,
    # Stop		=> \&CommandStop,
   },
  );
$mmkeys->Start();

Gtk3::main;

sub CommandBackward {
  print "Backward\n";
}

sub CommandForward {
  print "Forward\n";
}

sub CommandPause {
  print "Pause\n";
}

# sub CommandStop {
#   print "Stop\n";
# }

