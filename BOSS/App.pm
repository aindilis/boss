package BOSS::LocalCodeBase;

use strict;

use vars qw/ $VERSION /;
$VERSION = '1.00';
use Class::MethodMaker
  new_with_init => 'new',
  get_set       => [ qw / HomeDir / ];

sub init {
  my ($self,%args) = (shift,@_);
  $self->HomeDir($args{HomeDir} || `pwd`);
}

sub Execute {
  my ($self,%args) = (shift,@_);
}

1;


1;
