package APP::Class;

use Data::Dumper;

use Moose;

has Attribute =>
  (
   is => "rw",
   isa => "String",
  );

sub Method {
  my ($self,%args) = @_;
}

1;
