use Test::More tests => 13;
use strict;

use pQuery;

my $pq;

is $pQuery::document, undef, '$pQuery::document is not defined by default';
$pq = pQuery;

is ref($pq), 'pQuery', 'Empty object created';
is scalar(@$pq), 0, 'Empty object is empty';

$pq = pQuery(pQuery::DOM->fromHTML('<div>'));
is ref($pq), 'pQuery', 'pQuery object created';
is scalar(@$pq), 1, 'Object has one element';

$pq = pQuery([pQuery::DOM->fromHTML('I <b>Like</b> <ul>Pie</ul>.')]);
is ref($pq), 'pQuery', 'pQuery object created';
is scalar(@$pq), 5, 'Object has 5 elements';

$pq = pQuery('<ul><li>one</li><li>two</li></ul>');

is ref($pq), 'pQuery', 'HTML object created';
is scalar(@$pq), 1, 'Object has six elements';

$pq = pQuery('<p>aaa</p>bbb<p>ccc</p>');

is scalar(@$pq), 3, 'Object has 3 elements';

$pq = pQuery([5..10]);

is ref($pq), 'pQuery', 'Array object created';
is scalar(@$pq), 6, 'Object has six elements';
is $pq->[2], 7, 'Check value of a element';

