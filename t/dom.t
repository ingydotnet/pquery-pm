use t::TestpQuery tests => 33;

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

$dom = pQuery::DOM->fromHTML(<<'...');
<div id="div1">
    <div id="div2">
        <span id="span1">Foo</span> 
        <span id="span2">Bar</span>
        <span id="span3">Baz</span>
    </div>
</div>
...
my $span = $dom->getElementById('span1');
is $span->innerHTML, "Foo", 'getElementById works';
is $span->nodeValue, undef, 'nodeValue is undefined for Element';
is $span->tagName, "SPAN", 'tagName works';

my @spans = $dom->getElementsByTagName('span');
is scalar(@spans), 3, "Found 3 spans";
is $spans[0]->innerHTML, "Foo", '1st value is correct';
is $spans[1]->innerHTML, "Bar", '2nd value is correct';

$span->setAttribute('Foo', 'Bar');
is $span->toHTML, '<span id="span1" foo="Bar">Foo</span>',
    'setAttribute works';

is (pQuery::DOM->fromHTML('<div>')->hasAttributes, 0, 'hasAttributes works');
is (pQuery::DOM->fromHTML('<div XXX="yyy">')->hasAttributes, 1, 'hasAttributes works');

$span->removeAttribute('Id');
is $span->toHTML, '<span foo="Bar">Foo</span>',
    'removeAttribute works';

is $span->parentNode->id, 'div2',
    'parentNode works';

my $div2 = $dom->getElementById('div2');
my @children = $div2->childNodes;
is scalar(@children), 7, 'div2 has 7 children';
is ref($children[0]), '', 'child 1 is text node';

is $div2->firstChild, "\n        ", "firstChild works";
is $div2->lastChild, "\n    ", "lastChild works";

$dom = pQuery::DOM->fromHTML('<div>xxx<!-- yyy -->zzz</div>');
my @elems = pQuery::DOM->fromHTML('<div>xxx<!-- yyy -->zzz</div>')->childNodes;
my $comment = $elems[1];
is $comment->nodeType, 8, 'Handle comment nodes';
is $comment->nodeValue, ' yyy ', 'Handle comment node value';
is $comment->hasAttributes, 0, "Comments don't have attributes";
is $comment->nodeName, '#comment', 'Comment has proper nodeName';
is $comment->tagName, '', 'Comment has no tagName';
is $comment->parentNode->tagName, 'DIV', 'Comment has parentNode';
is $dom->toHTML, '<div>xxx<!-- yyy -->zzz</div>', 'Comments work in toHTML';
is $comment->innerHTML, undef, 'Comments have no innerHTML';

$dom->innerHTML('I <b>Like</b> Pie');

is $dom->toHTML, '<div>I <b>Like</b> Pie</div>', 'Setting innerHTML works';

my $div = pQuery::DOM->createElement('div');
$div->id('new-div');
$div->className('classy');
$comment = pQuery::DOM->createComment('I am remarkable');
$div->appendChild('Foo');
$div->appendChild($comment);
is $div->toHTML, '<div id="new-div" class="classy">Foo<!--I am remarkable--></div>',
        'createElement, createComment and appendChild work';
