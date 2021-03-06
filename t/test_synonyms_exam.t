#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Test::Output;

use My::Perceptron;

use FindBin;

use constant TEST_DATA => $FindBin::Bin . "/book_list_test.csv";
use constant TEST_DATA_NEW_FILE => $FindBin::Bin . "/book_list_test_exam-filled.csv";
use constant MODULE_NAME => "My::Perceptron";
use constant WANT_STATS => 1;
use constant IDENTIFIER => "book_name";

my $nerve_file = $FindBin::Bin . "/perceptron_1.nerve";
ok( -s $nerve_file, "Found nerve file to load" );

my $mature_nerve = My::Perceptron::load_perceptron( $nerve_file );

# write to original file
stdout_like {
    ok ( $mature_nerve->take_real_exam( {
            stimuli_validate => TEST_DATA,
            predicted_column_index => 4,
        } ), 
        "Testing stage succedded!" );

} qr/book_list_test\.csv/, "Correct output for testing when saving back to original file";


# with new output file
stdout_like {
    ok ( $mature_nerve->take_real_exam( {
            stimuli_validate => TEST_DATA,
            predicted_column_index => 4,
            results_write_to => TEST_DATA_NEW_FILE
        } ), 
        "Testing stage succedded!" );

} qr/book_list_test_exam\-filled\.csv/, "Correct output for testing when saving to NEW file";

ok( -e TEST_DATA_NEW_FILE, "New testing file found" );
isnt( -s TEST_DATA_NEW_FILE, 0, "New output file is not empty" );

done_testing;
# besiyata d'shmaya







