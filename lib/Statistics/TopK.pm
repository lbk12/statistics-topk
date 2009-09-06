package Statistics::TopK;

use strict;
use warnings;

use Carp qw(croak);

our $VERSION = '0.01';
$VERSION = eval $VERSION;

use constant _K      => 0;
use constant _ELEMS   => 1;
use constant _COUNTS => 2;
use constant _SIZE   => 3;
use constant _INDEX  => 4;

sub new {
    my ($class, $k) = @_;

    croak 'expecting a positive integer'
        unless defined $k and $k =~ /^\d+$/ and $k > 0;

    my $self = [
        $k,  # _K
        {},  # _ELEMS
        [],  # _COUNTS
        0,   # _SIZE
        0,   # _INDEX
    ];

    # Pre-extend the internal data structures, just in case $k is large.
    keys %{$self->[_ELEMS]} = $k;
    $#{$self->[_COUNTS]}   = $k - 1;

    return bless $self, $class;
}

sub add {
    my ($self, $elem) = @_;

    # Increment the element's counter if it is currently being counted.
    if (exists $self->[_ELEMS]{$elem}) {
        return $self->[_COUNTS][ $self->[_ELEMS]{$elem} ] += 1;
    }

    # Add the element if it's not being counted and there are free slots.
    if ($self->[_SIZE] < $self->[_K]) {
        my $size = $self->[_SIZE] += 1;
        $self->[_ELEMS]{$elem} = $size;
        return $self->[_COUNTS][$size] = 1;
    }

    # Decrement one of the currently counted elements.
    my $count = $self->[_COUNTS][ $self->[_INDEX] ] -= 1;
    # Advance the counter.
    $self->[_INDEX] = $self->[_INDEX]++ % $self->[_K];

    # If the count of the decremented element reaches 0, replace it with the
    # current element.
    if (0 == $count) {
        delete $self->[_ELEMS]{$elem};

        $self->[_ELEMS]{$elem} = $self->[_INDEX];
        return $self->[_COUNTS][ $self->[_INDEX] ] = 1;
    }

    # This element is not currently being counted.
    return 0;
}

sub top {
    return keys %{$_[0]->[_ELEMS]};
}

sub counts {
    my ($self) = @_;

    return map {
        $_ => $self->[_COUNTS][ $self->[_ELEMS]{$_} ]
    } $self->topk;
}


1;

__END__

=head1 NAME

Statistics::TopK - Implementation of the top-k streaming algorithm

=head1 SYNOPSIS

    use Statistics::TopK;

    my $counter = Statistics::TopK->new(10);
    while (my $val = <STDIN>) {
        chomp $val;
        $counter->add($val);
    }
    my @top = $counter->top;
    my %counts = $counter->counts;

=head1 DESCRIPTION

The C<Statistics::TopK> module implements the top-k streaming algorithm.
...

=head1 METHODS

=head2 new

    $counter = Statistics::TopK->new($k)

Creates a new C<Statistics::TopK> object which is prepared to count the top
 C<$k> elements.

=head2 top

    @top = $counter->top();

Returns the list of the top-k counted elements so far.

=head2 counts

    %counts = $counter->counts();

Returns a hash of the top-k counted elements and their counts.

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Statistics-TopK>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::TopK

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/statistics-topk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-TopK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-TopK>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Statistics-TopK>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-TopK>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut