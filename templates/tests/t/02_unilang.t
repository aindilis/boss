#!/usr/bin/perl -w

use PerlLib::SwissArmyKnife;

use Test::More tests => 12;

use_ok('Data::Dumper');
use_ok('FileHandle');
use_ok('UniLang::Util::TempAgent');
use_ok('UniLang::Util::TestHarness');

my $testharness = UniLang::Util::TestHarness->new();
isa_ok( $testharness, 'UniLang::Util::TestHarness' );

$testharness->StartTemporaryUniLangInstance;

my $tempagent = UniLang::Util::TempAgent->new
  (
   Host => "localhost",
   Port => "9010",
  );
isa_ok( $tempagent, 'UniLang::Util::TempAgent' );

foreach my $contents (qw(Test1 Test2 Test3)) {
  my $res = $tempagent->MyAgent->QueryAgent
    (
     Sender => $tempagent->Name,
     Receiver => "Echo",
     Contents => $contents,
     Data => {
	      _DoNotLog => 1,
	     },
    );
  isa_ok( $res, 'UniLang::Util::Message' );
  is( $res->{Contents}, $contents, "The contents returned are correct." );
}

$testharness->StopTemporaryUniLangInstance;

1;
