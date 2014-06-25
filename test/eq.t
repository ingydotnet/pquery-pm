use File::Basename;
use lib dirname(__FILE__), 'inc';

use TestpQuery tests => 2;

use pQuery;

my $testdir = -d 'test' ? 'test' : 't';

$pQuery::document = "$testdir/document2.html";
# $pQuery::document = 'index.html';

my $pquery;

# $pquery = pQuery('table:eq(1) tr');
$pquery = pQuery->find("table:eq(1) tr");

is $pquery->length, 89, ':eq works';

$pQuery::document = "$testdir/document3.html";

$pquery = pQuery("$testdir/document3.html")->find('table:eq(1) tr');

is $pquery->length, 2, '* works';
