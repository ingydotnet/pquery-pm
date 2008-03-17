use t::TestpQuery tests => 6;

use pQuery;

my $pquery;

$pquery = pQuery('t/document1.html')->find('li');

is scalar(@$pquery), 5, 'Found 5 LI elements';

$pquery = pQuery('t/document1.html')->find('xxx');

is scalar(@$pquery), 0, 'Found 0 XXX elements';

$pquery = pQuery('t/document1.html');

$pquery->find('#text')->each(sub {
    is $_->nodeName, 'P', 'find by id works';
});
$pquery->find('.para')->each(sub {
    is $_->nodeName, 'P', 'find by class works';
});

is $pquery->find('body p i')->text, 'example', 'multiple nested tags works';

is $pquery->find('li:eq(4)')->text, 'three', ':eq works';
