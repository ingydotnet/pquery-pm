use lib (-e 't' ? 't' : 'test'), 'inc';

use TestpQuery tests => 2;

use pQuery;

is ref(pQuery->end), 'pQuery', 'end works when no stack exists';

my $pq = pQuery('Foo <b>Bar</b> Baz');

is $pq->find('b')->each(sub { pass "One time" })->end->length, 3, 'end works';
