#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'My::Perceptron' ) || print "Bail out!\n";
}

diag( "Testing My::Perceptron $My::Perceptron::VERSION, Perl $], $^X" );
