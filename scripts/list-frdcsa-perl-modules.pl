#!/usr/bin/perl -w

use Data::Dumper;
use File::Slurp qw(read_file);
use IO::File;
use String::ShellQuote qw(shell_quote);

my $debug = 0;

my $c;
my $outfile = "/var/lib/myfrdcsa/codebases/internal/boss/data-git/perl-module-list.dat";
if (! -f $outfile) {
  my $fh1 = IO::File->new();
  $fh1->open(">$outfile") or die "no!\n";
  $c = `find /usr/share/perl5/ -follow | grep -E '\.pm\$'`;
  print $fh1 $c;
  $fh1->close();
} else {
  $c = read_file($outfile);
}

my $outfile = "/var/lib/myfrdcsa/codebases/internal/boss/data-git/frdcsa-perl-module-list.dat";
my $fh2 = IO::File->new();
$fh2->open(">$modulesfile") or die "no!\n";

my @frdcsamodules;

foreach my $file (split /\n/, $c) {
  # next unless $file =~ /\.pm$/;
  print "<$file>\n" if $debug;
  my $perlmodule = $file;
  $perlmodule =~ s/^\/usr\/share\/perl5\///sg;
  $perlmodule =~ s/\//::/sg;
  $perlmodule =~ s/.pm$//sg;
  print "<$perlmodule>\n" if $debug;
  my $quotedfile = shell_quote("$file");
  my $chasedfile = `chase $quotedfile`;
  chomp $chasedfile;
  print "<$chasedfile>\n" if $debug;
  if ($chasedfile =~ /^\/var\/lib\/myfrdcsa/) {
    push @frdcsamodules, {
			  Module => $perlmodule,
			  Path => $file,
			  ActualPath => $chasedfile,
			 };
  }
}



print $fh2 Dumper([sort @frdcsamodules]);
$fh2->close();

