my $t; use lib ($t = -e 't' ? 't' : 'test'), 'inc';

use TestpQuery tests => 38;

use pQuery;

pQuery("$t/spreadily.html");

is pQuery('*')->size, 76, '* finds all';
is pQuery('h3')->text, 'The Intarweb is a Spreadsheet!',
    'select an element by tag name';
is pQuery('#tagline')->text, 'The Intarweb is a Spreadsheet!',
    'select an element by id';
is pQuery('h3#tagline')->text, 'The Intarweb is a Spreadsheet!',
    'select an element by tag name and id';
is pQuery('h3:eq(0)')->text, 'The Intarweb is a Spreadsheet!',
    'select an element by tag name and index';
is pQuery('body h3')->text, 'The Intarweb is a Spreadsheet!',
    'select an element by tag under tag';

is pQuery->find('.bookmarklet')->text, 'Spreadily Available!',
    'select by class';

is pQuery('td:nth(4)')->text, 'Favorite Number',
    'select nth';

is pQuery('td:gt(2):lt(2)')->text, 'Age Favorite Number',
    'select a range with gt/lt';

is pQuery('td:lt(4):even')->text, 'First Name Favorite Color',
    'select a with even';

is pQuery('td:lt(4):odd')->text, 'Last Name Age',
    'select a with odd';

is pQuery('td:first')->text, 'First Name',
    'select first';

is pQuery('td:last')->text, '62.83',
    'select last';

is pQuery('td:first-child')->text,
    'First Name Alyssa Bennie Chester Delilah Eldridge Fennel',
    'select :first-child';

is pQuery('td:last-child')->text,
    'Favorite Number 13 7 144 54 21 138 377 62.83',
    'select :last-child';

is pQuery('ul li:only-child')->text,
    'Subversion: http://svn.spreadily.com/repo/trunk/',
    'select :only-child';

is pQuery('tr:last:parent')->text, 'Average 43.83 62.83', 'select :parent';
is pQuery('br:empty')->size, 3, 'select :empty';

is pQuery('td:contains(Blue)')->size, 3,
    '3 tds contain Blue';

like pQuery('p:has(u)')->text, qr/^Then you can/,
    ':has()';

is pQuery('*:header')->size, 2,
    'Two Headers';

is pQuery(':header')->size, 2,
    'Two Headers';

is pQuery("table#table1")->size, 1,
    'combined tag#id selector';

is pQuery('[href]')->size, 4,
    'match attribute is defined';

is pQuery('[nowrap]')->size, 4,
    'match attribute is defined';

is pQuery('[href="http://en.wikipedia.org/wiki/Bookmarklet"]')->size, 1,
    'match attribute href equals exactly';

is pQuery('A[href!=http://svn.spreadily.com/repo/trunk/]')->size, 2,
    'match tag attribute href is not equal or not defined';

is pQuery("[href][href!='http://svn.spreadily.com/repo/trunk/']")->size, 3,
    'match attribute href is defined and not equal';

is pQuery('[href^="http"]')->size, 2,
    'match attribute href starts with http';

is pQuery('[href$="Bookmarklet"]')->size, 1,
    'match attribute href ends with Bookmarklet';

is pQuery('[class|="table"]')->[0]->tagName, 'TR',
    'match attribute equals or is fallowed by a dash';

is pQuery('[class~="foo"]')->size, 5,
    'match attribute contains given word';

is pQuery('[class~="bar"]')->size, 3,
    'match attribute contains given word';

is pQuery('[class~="baz"]')->size, 4,
    'match attribute contains given word';

is pQuery('[class*=" foo baz"]')->size, 1,
    'match attribute contains given substring';

is pQuery('TaBle#table1 > TR:eq(2) TD:first-child')->html, 'Bennie',
    'complex case insensitive selector';

is pQuery('body > P:eq(0) ~ table')->attr('id'), 'table1',
    'complex sibling selector';

is pQuery('body > P:eq(0) ~ table > TR > TD:first-child + TD')->html, 'Last Name',
    'complex adjacent selector';

