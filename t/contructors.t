use Test::More tests => 5;

use pQuery;
use XXX;

my $p1 = pQuery;

is ref($p1), 'pQuery', 'Empty object created';
is scalar(@$p1), 0, 'Empty object is empty';

my $p2 = pQuery([5..10]);

is ref($p2), 'pQuery', 'Array object created';
is scalar(@$p2), 6, 'Object has six elements';
is $p2->[2], 7, 'Check value of a element';
