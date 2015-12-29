package Sort::BySpec;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(sort_by_spec cmp_by_spec);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Sort array (or create a list sorter) according to '.
        'specification',
};

$SPEC{sort_by_spec} = {
    v => 1.1,
    summary => 'Sort array (or create a list sorter) according to '.
        'specification',
    description => <<'_',


_
    args => {
        spec => {
            schema => 'array*',
            req => 1,
            pos => 0,
        },
        xform => {
            schema => 'code*',
            summary => 'Code to return sort keys from data elements',
            description => <<'_',

This is just like `xform` in `Sort::ByExample`.

_
        },
        array => {
            schema => 'array*',
        },
    },
    result => {
        summary => 'Sorted array, or sort coderef',
        description => <<'_',

If array is specified, will returned the sorted array. If array is not specified
in the argument, will return a sort subroutine that can be used to sort a list
and return the sorted list.

_
    },
    result_naked => 1,
    examples => [
        {
            summary => 'Sort according to a sequence of scalars (like Sort::ByExample)',
            args => {
                spec => ['foo', 'bar', 'baz'],
                array => [1, 2, 3, 'bar', 'a', 'b', 'c', 'baz'],
            },
        },
        {
            summary => 'Put integers first (in descending order), then '.
                'a sequence of scalars, then others (in ascending order)',
            args => {
                spec => [
                    qr/\A\d+\z/ => sub { $_[1] <=> $_[0] },
                    'foo', 'bar', 'baz',
                    qr// => sub { $_[0] cmp $_[1] },
                ],
                array => ["qux", "b", "a", "bar", "foo", 1, 10, 2],
            },
        },
    ],
};
sub sort_by_spec {
    my %args = @_;

    my $spec  = $args{spec};
    my $xform = $args{xform};

    my $code_get_rank = sub {
        my $val = shift;

        my $j;
        for my $which (0..2) { # 0=scalar, 1=regexp, 2=code
            $j = -1;
            while ($j < $#{$spec}) {
                $j++;
                my $spec_elem = $spec->[$j];
                my $ref = ref($spec_elem);
                if (!$ref) {
                    if ($which == 0 && $val eq $spec_elem) {
                        return($j);
                    }
                } elsif ($ref eq 'Regexp') {
                    my $sortsub;
                    if ($j < $#{$spec} && ref($spec->[$j+1]) eq 'CODE') {
                        $sortsub = $spec->[$j+1];
                    }
                    if ($which == 1 && $val =~ $spec_elem) {
                        return($j, $sortsub);
                    }
                    $j++ if $sortsub;
                } elsif ($ref eq 'CODE') {
                    my $sortsub;
                    if ($j < $#{$spec} && ref($spec->[$j+1]) eq 'CODE') {
                        $sortsub = $spec->[$j+1];
                    }
                    if ($which == 2 && $spec_elem->($val)) {
                        return($j, $sortsub);
                    }
                    $j++ if $sortsub;
                } else {
                    die "Invalid spec[$j]: not a scalar/Regexp/code";
                }
            } # loop element of spec
        } # which
        return($j+1);
    };

    if ($args{_return_cmp}) {
        my $cmp = sub {
            my ($a, $b);

            if (@_ >= 2) {
                $a = $_[0];
                $b = $_[1];
            } else {
                my $caller = caller();
                $a = ${"caller\::a"};
                $b = ${"caller\::b"};
            }

            if ($xform) {
                $a = $xform->($a);
                $b = $xform->($b);
            }

            my ($rank_a, $sortsub) = $code_get_rank->($a);
            my ($rank_b          ) = $code_get_rank->($b);

            if ($rank_a != $rank_b) {
                return $rank_a <=> $rank_b;
            }
            return 0 unless $sortsub;
            return $sortsub->($a, $b);
        };
        return $cmp;
    } else {
        # use schwartzian transform to speed sorting longer lists
        my $sorter = sub {
            return map { $_->[0] }
                sort {
                    $a->[2] <=> $b->[2] ||
                        ($a->[3] ? $a->[3]($a->[1], $b->[1]) : 0) }
                    map {
                        my $x = $xform ? $xform->($_) : $_;
                        [$_, $x, $code_get_rank->($x)]
                    } @_;
        };

        if ($args{array}) {
            return [$sorter->(@{ $args{array} })];
        }
        return $sorter;
    }
}

