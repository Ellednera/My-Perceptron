package My::Perceptron;

use 5.006;
use strict;
use warnings;
use Carp "croak";

use utf8;
binmode STDOUT, ":utf8";

use local::lib;
use Text::CSV qw(csv);
use Text::Matrix;

=head1 NAME

My::Perceptron

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.04';

# default values
use constant LEARNING_RATE => 0.05;
use constant THRESHOLD => 0.5;
use constant TUNE_UP => 1;
use constant TUNE_DOWN => 0;

=head1 SYNOPSIS

    #!/usr/bin/perl

    use My::Perceptron;

    # create a new nerve / neuron / perceptron
    $perceptron = My::Perceptron->new( {
        initial_value => $any_value_that_makes_sense, # size of each dendrite :)
        learning_rate => 0.3, # optional
        threshold => 0.85, # optional
        attribs => \@attributes, # dendrites / header names in csv files to train
    } );

    # training
    $perceptron->train( $training_data_csv, $expected_column_name, $save_nerve_to );
    # or
    $perceptron->train(
        $training_data_csv, $expected_column_name, $save_nerve_to, 
        $show_progress, $identifier); # these two parameters must go together


    # validating
    # fill results to original file
    $perceptron->validate( { 
        stimuli_validate => $validation_data_csv, 
        predicted_column_index => 4,
     } );
    # or        
    # fill results to a new file
    $perceptron->validate( {
        stimuli_validate => $validation_data_csv,
        predicted_column_index => 4,
        results_write_to => $new_csv
    } );


    # testing, parameters same as validate
    $perceptron->test( { 
        stimuli_validate => $testing_data_csv, 
        predicted_column_index => 4,
     } );
    # or        
    # fill results to a new file
    $perceptron->test( {
        stimuli_validate => $testing_data_csv,
        predicted_column_index => 4,
        results_write_to => $new_csv
    } );


    # confusion matrix
    my %c_matrix = $perceptron->get_confusion_matrix( { 
        full_data_file => $file_csv, 
        actual_output_header => $header_name,
        predicted_output_header => $predicted_header_name
    } );

    # accessing the confusion matrix
    my @keys = qw( true_positive true_negative false_positive false_negative 
                   total_entries accuracy sensitivity );
    for ( @keys ) {
        print $_, " => ", $c_matrix{ $_ }, "\n";
    }

    # output to console
    $perceptron->display_confusion_matrix( \%c_matrix, { 
        zero_as => "bad apples", # cat  milk   green  etc.
        one_as => "good apples", # dog  honey  pink   etc.
    } );


    # save data of the trained perceptron
    my $nerve_file = "apples.nerve";
    My::Perceptron::save_perceptron( $perceptron, $nerve_file );

    # load data of percpetron for use in actual program
    my $apple_nerve = My::Perceptron::load_perceptron( $nerve_file ); # :)

=head1 DESCRIPTION

This module provides methods to build, train, validate and test a perceptron. It can also save the data of the perceptron for future use for any actual AI programs.

This module is also aimed to help newbies grasp hold of the concept of perceptron, training, validation and testing as much as possible. Hence, all the methods and subroutines in this module are decoupled as much as possible so that the actual scripts can be written as simple complete programs.

The implementation here is super basic as it only takes in input of the dendrites and calculate the output. If the output is 
higher than the threshold, the final result (category) will be 1 aka perceptron is activated. If not, then the 
result will be 0 (not activated).

Depending on how you view or categorize the final result, the perceptron will fine tune itself (aka train) based on 
the learning rate until the desired result is met. Everything from here on is all mathematics and numbers which only makes sense to the computer and not humans anymore.

Whenever the perceptron fine tunes itself, it will increase/decrease all the dendrites that is significant (attributes  
labelled 1) for each input. This means that even when the perceptron successfully fine tunes itself to suite all 
the data in your file for the first round, the perceptron might still get some of the things wrong for the next 
round of training. Therefore, the perceptron should be trained for as many rounds as possible. The more "confusion" 
the perceptron is able to correctly handle, the more "mature" the perceptron is. No one defines how "mature" it is 
except the programmer himself/herself :)

=head1 EXPORT

None. 

Almost everything is OO with some exceptions of course :)

=head1 CREATION RELATED SUBROUTINES/METHODS

=head2 new ( \%options )

