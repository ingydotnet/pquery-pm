use t::TestpQuery tests => 9;

use pQuery;

ok pQuery->pquery =~ /^0\.\d\d$/, 'pquery version method works';

my $pq = pQuery('Foo <b>Bar</b> Baz');

is $pq->size, $pq->length, 'size and length are the same';

is $pq->length, 3, 'size and length methods work';

is $pq->get(1)->innerHTML, 'Bar', 'Test fetching specific member';
is $pq->get(0), 'Foo ', 'Test fetching memeber 0';

is join("", map { ref($_) ? $_->innerHTML : $_} $pq->get),
    "Foo Bar Baz",
    'get() with no args returns list';

is $pq->index($pq->get(1)), 1, 'index() method works';
is $pq->index(" Baz"), 2, 'index() method works on text elems';
is $pq->index("Bozo"), -1, 'index() method works when no match';

