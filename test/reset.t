use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 1) : (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;

#check for memory leaks

use pQuery;

no_leaks_ok{
    my $testdir = -d 'test' ? 'test' : 't';
    my $pq = pQuery("$testdir/document2.html");

    $pq->find('td')->each(sub {
	my $i = shift;
	my $elem = $_;
			  });
} 'memory leak with traversal';