Creates a brand new perceptron and initializes the value of each ATTRIBUTE or "thickness" of the dendrites :)

For C<%options>, the followings are needed unless mentioned:

=over 4

=item initial_value => $decimal

The value or thickness :) of ALL the dendrites when a new perceptron is created.

Generally speaking, this value is usually between 0 and 1. However, it all depend on your combination of numbers for the other options.

=item attribs => $array_ref

An array reference containing all the attributes the perceptron should have.

=item learning_rate => $decimal

Optional. The default is C<0.05>.

The learning rate or the "rest duration" of the perceptron for the fine-tuning process (between 0 and 1). 

Generally speaking, the smaller the value the better. This value is usually between 0 and 1. However, it all depend on your combination of numbers for the other options.

=item threshold => $decimal

Optional. The default is C<0.5>

This is the passing rate to determine the neuron output (0 or 1).

Generally speaking, this value is usually between 0 and 1. However, it all depend on your combination of numbers for the other options.

=back

=cut

sub new {
    my $class = shift;
    
    my $data_ref = shift;
    my %data = %{ $data_ref };
    
    # check keys
    $data{ learning_rate } = LEARNING_RATE if not exists $data{ learning_rate };
    $data{ threshold } = THRESHOLD if not exists $data{ threshold };
    
    # don't pack this key checking process into a subroutine for now
    # this is also used in &_real_validate_or_test
    my @missing_keys;
    for ( qw( initial_value attribs ) ) {
        push @missing_keys, $_ unless exists $data{ $_ };
    }
    
    croak "Missing keys: @missing_keys" if @missing_keys;
    
    # continue to process the rest of the data
    my %attributes;
    for ( @{ $data{ attribs } } ) {
        $attributes{ $_ } = $data{ initial_value };
    }
    
    my %processed_data = (
        learning_rate => $data{ learning_rate },
        threshold => $data{ threshold },
        attributes_hash_ref => \%attributes,
        #attribs_name => $data{ attribs }, # just take the keys of %'attributes_hash'
    );
    
    bless \%processed_data, $class;
}

=head2 get_attributes

Obtains a hash of all the attributes of the perceptron

=cut

sub get_attributes {
    my $self = shift;
    %{ $self->{attributes_hash_ref} };
}

=head2 learning_rate ( $value )

=head2 learning_rate

If C<$value> is given, sets the learning rate to C<$value>. If not, then it returns the learning rate.

The C<$value> should be between C<0> and C<1>. Default is C<0.05>

=cut

sub learning_rate {
    my $self = shift;
    if ( @_ ) {
        $self->{learning_rate} = shift;
    } else {
        $self->{learning_rate}
    }
}

=head2 threshold ( $value )

=head2 threshold

If C<$value> is given, sets the threshold / passing rate to C<$value>. If not, then it returns the passing rate.

The C<$value> should be between C<0> and C<1>. Default is C<0.5>

=cut

sub threshold {
    my $self = shift;
    if ( @_ ) {
        $self->{ threshold } = shift;
    } else {
        $self->{ threshold };
    }
}

=head1 TRAINING RELATED SUBROUTINES/METHODS

All the training methods here have the same parameters as the two actual C<train> method and they all do the same stuff. They are also used in the same way.

=head2 tame ( ... )

=head2 exercise ( ... )

=head2 train ( $stimuli_train_csv, $expected_output_header, $save_nerve_to_file )

=head2 train ( $stimuli_train_csv, $expected_output_header, $save_nerve_to_file, $display_stats, $identifier )

Trains the perceptron. 

C<$stimuli_train_csv> is the set of data / input (in CSV format) to train the perceptron while C<$save_nerve_to_file> is 
the filename that will be generate each time the perceptron finishes the training process. This data file is the data of the C<My::Perceptron> 
object and it is used in the C<validate> method.

C<$expected_output_header> is the header name of the columns in the csv file with the actual category or the exepcted values. This is used to determine to tune the nerve up or down. This value should only be 0 or 1 for the sake of simplicity.

C<$display_stats> is B<optional> and the default is 0. It will display more output about the tuning process. It will show the followings:

=over 4

=item tuning status

Indicates the nerve was tuned up or down

=item old sum

The original sum of all C<weightage * input>

=item threshold

The threshold of the nerve

=item new sum

The new sum of all C<weightage * input> after fine-tuning the nerve

