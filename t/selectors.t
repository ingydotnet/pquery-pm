use t::TestpQuery tests => 23;

use pQuery;

pQuery('t/spreadily.html');

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

is pQuery("table#table1")->size, 1, 'id after other selector';
