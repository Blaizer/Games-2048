#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Games::2048' ) || print "Bail out!\n";
}

diag( "Testing Games::2048 $Games::2048::VERSION, Perl $], $^X" );