=back

If C<$display_stats> is set to C<1>, then you must specify the C<$identifier>. This is the column / header name that is used to identify a specific row of data in C<$stimuli_train_csv>.

=cut

sub tame {
    #my $self = shift;
    #$self->train( @_ );
    train( @_ );
}

sub exercise {
    train( @_ );
}

sub train {
    my $self = shift;
    my( $stimuli_train_csv, $expected_output_header, $save_nerve_to_file, $display_stats, $identifier ) = @_;
    
    $display_stats = 0 if not defined $display_stats;
    if ( $display_stats and not defined $identifier ) {
        croak "Please specifiy a string for \$identifier if you are trying to display stats";
    }
    
    # CSV processing is all according to the documentation of Text::CSV
    open my $data_fh, "<:encoding(UTF-8)", $stimuli_train_csv 
        or die "Can't open $stimuli_train_csv: $!";
    
    my $csv = Text::CSV->new( {auto_diag => 1, binary => 1} );
    
    # tested up till here, here onwards, manual checking
    my $attrib = $csv->getline($data_fh);
    #use Data::Dumper;    #print Dumper($attrib);    #print $attrib;    #no Data::Dumper;
    $csv->column_names( $attrib );

    # individual row
    ROW: while ( my $row = $csv->getline_hr($data_fh) ) {
        # print $row->{book_name}, " -> ";
        # print $row->{$expected_output_header} ? "??????\n" : "????????????\n";

        # calculate the output and fine tune parameters if necessary
        # THIS PART IS STILL INCOMPLETE
        while (1) {
            my $output = _calculate_output( $self, $row );
            
            #print "Sum = ", $output, "\n";
            
            # $expected_output_header to be checked together over here
            # if output >= threshold
            #    then category/result aka output is considered 1
            # else output considered 0
            
            # output expected/actual tuning
            #    0       0             -
            #    1       0             down
            #    0       1             up
            #    1       1             -
            if ( ($output >= $self->threshold) and ( $row->{$expected_output_header} eq 0 ) ) {
                _tune( $self, $row, TUNE_DOWN );

                # debugging purpose
                if ( $display_stats ) {
                    print $row->{$identifier}, "\n";
                    print "   -> TUNED DOWN";
                    print "   Old sum = ", $output;
                    print "   Threshold = ", $self->threshold;
                    print "   New Sum = ", _calculate_output( $self, $row ), "\n";                
                }
                
                #last; # break out during tests for the moment
            } elsif ( ($output < $self->threshold) and ( $row->{$expected_output_header} eq 1 ) ) {
                _tune( $self, $row, TUNE_UP );
                
                # debugging purpose
                if ( $display_stats ) {
                    print $row->{$identifier}, "\n";
                    print "   -> TUNED UP";
                    print "   Old sum = ", $output;
                    print "   Threshold = ", $self->threshold;
                    print "   New Sum = ", _calculate_output( $self, $row ), "\n";
                }
               # last;
            } elsif ( ($output < $self->threshold) and ( $row->{$expected_output_header} eq 0 ) ) {
            
                if ( $display_stats ) {
                    print $row->{$identifier}, "\n";
                    print "   -> NO TUNING NEEDED";
                    print "   Sum = ", _calculate_output( $self, $row );
                    print "   Threshold = ", $self->threshold, "\n";
                }
                
                next ROW;
                
            } elsif ( ($output >= $self->threshold) and ( $row->{$expected_output_header} eq 1 ) ) {
            
                if ( $display_stats ) {
                    print $row->{$identifier}, "\n";
                    print "   -> NO TUNING NEEDED";
                    print "   Sum = ", _calculate_output( $self, $row );
                    print "   Threshold = ", $self->threshold, "\n";
                }
                
                next ROW;
            } #else { print "Something's not right\n'" }
        }
    }

    close $data_fh;
    
    save_perceptron( $self, $save_nerve_to_file ); # this doesn't return anything
    
}

=head2 &_calculate_output( $self, \%stimuli_hash )

Calculates and returns the C<sum(weightage*input)> for each individual row of data. For the coding part, it justs add up all the existing weight since C<input> is always 1 for now :)

C<%stimuli_hash> is the actual data to be used for training. It might contain useless columns.

This will get all the avaible dendrites through the C<get_attributes> method and then use all the keys ie. headers to access the corresponding values.

