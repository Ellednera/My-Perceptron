package My::Perceptron;

use 5.006;
use strict;
use warnings;
use Carp "croak";

use utf8;
use Text::CSV qw(csv);
binmode STDOUT, ":utf8";

=head1 NAME

My::Perceptron

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

# default values
use constant LEARNING_RATE => 0.05;
use constant THRESHOLD => 0.5;
use constant TUNE_UP => 1;
use constant TUNE_DOWN => 0;

=head1 SYNOPSIS

    #!/usr/bin/perl

    use AI::Perceptron::Simple;

    # the codes are expected to look something like this
    $perceptron->new;

    # these three steps could be done in seperated scripts if necessary
    # &train and &validate could be put inside a loop or something
    $perceptron->train( $file_train );
    $perceptron->validate( $file_validate );
    $perceptron->test( $file_test );

    # show results ie confusion matrix
    # (TP-true positive, TN-true negative, FP-false positive, FN-false negative)
    # this should only be done during validation and testing
    $perceptron->generate_confusion_matrix;

    # save data of the trained perceptron
    $perceptron->save_data( $data_file );

    # load data of percpetron for use in actual program
    $perceptron->load_data( $data_file );

=head1 DESCRIPTION

This module provides methods to build, train, validate and test a perceptron. It can also save the data of the perceptron for future use of for any actual AI programs.

This module is also aimed to help newbies to be able to grasp hold of the concept of perceptron, training, validation and testing concept as much as possible. Hence, all the methods and subroutines in this module are decoupled as much as possible so that the actual scripts can be written as simple complete programs.

The implementation here is super basic as it only takes in input of the dendrites and calculate the output. If the output is 
higher than the threshold, the final result (category) will be 1 aka perceptron is activated. If not, then the 
result will be 0 (not activated).

Depending on how you view or categorize the final result, the perceptron will fine tune itself (aka train) based on 
the learning rate until the desired result is met. Everything from here on is all mathematics and numbers. 
The data will only makes sense to the computer and not humans anymore.

Whenever the perceptron fine tunes itself, it will increase/decrease all the dendrites that is significant (attributes  
labelled 1) for each input. This means that even when the perceptron successfully fine tunes itself to suite all 
the data in your file for the first round, the perceptron might still get some of the things wrong for the next 
round of training. Therefore, the perceptron should be trained for as many rounds as possible. The more "confusion" 
the perceptron is able to correctly handle, the more "mature" the perceptron is. No one defines how "mature" it is 
except the programmer himself/herself :)

=head1 EXPORT

None. Almost everything is OO

=head1 SUBROUTINES/METHODS

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

# CREATION OF PERCEPTRON

sub new {
    my $class = shift;
    
    my $data_ref = shift;
    my %data = %{ $data_ref };
    
    # check keys
    $data{ learning_rate } = LEARNING_RATE if not exists $data{ learning_rate };
    $data{ threshold } = THRESHOLD if not exists $data{ threshold };
    
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

=head2 learning_rate( $value )

=head2 learning_rate

If C<$value> is given, sets the learning rate to C<$value>. If not, then it returns the learning rate.

The C<$value> should be between 0 and 1. Default is C<0.05>

=cut

sub learning_rate {
    my $self = shift;
    if ( @_ ) {
        $self->{learning_rate} = shift;
    } else {
        $self->{learning_rate}
    }
}

=head2 threshold( $value )

=head2 threshold

If C<$value> is given, sets the threshold/passing rate to C<$value>. If not, then it returns the passing rate.

The C<$value> should be between 0 and 1. Default is C<0.5> ie 50%

=cut

sub threshold {
    my $self = shift;
    if ( @_ ) {
        $self->{ threshold } = shift;
    } else {
        $self->{ threshold };
    }
}

# TRAINING STAGE

=head2 train( $stimuli_train_csv, $expected_output_header, $save_nerve_to_file [, $display_stats, $identifier ] )

Trains the perceptron. 

C<$stimuli_train_csv> is the set of data/input (in CSV format) to train the perceptron while C<$save_nerve_to_file> is 
the filename that will be generate each time the perceptron finishes the training process. This data file is the data of the C<My::Perceptron> 
object and it is used in the C<validate> method.

C<$expected_output_header> is the header name of the columns in the csv file with the actual category or the exepcted values. This is used to determine to tune the nerve up or down. This value should only be 0 or 1 for the sake of simplicity.

C<$display_stats> is B<optional> and the default is 0. It will display more output about the tuning process. It will show the followings:

=over 4

=item old sum

The original sum of all C<weightage * input>

=item new output as well as it was tuned up or down

The new sum of all C<weightage * input> after fine-tuning the nerve

=back

If C<$display_stats> is set to C<1>, the you must specify the C<$identifier>. This is the column/header name that is used to identify a specific row of data in C<$stimuli_train_csv>.

This method eturns C<$save_nerve_to_file> upon completion. This is useful if you are perfrorming the training and validation process in one go. So 
you can write the following if you want to:

    $perceptron->validate(  $stimuli_validate, 
                            $perceptron->train( $stimuli_train, $save_nerve_to_file ) 
                        );

=cut

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
        # print $row->{$expected_output_header} ? "意林\n" : "魅丽优品\n";

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
    
    save_perceptron( $self, $save_nerve_to_file );
    
    return $save_nerve_to_file;
}

