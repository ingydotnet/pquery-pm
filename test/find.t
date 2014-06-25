use File::Basename;
use lib dirname(__FILE__), 'inc';

use TestpQuery tests => 7;

use pQuery;

my $testdir = -d 'test' ? 'test' : 't';
my $pquery;

$pquery = pQuery("$testdir/document1.html")->find('li');

is scalar(@$pquery), 5, 'Found 5 LI elements';

$pquery = pQuery("$testdir/document1.html")->find('xxx');

is scalar(@$pquery), 0, 'Found 0 XXX elements';

$pquery = pQuery("$testdir/document1.html");

$pquery->find('#text')->each(sub {
    is $_->nodeName, 'P', 'find by id works';
});
$pquery->find('.para')->each(sub {
    is $_->nodeName, 'P', 'find by class works';
});

is $pquery->find('body p i')->text, 'example', 'multiple nested tags works';

is $pquery->find('li:eq(4)')->text, 'three', ':eq works';

is pQuery('<b>foo</b>')->find('b')->length, 0,
    "don't find top level node";
