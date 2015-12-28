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
    description => <<'_',

This package provides an advanced form of `Sort::ByExample`. Unlike in
`Sort::ByExample` where you only provide a single array of example, you can
specify multiple examples as well as regex or matcher subroutine coupled with
sort rules.

XXX (about the spec)

_
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
# XXX opt: ci
sub sort_by_spec {
    my %args = @_;

    my $spec = $args{spec};

    my $cmp = sub {
        my @vals;
        if (@_ >= 2) {
            $vals[0] = $_[0];
            $vals[1] = $_[1];
        } else {
            my $caller = caller();
            $vals[0] = ${"caller\::a"};
            $vals[1] = ${"caller\::b"};
        }

        my @ranks = ();
        my @sortsubs;
        for my $i (0..1) {
            my $val = $vals[$i];
          GET_RANK:
            for my $which ('scalar', 'regexp', 'code') {
                my $j = -1;
                while ($j < $#{$spec}) {
                    $j++;
                    my $spec_elem = $spec->[$j];
                    my $ref = ref($spec_elem);
                    if (!$ref) {
                        if ($which eq 'scalar' && $val eq $spec_elem) {
                            $ranks[$i] = $j; last GET_RANK;
                        }
                    } elsif ($ref eq 'Regexp') {
                        if ($i == 0 && $j < $#{$spec} &&
                                ref($spec->[$j+1]) eq 'CODE') {
                            $sortsubs[$j] = $spec->[$j+1];
                        }
                        if ($which eq 'regexp' && $val =~ $spec_elem) {
                            $ranks[$i] = $j; last GET_RANK;
                        }
                        if ($sortsubs[$j]) {
                            $j++;
                        }
                    } elsif ($ref eq 'CODE') {
                        if ($i == 0 && $j < $#{$spec} &&
                                ref($spec->[$j+1]) eq 'CODE') {
                            $sortsubs[$j] = $spec->[$j+1];
                        }
                        if ($which eq 'code' && $spec_elem->($val)) {
                            $ranks[$i] = $j; last GET_RANK;
                        }
                        if ($sortsubs[$j]) {
                            $j++;
                        }
                    } else {
                        die "Invalid spec[$j]: not a scalar/Regexp/code";
                    }
                } # loop element of spec
                $ranks[$i] //= $j+1;
            } # which
        }

        #use DD; dd {vals=>\@vals, ranks=>\@ranks};

        return $ranks[0] <=> $ranks[1]
            if $ranks[0] != $ranks[1];
        my $sortsub = $sortsubs[ $ranks[0] ];
        return 0 unless $sortsub;
        return $sortsub->($vals[0], $vals[1]);
    };

    if ($args{_return_cmp}) {
        return $cmp;
    } elsif ($args{array}) {
        return [sort {$cmp->($a, $b)} @{ $args{array} }];
    } else {
        return sub {
            my $caller = caller();
            $a = ${"caller\::a"};
            $b = ${"caller\::b"};
            sort {$cmp->($a, $b)} @_;
        };
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


=head1 DESCRIPTION


=head1 SEE ALSO

L<Sort::ByExample>
