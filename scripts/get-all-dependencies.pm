#!/usr/bin/perl -w

my $file = shift;

@queue;
%marked;

sub AddFileToQueue {
  my $file = shift;
  if (! exists $marked->{$file}) {
    $marked->{$file} = 1;
    push @queue, $file;
  }
}

AddFileToQueue($file);
