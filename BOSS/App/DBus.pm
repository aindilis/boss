package BOSS::App::DBus;

use BOSS::App::DBus::Object;

use Glib;
use Net::DBus;
use Net::DBus::Service;

my $not_glib_dbus;
our $bus;
eval { require Net::DBus::GLib; $bus = Net::DBus::GLib->session; };
unless ($bus)
{	#warn "Net::DBus::GLib not found (not very important)\n";
	$not_glib_dbus=1;
	$bus= Net::DBus->session;
}

Glib::Idle->add(\&init); #initialize once the main gmb init is finished

sub init
{	#my $bus = Net::DBus->session;
	my $service= $bus->export_service('org.frdcsa.clear');	# $::DBus_id is 'org.gmusicbrowser' by default
	my $object = BOSS::App::DBus::Object->new($service);
	DBus_mainloop_hack() if $not_glib_dbus;
	0; #called in an idle, return 0 to run only once
}

sub DBus_mainloop_hack
{	# use Net::DBus internals to connect it to the Glib mainloop, though unlikely, it may break with future version of Net::DBus
	use Net::DBus::Reactor;
	my $reactor=Net::DBus::Reactor->main;

	for my $ref (['in','read'],['out','write'], ['err','exception'])
	{	my ($type1,$type2)=@$ref;
		for my $fd (keys %{$reactor->{fds}{$type2}})
		{	#warn "$fd $type2";
			Glib::IO->add_watch($fd,$type1,
			sub{	my $cb=$reactor->{fds}{$type2}{$fd}{callback};
				$cb->invoke if $cb;
				$_->invoke for $reactor->_dispatch_hook;
				1;
			   }) if $reactor->{fds}{$type2}{$fd}{enabled};
			#Glib::IO->add_watch($fd,$type1,sub { Net::DBus::Reactor->main->step;Net::DBus::Reactor->main->step;1; }) if $reactor->{fds}{$type2}{$fd}{enabled};
		}
	}

	# run the dbus mainloop once so that events already pending are processed
	# needed if events already waiting when gmb is starting
		my $timeout=$reactor->add_timeout(1, Net::DBus::Callback->new( method => sub {} ));
		Net::DBus::Reactor->main->step;
		$reactor->remove_timeout($timeout);
}

1;