This subroutine should be called in the procedural way for now.

=cut

sub _calculate_output {
    my $self = shift; 
    my $stimuli_hash_ref = shift;
    
    my %dendrites = $self->get_attributes;
    my $sum; # this is the output
    
    for ( keys %dendrites ) {
        # if input is 1 for a dendrite, then calculate it
        if ( $stimuli_hash_ref->{ $_ } ) {
            # $sum += $dendrites{ $_ } * 1; # no need, if 1 then it is always the value itself
            # this is very efficient, nice :)
            $sum += $dendrites{ $_ };
        }
    }
    $sum;
    #1; #0.01;
}

=head2 &_tune( $self, \%stimuli_hash, $tune_up_or_down )

Fine tunes the nerve. This will directly alter the attributes values in C<$self> according to the attributes / dendrites specified in C<new>.

The C<%stimuli_hash> here is the same as the one in the C<_calculate_output> method.

C<%stimuli_hash> will be used to determine which dendrite in C<$self> needs to be fine-tuned. As long as the value of any key in C<%stimuli_hash> returns true (1) then that dendrite in C<$self> will be tuned.

Tuning up or down depends on C<$tune_up_or_down> specifed by the C<&_calculate_output> subroutine. The following constants can be used for C<$tune_up_or_down>:

=over 4

=item TUNE_UP

Value is C<1>

=item TUNE_DOWN

Value is C<0>

=back

This subroutine should be called in the procedural way for now.

=cut

sub _tune {
    my $self = shift; 
    my ( $stimuli_hash_ref, $tuning_status ) = @_;

    my %dendrites = $self->get_attributes;

    for ( keys %dendrites ) {
        if ( $tuning_status == TUNE_DOWN ) {
            
            if ( $stimuli_hash_ref->{ $_ } ) { # must check this one, it must be 1 before we can alter the actual dendrite size in the nerve :)
                $self->{ attributes_hash_ref }{ $_ } -= $self->learning_rate;
            }
            
            #print $_, ": ", $self->{ attributes_hash_ref }{ $_ }, "\n";
            
        } elsif ( $tuning_status == TUNE_UP ) {
            if ( $stimuli_hash_ref->{ $_ } ) {
                $self->{ attributes_hash_ref }{ $_ } += $self->learning_rate;
            }
            #print $_, ": ", $self->{ attributes_hash_ref }{ $_ }, "\n";
            
        }
    }

    #print "_tune returned 1\n";
    #1; #last; # calling last here will give warnings
}

=head1 VALIDATION RELATED METHODS

All the validation methods here have the same parameters as the actual C<validate> method and they all do the same stuff. They are also used in the same way.

=head2 take_mock_exam (...)

=head2 take_lab_test (...)

=head2 validate ( \%options )

This method validates the perceptron against another set of data after it has undergone the training process.

This method calculates the output of each row of data and write the result into the predicted column. The data begin written into the new file or the original file will maintain it's sequence.

Please take note that this method will load all the data of the validation stimuli, so please split your stimuli into multiple files if possible and call this method a few more times.

For C<%options>, the followings are needed unless mentioned:

=over 4

=item stimuli_validate => $csv_file

This is the CSV file containing the validation data, make sure that it contains a column with the predicted values as it is needed in the next key mentioned: C<predicted_column_index>

=item predicted_column_index => $column_number

This is the index of the column that contains the predicted output values. C<$index> starts from C<0>.

This part will be filled and saved to C<results_write_to>.

=item results_write_to => $new_csv_file

Optional.

The default behaviour will write the predicted output into C<stimuli_validate> ie the original data while maintaining the original sequence.

=back

I<*This method will call &_real_validate_or_test to do the actual work.>

=cut

sub take_mock_exam {
    my ( $self, $data_hash_ref ) = @_;
    $self->_real_validate_or_test( $data_hash_ref );
}

sub take_lab_test {
    my ( $self, $data_hash_ref ) = @_;
    $self->_real_validate_or_test( $data_hash_ref );
}

sub validate {
    my ( $self, $data_hash_ref ) = @_;
    $self->_real_validate_or_test( $data_hash_ref );
}

=head1 TESTING RELATED SUBROUTINES/METHODS

All the testing methods here have the same parameters as the actual C<test> method and they all do the same stuff. They are also used in the same way.

=head2 take_real_exam (...)

