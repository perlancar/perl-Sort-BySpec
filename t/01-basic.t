#!perl

use 5.010;
use strict;
use warnings;


use Sort::ByExample::Clusters qw(sbe_clusters);
use Test::More 0.98;

{
    my $sorter = sbe_clusters(
        {},
        qr/\d+/           => sub { $_[1] <=> $_[0] },
        [qw/foo bar baz/],
        qr/.+/            => sub { $_[1] cmp $_[0] },
    );
    is_deeply([$sorter->(qw/bar baz foo
                            1 2 3
                            2B 2H 1H 3B
                            qux quux
                           /)],
              qw/3 2 1
                 foo bar baz
                 2H 1H 2B 3B
                 quux qux/);
}

done_testing;