=head2 _calculate_output( $self, \%stimuli_hash )

Calculates and returns the sum(weightage*input) for each individual row of data.

C<%stimuli_hash> is the actual data to be used for training. It might contain useless columns.

This will get all the avaible dendrites through the C<get_attributes> method and then use all the keys ie. headers to access the corresponding values.

This subroutine shuold be called in the procedural way for now.

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

=head2 _tune( $self, \%stimuli_hash, $tune_up_or_down )

Fine tunes the nerve. This will directly alter the attributes values in C<$self> according to the attributes/dendrites specified in C<new>.

The C<%stimuli_hash> here is the same as the one in the C<_calculate_output> method.

C<%stimuli_hash> will be used to determine which dendrite in C<$self> needs to be fine-tuned. As long as the value of any key in C<%stimuli_hash> returns true (1) then that dendrite in C<$self> will be tuned.

Tuning up or down depends on C<$tune_up_or_down> specifed by the C<&_calculate_output> subroutine. The following constants can be used for C<$tune_up_or_down>:

=over 4

=item TUNE_UP

Value is C<1>

=item TUNE_DOWN

Value is C<0>

=back

This subroutine shuold be called in the procedural way for now.

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
    1; #last; # calling last here will give warnings
}


=head2 validate ( \%options )

B<This method is not ready yet!>

This method validates the perceptron against another set of data after it has undergone the training process.

This method calculates the output of each row of data and write the result into the predicted column. The data begin written into the new file or the original file will maintain it's sequence.

Please take note that this method will load all the data of the validation stimuli, so please split your stimuli into multiple files if possible and call this method a few more times.

For C<%options>, the followings are needed unless mentioned:

=over 4

=item stimuli_validate => $csv_file

This is the CSV file containing the validation data, make sure that it contains a column with the predicted values as it is needed in the next key mentioned: C<predicted_column_index>

=item predicted_column_index => $index

This is the index of the column that contains the predicted output values. C<$index> starts from C<0>.

This part will be filled and saved to C<results_write_to>.

=item results_write_to => $new_csv_file

Optional.

The default behaviour will write the predicted output into C<stimuli_validate> ie the original data while maintaining the original sequence.

=back

=cut

sub validate {

    my $self = shift;   my $data_hash_ref = shift;
    
    my $stimuli_validate = $data_hash_ref->{ stimuli_validate };
    my $actual_index = $data_hash_ref->{ actual_column_index };
    my $predicted_index = $data_hash_ref->{ predicted_column_index };
    
    my $output_file;
    if ( defined $data_hash_ref->{ results_write_to } ) {
        $output_file = $data_hash_ref->{ results_write_to };
    } else {
        $output_file = $stimuli_validate;
    }
    
    # open for writing results
    my $aoa = csv (in => $stimuli_validate, encoding => ":encoding(utf-8)");

    my $attrib_array_ref = shift @$aoa;


    # open for calculation of results
    # completed up till here    
    ###################################################
    # CSV processing is all according to the documentation of Text::CSV
    open my $data_fh, "<:encoding(UTF-8)", $stimuli_validate 
        or die "Can't open $stimuli_validate: $!";
    
    my $csv = Text::CSV->new( {auto_diag => 1, binary => 1} );
    
    my $attrib = $csv->getline($data_fh);
    #use Data::Dumper;    #print Dumper($attrib);    #print $attrib;    #no Data::Dumper;
    $csv->column_names( $attrib );

    # individual row
    my $row = 0;
    while ( my $row = $csv->getline_hr($data_fh) ) {
        
        if ( _calculate_output( $self, $row )  >= $self->threshold ) {
            # write 1 into aoa
            $aoa->[ $row ][ $predicted_index ] = 1;
        } else {
            #write 0 into aoa
            $aoa->[ $row ][ $predicted_index ] = 0;
        }
        
        $row++;
    }
    
    close $data_fh;
    ###################################################

    unshift @$aoa, $attrib_array_ref;
    print Dumper( $aoa ), "\n";

    print "Press enter to save to file\n"; # debug
    <>;
    csv( in => $aoa, out => $output_file, encoding => ":encoding(utf-8)" );
    print "Done!\n";

}

=head2 &save_perceptron( $nerve_file )

Saves the C<My::Perceptron> object into a C<Storable> file. There shouldn't be a need to call this method manually since after every 
training process this will be called automatically.

This subroutine is not exported in any way whatsoever.

This subroutine is to be called in the procedural way. No checking is done currently.

=cut

sub save_perceptron {
    my $self = shift;
    my $nerve_file = shift;
    use Storable;
    store $self, $nerve_file;
    no Storable;
}

=head2 &load_perceptron( $nerve_file_to_load )

Loads the data and turns it into a C<My::Perceptron> object as the return value.

This subroutine is not exported in any way whatsoever.

This subroutine is to be called in the procedural way. No checking is done currently.

=cut

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

Please report any bugs or feature requests to C<bug-my-perceptron at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=My-Perceptron>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc My::Perceptron


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=My-Perceptron>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/My-Perceptron>

=item * Search CPAN

L<https://metacpan.org/release/My-Perceptron>

=back


=head1 ACKNOWLEDGEMENTS

Besiyata d'shmaya

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Raphael Jong Jun Jie.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of My::Perceptron