=head2 work_in_real_world (...)

=head2 test ( \%options )

This method is used to put the trained nerve to the test. You can think of it as deploying the nerve for the actual work.

This method works and behaves the same way as the C<validate> method. See C<validate> for the details.

I<*This method will call &_real_validate_or_test to do the actual work.>

=cut

# redirect to _real_validate_or_test
sub take_real_exam {
    my ( $self, $data_hash_ref ) = @_;
    $self->_real_validate_or_test( $data_hash_ref );
}

sub work_in_real_world {
    my ( $self, $data_hash_ref ) = @_;
    $self->_real_validate_or_test( $data_hash_ref );
}

sub test {
    my ( $self, $data_hash_ref ) = @_;
    $self->_real_validate_or_test( $data_hash_ref );
}

=head2 _real_validate_or_test ( $data_hash_ref )

This is where the actual validation or testing takes place. 

C<$data_hash_ref> is the list of parameters passed into the C<validate> or C<test> methods.

This is a B<method>, so use the OO way. This is one of the exceptions to the rules where private subroutines are treated as methods :)

=cut

sub _real_validate_or_test {

    my $self = shift;   my $data_hash_ref = shift;
    
    # don't pack this into a subroutine
    my @missing_keys;
    for ( qw( stimuli_validate predicted_column_index ) ) {
        push @missing_keys, $_ unless exists $data_hash_ref->{ $_ };
    }
    
    croak "Missing keys: @missing_keys" if @missing_keys;
    
    my $stimuli_validate = $data_hash_ref->{ stimuli_validate };
    my $predicted_index = $data_hash_ref->{ predicted_column_index };
    
    # actual processing starts here
    my $output_file = defined $data_hash_ref->{ results_write_to } 
                        ? $data_hash_ref->{ results_write_to }
                        : $stimuli_validate;
    
    # open for writing results
    my $aoa = csv (in => $stimuli_validate, encoding => ":encoding(utf-8)");
    #die ref $aoa;
    my $attrib_array_ref = shift @$aoa; # 'remove' the header, it's annoying :)

    $aoa = _fill_predicted_values( $self, $stimuli_validate, $predicted_index, $aoa );

    # put back the array of headers before saving file
    unshift @$aoa, $attrib_array_ref;

    print "Saving data to $output_file\n";
    csv( in => $aoa, out => $output_file, encoding => ":encoding(utf-8)" );
    print "Done saving!\n";

}

=head2 &_fill_predicted_values ( $self, $stimuli_validate, $predicted_index, $aoa )

This is where the filling in of the predicted values takes place. Take note that the parameters naming are the same as the ones used in the C<validate> and C<test> method.

This subroutine should be called in the procedural way.

=cut

sub _fill_predicted_values {
    my ( $self, $stimuli_validate, $predicted_index, $aoa ) = @_;

    # CSV processing is all according to the documentation of Text::CSV
    open my $data_fh, "<:encoding(UTF-8)", $stimuli_validate 
        or die "Can't open $stimuli_validate: $!";
    
    my $csv = Text::CSV->new( {auto_diag => 1, binary => 1} );
    
    my $attrib = $csv->getline($data_fh);
    #use Data::Dumper;    #print Dumper($attrib);    #print $attrib;    #no Data::Dumper;
    $csv->column_names( $attrib );

    # individual row
    my $row = 0;
    while ( my $data = $csv->getline_hr($data_fh) ) {
        
        if ( _calculate_output( $self, $data )  >= $self->threshold ) {
            # write 1 into aoa
            $aoa->[ $row ][ $predicted_index ] = 1;
        } else {
            #write 0 into aoa
            $aoa->[ $row ][ $predicted_index ] = 0;
        }
        
        $row++;
    }
    
    close $data_fh;
    
    $aoa;
}

=head1 RESULTS RELATED SUBROUTINES/METHODS

This part is related to generating the confusion matrix.

=head2 get_exam_results ( ... )

The parameters and usage are the same as C<get_confusion_matrix>. See the next method.

=head2 get_confusion_matrix ( \%options )

Returns the confusion matrix in the form of a hash. The hash will contain these keys: C<true_positive>, C<true_negative>, C<false_positive>, C<false_negative>, C<accuracy>, C<sensitivity>.

Take note that the C<accuracy> and C<sensitivity> are in percentage (%) in decimal (if any).

