use File::Basename;
use lib dirname(__FILE__), 'inc';

use TestpQuery tests => 1;

use pQuery;

my $testdir = -d 'test' ? 'test' : 't';
my $output = '';
pQuery("$testdir/document1.html")->find('li')->each(sub {
    my $i = shift;
    my $text = pQuery($_)->text();
    $output .= ($i + 1) . ') ' . $text . "\n";
});

is $output, <<'...', 'each() and text() work';
1) one
2) two apple orange
3) apple
4) orange
5) three
...
