#!perl

use 5.010;
use strict;
use warnings;

use Sort::BySpec qw(sort_by_spec cmp_by_spec);
use Test::More 0.98;

# test without array (returning sorter)
# test cmp (return sub to use with sort())

# test spec: wrong element -> dies
# test spec: scalars
# test spec: regex
# test spec: coderef
# test spec: coderef + regex (qr//) + scalars (test ordering)
# test spec: scalars + regex (without sort sub) + coderef (without sort sub)
# test spec: scalars + regex (with sort sub) + coderef (with sort sub)

# test opt: xform

# test opt: ci

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