$SPEC{cmp_by_spec} = do {
    # poor man's "clone"
    my $meta = { %{ $SPEC{sort_by_spec} } };
    $meta->{summary} = 'Create a compare subroutine to be used in sort()';
    $meta->{args} = { %{$meta->{args}} };
    delete $meta->{args}{array};
    delete $meta->{result};
    delete $meta->{examples};
    $meta;
};
sub cmp_by_spec {
    sort_by_spec(
        @_,
        _return_cmp => 1,
    );
}

1;
# ABSTRACT:

=head1 SYNOPSIS

 use Sort::BySpec qw(sort_by_spec cmp_by_spec);

 my $sorter = sort_by_spec(spec => [
     # put odd numbers first, in ascending order
     qr/[13579]\z/ => sub { $_[0] <=> $_[1] },

     # then put specific numbers here, in this order
     4, 2, 42,

     # put even numbers last, in descending order
     sub { $_[0] % 2 == 0 } => sub { $_[1] <=> $_[0] },
 ]);

 my @res = $sorter->(1..15, 42);
 # => (1,3,5,7,9,11,13,15,  4,2,42,   14,12,10,8,6)


=head1 DESCRIPTION

This package provides a more powerful alternative to L<Sort::ByExample>. Unlike
in `Sort::ByExample` where you only provide a single array of example, you can
specify multiple examples as well as regex or matcher subroutine coupled with
sort rules. With this, you can more precisely specify how elements of your list
should be ordered. If your needs are not met by Sort::ByExample, you might want
to consider this package. The downside is performance penalty, especially when
your list is large.

To sort using Sort::BySpec, you provide a "spec" which is an array of strings,
regexes, or coderefs to match against elements of your list to be sorted. In the
simplest form, the spec contains only a list of examples:

 my $sorter = sort_by_spec(spec => ["foo", "bar", "baz"]); # [1]

and this is equivalent to Sort::ByExample:

 my $sorter = sbe(["foo", "bar", "baz"]);

You can also specify regex to match elements. This is evaluated after strings,
so this work:

 my $sorter = sort_by_spec(spec => [qr/o/, "foo", "bar", "baz", qr/a/]);
 my @list = ("foo", "food", "bar", "back", "baz", "fool", "boat");
 my @res = $sorter->(@list);
 # => ("food","boat","fool",   "foo","bar","baz",   "back")

Right after a regex, you can optionally specify a sort subroutine to tell how to
sort elements matching that regex, for example:

 my $sorter = sort_by_spec(spec => [
     qr/o/ => sub { $_[0] cmp $_[1] },
     "foo", "bar", "baz",
     qr/a/
 ]);

 # the same list @list above will now be sorted into:
 # => ("boat","food","fool",   "foo","bar","baz",   "back")

Note that instead of C<$a> and C<$b>, you should use C<$_[0]> and C<$_[1]>
respectively. This avoids the package scoping issue of C<$a> and C<$b>, making
your sorter subroutine works everywhere without any special workaround.

Finally, aside from strings and regexes, you can also specify a coderef matcher
for more complex matching:

 my $sorter = sort_by_spec(spec => [
     # put odd numbers first, in ascending order
     sub { $_[0] % 2 } => sub { $_[0] <=> $_[1] },

     # then put specific numbers here, in this order
     4, 2, 42,

     # put even numbers last, in descending order
     sub { $_[0] % 2 == 0 } => sub { $_[1] <=> $_[0] },
 ]);

 my @res = $sorter->(1..15, 42);
 # => (1,3,5,7,9,11,13,15,  4,2,42,   14,12,10,8,6)


=head1 SEE ALSO

L<Sort::ByExample>

L<Bencher::Scenario::SortBySpec>
