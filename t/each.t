use t::TestpQuery tests => 1;

use pQuery;

my $output = '';
pQuery('t/document1.html')->find('li')->each(sub {
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