For C<%options>, the followings are needed unless mentioned:

=over 4

=item full_data_file => $filled_test_file

This is the CSV file filled with the predicted values. 

Make sure that you don't do anything to the actual and predicted output in this file after testing the nerve. These two columns must contain binary values only!

=item actual_output_header => $actual_column_name

=item predicted_output_header => $predicted_column_name

=back

The binary values are treated as follows:

=over 4

=item C<0> is negative

=item C<1> is positive

=back

=cut

sub get_exam_results {
    my ( $self, $info ) = @_;
    
    $self->get_confusion_matrix( $info );
}

sub get_confusion_matrix {
    my ( $self, $info ) = @_;

    my %c_matrix = _collect_stats( $info ); # processes total_entries, accuracy, sensitivity etc
    
    %c_matrix;
}


=head2 &_collect_stats ( \%options )

Generates a hash of confusion matrix based on C<%options> given in the C<get_confusion_matrix> method.

=cut

sub _collect_stats {
    my $info = shift;
    my $file = $info->{ full_data_file };
    my $actual_header = $info->{ actual_output_header };
    my $predicted_header = $info->{ predicted_output_header };
    
    my %c_matrix = ( 
        true_positive => 0, true_negative => 0, false_positive => 0, false_negative => 0,
        accuracy => 0, sensitivity => 0
    );
    
    # CSV processing is all according to the documentation of Text::CSV
    open my $data_fh, "<:encoding(UTF-8)", $file
        or die "Can't open $file: $!";
    
    my $csv = Text::CSV->new( {auto_diag => 1, binary => 1} );
    
    my $attrib = $csv->getline($data_fh); # get the row of headers, can't specify any column
    # shouldn't be a problem, since we're reading line by line :)

    $csv->column_names( $attrib );

    # individual row
    #use Data::Dumper;
    
    while ( my $row = $csv->getline_hr($data_fh) ) {
        #print Dumper( $row ), "\n";
        #print "Actual: ", $row->{$actual_header}, " Predicted: ", $row->{$predicted_header}, "\n";
        
        if ( $row->{ $actual_header } == 1 and $row->{ $predicted_header } == 1 ) {

            # true positive
            $c_matrix{ true_positive }++;
            
        } elsif ( $row->{ $actual_header } == 0 and $row->{ $predicted_header } == 0 ) {
            
            # true negative
            $c_matrix{ true_negative }++;
            
        } elsif ( $row->{ $actual_header } == 1 and $row->{ $predicted_header } == 0 ) {
            
            # false negative
            $c_matrix{ false_negative }++;
            
        } elsif ( $row->{ $actual_header } == 0 and $row->{ $predicted_header } == 1 ) {
            
            # false positive
            $c_matrix{ false_positive }++;
            
        } else {
        
            croak "Something's wrong!\n".
            "Make sure that the actual and predicted values in your file are binary ie 0 or 1" ;
            
        }
    }
    
    close $data_fh;
    # no Data::Dumper;

    _calculate_total_entries( \%c_matrix );

    _calculate_sensitivity( \%c_matrix );
    
    _calculate_accuracy( \%c_matrix );
    
    %c_matrix;
}

=head2 &_calculate_total_entries ( $c_matrix_ref )

Calculates and adds the data for the C<total_entries> key in the confusion matrix hash.

=cut

sub _calculate_total_entries {

    my $c_matrix = shift;
    my $total = $c_matrix->{ true_negative } + $c_matrix->{ false_positive };
       $total += $c_matrix->{ false_negative } + $c_matrix->{ true_positive };

    $c_matrix->{ total_entries } = $total;

}

=head2 &_calculate_accuracy ( $c_matrix_ref )

Calculates and adds the data for the C<accuracy> key in the confusion matrix hash.

=cut

sub _calculate_accuracy {

    my $c_matrix = shift;
    
    my $numerator = $c_matrix->{ true_positive } + $c_matrix->{ true_negative };
    my $denominator = $numerator + $c_matrix->{ false_positive } + $c_matrix->{ false_negative };
    
    $c_matrix->{ accuracy } = $numerator / $denominator * 100;
    
    # no need to return anything, we're using ref
}

=head2 &_calculate_sensitivity ( $c_matrix_ref )

Calculates and adds the data for the C<sensitivity> key in the confusion matrix hash.

