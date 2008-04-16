use t::TestpQuery tests => 25;
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

is $pQuery::document, undef, 'Global document not set yet';
is $pQuery, undef, '$pQuery not set yet';
$pQuery = 't/document3.html';
is $pQuery::document, 't/document3.html', 'Global document is now set';
is $pQuery, 't/document3.html', '$pQuery is now set';
$pq = pQuery;
is ref($pQuery::document), 'pQuery::DOM', 'Global document is a DOM';
is ref($pQuery), 'pQuery::DOM', '$pQuery is a DOM';
is $pq->find('title')->text, 'Sample HTML Document 3', 'Document is correct';

$pQuery::document = 't/document1.html';
is $pQuery::document, 't/document1.html', 'Global document is now set';
is $main::pQuery, 't/document1.html', '$main::pQuery is now set';
$pq = pQuery;
is ref($pQuery::document), 'pQuery::DOM', 'Global document is a DOM';
is ref($pQuery), 'pQuery::DOM', '$pQuery is a DOM';
is $pq->find('title')->text, 'Sample HTML Document', 'Document is correct';


