#!/usr/bin/perl -w

use Test::More no_plan;
use Test::Deep;

use_ok('UniLang::Util::TempAgent');
use_ok('UniLang::Util::TestHarness');

my $testharness1;
eval {
  $testharness1 = UniLang::Util::TestHarness->new
    (
     Host => "localhost",
     Port => "9010",
    );
};
isa_ok( $testharness1, 'UniLang::Util::TestHarness' );

my $testharness2;
eval {
  $testharness2 = UniLang::Util::TestHarness->new
    (
     Host => "localhost",
     Port => "9011",
    );
};
isa_ok( $testharness2, 'UniLang::Util::TestHarness' );

$testharness1->StartTemporaryUniLangInstance();
$testharness2->StartTemporaryUniLangInstance();

# now setup messages between the two

my $tempagent1;
eval {
  $tempagent1 = UniLang::Util::TempAgent->new
    (
     Host => "localhost",
     Port => "9010",
    );
};
isa_ok( $tempagent1, 'UniLang::Util::TempAgent' );

my $tempagent2;
eval {
  $tempagent2 = UniLang::Util::TempAgent->new
    (
     Host => "localhost",
     Port => "9011",
    );
};
isa_ok( $tempagent2, 'UniLang::Util::TempAgent' );

if (0) {
  my $res001 = $tempagent1->MyAgent->QueryAgent
    (
     Receiver => "WS-Server-XMLRPC",
     Contents => "",
     Data => {
	      _DoNotLog => 1,
	     },
    );
  isa_ok( $res001, 'UniLang::Util::Message' );

  my $res002 = $tempagent1->MyAgent->QueryAgent
    (
     Receiver => "WS-Client-XMLRPC",
     Contents => "",
     Data => {
	      _DoNotLog => 1,
	     },
    );
  isa_ok( $res002, 'UniLang::Util::Message' );
}

# we should just run the script as a separate process

# now how do we go about doing this?  do we have to fork?  how will
# testing handle that?

$testharness1->StopTemporaryUniLangInstance;
$testharness2->StopTemporaryUniLangInstance;
