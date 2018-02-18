#!/usr/bin/perl -w

use BOSS::App::GMMKeys;

use Glib;

use constant
{
 PROGRAM_NAME => 'GMMKeysTest',
};

Glib::set_application_name(PROGRAM_NAME);
Glib::Idle->add(\&MyMainLoop);

my $bus = Net::DBus::GLib->session();
my $service = $bus->export_service("org.frdcsa.clear");
my $object = SomeObject->new($service);

  Glib::MainLoop->new()->run();


  # my $bus = Net::DBus::GLib->session();

  # my $service = $bus->get_service("org.designfu.SampleService");
  # my $object = $service->get_object("/SomeObject");

  # my $list = $object->HelloWorld("Hello from example-client.pl!");


my $mmkeys = BOSS::App::GMMKeys->new
  (
   AppName => PROGRAM_NAME,
   Commands =>
   {
    Previous	        => \&CommandBackward,
    Next		=> \&CommandForward,
    Play		=> \&CommandPause,
   },
  );

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

Glib::Timeout->add(1000, sub {print "hi\n";});
