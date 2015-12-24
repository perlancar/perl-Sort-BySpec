package Sort::ByExample::Clusters;

# DATE
# VERSION

use 5.010;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(sbe_clusters cbe_clusters);

# XXX opt: xform like in Sort::ByExample
# XXX opt: fallback
# XXX opt:

sub sbe_clusters {
    my %args = @_;

    my $example = $args{example};

    my $cmp =  sub {
        # "a" is in $_[0], "b" is in $_[1]

        my @cluster_no;
        my @order;
        for my $i (0..1) {

            my $cluster_no;

        # look for example arrays
        my $i = ;
        while () {
        }
    };

    my $sorter = sub {
        sort { $cmp->() } @_;
    };
}

1;
# ABSTRACT: Sort lists to look like the example you provide

=head1 SYNOPSIS


=head1 SEE ALSO

L<Sort::ByExample>
