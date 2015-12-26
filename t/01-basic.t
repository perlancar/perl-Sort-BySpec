#!perl

use 5.010;
use strict;
use warnings;

use Sort::BySpec qw(sort_by_spec cmp_by_spec);
use Test::More 0.98;

{
    my $sorter = sort_by_spec(
        spec => [
            qr/\d+/           => sub { $_[1] <=> $_[0] },
            "foo", "bar", "baz",
            qr/.+/            => sub { $_[1] cmp $_[0] },
        ],
    );

    is_deeply([$sorter->(qw/bar baz foo
                            1 2 3
                            qux quux
                           /)],
              qw/3 2 1
                 foo bar baz
                 quux qux/);
}

done_testing;
