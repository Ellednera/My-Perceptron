#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Output;

use My::Perceptron;

#use local::lib;
use Text::Matrix;

use FindBin;

use constant TEST_FILE => $FindBin::Bin . "/book_list_test-filled.csv";
use constant NON_BINARY_FILE => $FindBin::Bin . "/book_list_test-filled-non-binary.csv";

my $nerve_file = $FindBin::Bin . "/perceptron_1.nerve";
my $perceptron = My::Perceptron::load_perceptron( $nerve_file );

ok ( my %c_matrix = $perceptron->get_confusion_matrix( { 
        full_data_file => TEST_FILE, 
        actual_output_header => "brand",
        predicted_output_header => "predicted",
    } ), 
    "get_confusion_matrix method is working");

is ( ref \%c_matrix, ref {}, "Confusion matrix in correct data structure" );

is ( $c_matrix{ true_positive }, 2, "Correct true_positive" );
is ( $c_matrix{ true_negative }, 4, "Correct true_negative" );
is ( $c_matrix{ false_positive }, 1, "Correct false_positive" );
is ( $c_matrix{ false_negative }, 3, "Correct false_negative" );

is ( $c_matrix{ total_entries }, 10, "Total entries is correct" );
ok ( My::Perceptron::_calculate_total_entries( \%c_matrix ), 
    "Testing the 'untestable' &_calculate_total_entries" );
is ( $c_matrix{ total_entries }, 10, "'illegal' calculation of total entries is correct" );

like ( $c_matrix{ accuracy }, qr/60/, "Accuracy seems correct to me" );
ok ( My::Perceptron::_calculate_accuracy( \%c_matrix ), 
    "Testing the 'untestable' &_calculate_accuracy" );
like ( $c_matrix{ accuracy }, qr/60/, "'illegal' calculation of accuracy seems correct to me" );

like ( $c_matrix{ sensitivity }, qr/40/, "Accuracy seems correct to me" );
ok ( My::Perceptron::_calculate_sensitivity( \%c_matrix ), 
    "Testing the 'untestable' &_calculate_sensitivity" );
like ( $c_matrix{ accuracy }, qr/60/, "'illegal' calculation of sensitivity seems correct to me" );

{
    local $@;
    eval {
        $perceptron->get_confusion_matrix( { 
            full_data_file => NON_BINARY_FILE,
            actual_output_header => "brand",
            predicted_output_header => "predicted",
        } );
    };

    like ( $@, qr/Something\'s wrong\!/, "Croaked! Found non-binary values in file");
}

stdout_like {
    
    ok ( 
        $perceptron->display_confusion_matrix( \%c_matrix, { 
            zero_as => "MP520", one_as => "Yi Lin" 
        } ),
    "display_confusion_matrix is working");
    
} qr /(A\:)|(P\:)|(actua)|(predicted)|(entries)|(Accuracy)|(Sensitivity)|(MP520)|(Yi Lin)/n, 
    "Correct stuff displayed";

{
    local $@;
    
    eval {
        $perceptron->display_confusion_matrix( \%c_matrix, { one_as => "Yi Lin" } );
    };
    
    like ( $@, qr/zero_as/, "Missing keys found: zero_as!" );
    unlike ( $@, qr/one_as/, "Confirmed one_as is present but not zero_as" );
}

{
    local $@;
    
    eval {
        $perceptron->display_confusion_matrix( \%c_matrix, { zero_as => "MP520" } );
    };
    
    like ( $@, qr/one_as/, "Missing keys found: one_as!" );
    unlike ( $@, qr/zero_as/, "Confirmed zero_as is present but not one_as" );
}

{
    local $@;
    
    eval {
        $perceptron->display_confusion_matrix( \%c_matrix );
    };
    
    like ( $@, qr/zero_as one_as/, "Both keys not found" );
}

done_testing;

# besiyata d'shmaya




