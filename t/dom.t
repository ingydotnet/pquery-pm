use Test::More tests => 8;

use pQuery::DOM;

my $dom = pQuery::DOM->fromHTML('<p id= "id1" class="class1">Hello world</p>');

is $dom->nodeType, '1', 'nodeType is 1';
is $dom->nodeName, 'P', 'nodeName is P';
is $dom->getAttribute('id'), 'id1', 'id attribute is correct';
is $dom->id, 'id1', 'id method is correct';
is $dom->getAttribute('class'), 'class1', 'id attribute is correct';
is $dom->className, 'class1', 'className method is correct';

$dom = pQuery::DOM->fromHTML('<p>I <b>Like</b> <ul>Pie</ul>!</p>');
is $dom->toHTML, '<p>I <b>Like</b> <ul>Pie</ul>!</p>',
    'innerHTML works';
is $dom->innerHTML, 'I <b>Like</b> <ul>Pie</ul>!',
    'innerHTML works';
