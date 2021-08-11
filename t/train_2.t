#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

plan( skip_all => "This is sort of the actual program for debugging" );
done_testing;

use My::Perceptron;

use FindBin;
use constant TRAINING_DATA => $FindBin::Bin . "/book_list_train.csv";
use constant MODULE_NAME => "My::Perceptron";
use constant WANT_STATS => 1;
use constant IDENTIFIER => "book_name";

# 36 headers
my @attributes = qw ( 
    glossy_cover	has_plastic_layer_on_cover	male_present	female_present	total_people_1	total_people_2	total_people_3
	total_people_4	total_people_5_n_above	has_flowers	flower_coverage_more_than_half	has_leaves	leaves_coverage_more_than_half	has_trees
	trees_coverage_more_than_half	has_other_living_things	has_fancy_stuff	has_obvious_inanimate_objects	red_shades	blue_shades	yellow_shades
	orange_shades	green_shades	purple_shades	brown_shades	black_shades	overall_red_dominant	overall_green_dominant
	overall_yellow_dominant	overall_pink_dominant	overall_purple_dominant	overall_orange_dominant	overall_blue_dominant	overall_brown_dominant
	overall_black_dominant	overall_white_dominant );

my $total_headers = scalar @attributes;

my $perceptron = My::Perceptron->new( {
    initial_value => 0.01,
    learning_rate => 0.001,
    threshold => 0.8,
    attribs => \@attributes
} );

my $nerve_file = $FindBin::Bin . "/perceptron_1.nerve";

for ( 0..5 ) {
    print "Rounf $_\n";
    $perceptron->train( TRAINING_DATA, "brand", $nerve_file, WANT_STATS, IDENTIFIER );
    print "\n";
}
#print Dumper($perceptron), "\n";




# besiyata d'shmaya







