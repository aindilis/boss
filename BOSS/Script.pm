package BOSS::Script;

# this really needs to be fixed up

# Most  of  my  programs  have  descriptions that  could  be  used  to
# bootstrap the learning of task mappings to files.  Like this one for
# instance.

# We can also attempt to determine  what the programs do by looking at
# their function names and their structure, and mapping these to items
# in the todo, and by inferring  based on what project they belong to,
# etc, so as to reason towards likely solutions.

# use Learner::Method;

use Data::Dumper;

use Class::MethodMaker
  new_with_init => 'new',
  get_set       =>
  [

   qw / MyMethod FileName /

  ];

sub init {
  my ($self,%args) = @_;
  $self->FileName($args{FileName});
  # $self->MyMethod(Learner::Method->new());
}

sub Execute {
  my ($self,%args) = @_;
  foreach my $f (@{$args{File}}) {
    my $ret = $self->ProcessCommentsInFile(File => $f);
    print join("\n",@{$ret->{Comments}})."\n";
  }
}

sub Train {
  my ($self,%args) = @_;
  # train it on non comments
  # get some files names
  # now get some random english text
  my @files = (); # ?
  foreach my $file (splice(@files,0,10)) {
    my $res = $self->ProcessCommentsInFile(File => $file);
    foreach my $l (@{$res->{Other}}) {
      $self->MyMethod->Train($l => "comment");
    }
  }

  # retrieve some random perl files for reading
  @files = split /\n/, `locate pm | grep '\.pm\$' | rl`;
  foreach my $file (splice(@files,0,10)) {
    my $res = $self->ProcessCommentsInFile(File => $file);
    foreach my $l (@{$res->{Other}}) {
      $self->MyMethod->Train($l => "other");
    }
  }
}

sub ProcessCommentsInFile {
  my ($self,%args) = @_;
  my $f = $args{File};
  my $uselearner = 0;
  my @comments;
  my @other;
  if (-f $f) {
    my $c = `cat "$f"`;
    foreach my $l (split /\n/, $c) {
      if ($uselearner) {
	if ($self->MyMethod->Predict($l) eq "comment") {
	  push @comments, $1;
	} else {
	  push @other, $l;
	}
      } else {
	if ($l =~ /^.*\#(.*)/) {
	  push @comments, $1;
	} else {
	  push @other, $l;
	}
      }
    }
  }
  return {Comments => \@comments,
	  Other => \@other};
}

1;
