#!/usr/bin/perl -w

use PerlLib::UI::AutoGenerate;

my $auto = PerlLib::UI::AutoGenerate->new;

$auto->GenerateUIForCodebase;
