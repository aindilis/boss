package BOSS::App::DBus::Object;

use base 'Net::DBus::Service';
use Net::DBus::Exporter 'org.frdcsa.clear';

sub new
{	my ($class,$service) = @_;
	my $self = $class->SUPER::new($service, '/org/frdcsa/clear');
	bless $self, $class;

	Glib::Idle->add(
		sub { 0; });

	return $self;
}
# dbus_method('RunCommand', ['string'], [],{no_return=>1});

1;
