use Test::More tests => 7;

use pQuery;

my $p1 = pQuery;

is ref($p1), 'pQuery', 'Empty object created';
is scalar(@$p1), 0, 'Empty object is empty';

my $p2 = pQuery([5..10]);

is ref($p2), 'pQuery', 'Array object created';
is scalar(@$p2), 6, 'Object has six elements';
is $p2->[2], 7, 'Check value of a element';

my $p3 = pQuery('<ul><li>one</li><li>two</li></ul>');

is ref($p3), 'pQuery', 'HTML object created';
is scalar(@$p3), 1, 'Object has six elements';

