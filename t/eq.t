use t::TestpQuery tests => 2;

use pQuery;

$pQuery::document = 't/document2.html';
# $pQuery::document = 'index.html';

my $pquery;

# $pquery = pQuery('table:eq(1) tr');
$pquery = pQuery->find("table:eq(1) tr");

is $pquery->length, 89, ':eq works';

$pQuery::document = 't/document3.html';

$pquery = pQuery('t/document3.html')->find('table:eq(1) tr');

is $pquery->length, 2, '* works';