=cut

sub _calculate_sensitivity {
    my $c_matrix = shift;
    
    my $numerator = $c_matrix->{ true_positive };
    my $denominator = $numerator + $c_matrix->{ false_negative };
    
    $c_matrix->{ sensitivity } = $numerator / $denominator * 100;

    # no need to return anything, we're using ref
}

=head2 display_exam_results ( ... )

The parameters are the same as C<display_confusion_matrix>. See the next method.

=head2 display_confusion_matrix ( \%confusion_matrix, \%labels ) 

Display the confusion matrix.

C<%confusion_matrix> is the same confusion matrix returned by the C<get_confusion_matrix> method.

Surely C<0>'s and C<1>'s don't make much sense for the output. Therefore, for C<%labels>, the following keys must be specified:

=over 4

=item zero_as => $category_zero_name

=item one_as => $category_one_name

=back

Please take note that non-ascii characters ie. non-English alphabets will cause the output to go off :)

For the C<%labels>, there is no need to enter "actual X", "predicted X" etc. It will be indicated with C<A: > for actual and C<P: > for the predicted values.

=cut

sub display_exam_results {
    my $self = shift;
    my ( $c_matrix, $labels ) = @_;
    
    $self->display_confusion_matrix( $c_matrix, $labels );
}

sub display_confusion_matrix {
    my ( $self, $c_matrix, $labels ) = @_;
    
    my @missing_keys;
    for ( qw( zero_as one_as ) ) {
        push @missing_keys, $_ unless exists $labels->{ $_ };
    }
    
    croak "Missing keys: @missing_keys" if @missing_keys;
    
    my $predicted_columns = [ "P: ".$labels->{ zero_as }, "P: ".$labels->{ one_as } ];
    my $actual_rows = [ "A: ".$labels->{ zero_as }, "A: ".$labels->{ one_as }];
    
    my $data = [ 
        [ $c_matrix->{ true_negative },  $c_matrix->{ false_positive } ],
        [ $c_matrix->{ false_negative }, $c_matrix->{ true_positive } ]
     ];
    my $matrix = Text::Matrix->new(
        rows => $actual_rows,
        columns => $predicted_columns,
        data => $data,
    );
    print "~~" x24, "\n";
    print "CONFUSION MATRIX (A:actual  P:predicted)\n";
    print "~~" x24, "\n";
    print $matrix->matrix();
    print "~~" x24, "\n";
    print "Total of ", $c_matrix->{ total_entries } , " entries\n";
    print "  Accuracy: $c_matrix->{ accuracy } %\n";
    print "  Sensitivity: $c_matrix->{ sensitivity } %\n";
    print "~~" x24, "\n";
}

=head1 NERVE DATA RELATED SUBROUTINES

This part is about saving the state of the nerve.

B<The subroutines are to be called in the procedural way>. No checking is done currently.

The subroutines here are not exported in any way whatsoever.

=head2 preserve ( ... )

The parameters and usage are the same as C<save_perceptron>. See the next subroutine.

=head2 save_perceptron ( $nerve_file )

Saves the C<My::Perceptron> object into a C<Storable> file. There shouldn't be a need to call this method manually since after every 
training process this will be called automatically.

=cut

sub preserve {
    save_perceptron( @_ );
}

sub save_perceptron {
    my $self = shift;
    my $nerve_file = shift;
    use Storable;
    store $self, $nerve_file;
    no Storable;
}

=head2 revive (...)

The parameters and usage are the same as C<load_perceptron>. See the next subroutine.

=head2 load_perceptron ( $nerve_file_to_load )

Loads the data and turns it into a C<My::Perceptron> object as the return value.

=cut

sub revive {
    load_perceptron( @_ );
}

sub load_perceptron {
    my $nerve_file_to_load = shift;
    use Storable;
    my $loaded_nerve = retrieve( $nerve_file_to_load );
    no Storable;
    
    $loaded_nerve;
}

=head1 AUTHOR

Raphael Jong Jun Jie, C<< <ellednera at cpan.org> >>

=head1 BUGS

Please email me if you happen to find any bugs. 

=head1 ACKNOWLEDGEMENTS

Besiyata d'shmaya, Wikipedia

=head1 SEE ALSO

AI::Perceptron, Text::Matrix

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Raphael Jong Jun Jie.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of My::Perceptron
