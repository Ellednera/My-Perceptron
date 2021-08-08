package My::Perceptron;

use 5.006;
use strict;
use warnings;
use Carp "croak";

use utf8;
use Text::CSV;
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

This module provides methods to build, train, validate and test a perceptron. It can also save the data of the 
perceptron for future use of for any actual AI programs.

See wikipedia for more info about perceptron.

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

The value should be between 0 and 1.

=item attribs => $array_ref

An array reference containing all the attributes the perceptron should have.

=item learning_rate => $decimal

Optional. The default is C<0.05>.

The learning rate or the "rest duration" of the perceptron for the fine-tuning process (between 0 and 1). 

Generally speaking, the smaller the value the better.

=item threshold => $decimal

Optional. The default is C<0.5>

This is the passing rate to determine the neuron output (0 or 1)

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

=head2 train( $stimuli_train_csv, $save_nerve_to_file )

Trains the perceptron. C<$stimuli_train> is the set of data/input (in CSV format) to train the perceptron while C<$save_nerve_to_file> is 
the filename that will be generate each time the perceptron finishes the training process. This data file is the data of the C<My::Perceptron> 
object and it is used in the C<validate> method.

Returns C<$save_nerve_to_file> upon completion. This is useful if you are perfrorming the training and validation process in one go. So 
you can write the following if you want to:

    $perceptron->validate(  $stimuli_validate, 
                            $perceptron->train( $stimuli_train, $save_nerve_to_file ) 
                        );

=cut

sub train {
    my $self = shift;
    my( $stimuli_train_csv, $save_nerve_to_file ) = @_;
    
    open my $data_fh, "<:encoding(UTF-8)", $stimuli_train_csv 
        or die "Can't open $stimuli_train_csv: $!";
    
    my $csv = Text::CSV->new( {auto_diag => 1, binary => 1} );
    
    # tested up till here, here onwards, manual checking
    # based on documentation of Text::CSV
    my $attrib = $csv->getline($data_fh);
    #use Data::Dumper;    #print Dumper($attrib);    #print $attrib;    #no Data::Dumper;
    $csv->column_names( $attrib );

    # individual row
    while ( my $row = $csv->getline_hr($data_fh) ) {
        print $row->{book_name}, " -> "; print $row->{brand} ? "意林\n" : "魅丽优品\n";
        # calculate the output
    }

    close $data_fh;
    
    #save_perceptron( $save_nerve_to_file );
    
    return $save_nerve_to_file;
}

=head2 _process_csv()

Returns an array of headers that has the value of 1

=head2 _read_from_csv()



=head2 _write_to_csv()



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
    my $loaded_perceptron = retrieve( $nerve_file_to_load );
    no Storable;
    
    $loaded_perceptron;
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
