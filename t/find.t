use t::TestpQuery tests => 2;

use pQuery;

open FILE, 't/document1.html' or die $!;
my $html = do {local $/; <FILE>};
close FILE;
chomp $html;

my $pquery = pQuery($html)->find('li');

is scalar(@$pquery), 5, 'Found 5 LI elements';

$pquery = pQuery($html)->find('xxx');

is scalar(@$pquery), 0, 'Found 0 XXX elements';
