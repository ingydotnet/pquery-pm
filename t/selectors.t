use t::TestpQuery tests => 12;

use pQuery;

pQuery('t/spreadily.html');

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

is pQuery('td:gt(2):lt(2)')->text, 'AgeFavorite Number',
    'select a range with gt/lt';

is pQuery('td:lt(4):even')->text, 'First NameFavorite Color',
    'select a with even';

is pQuery('td:lt(4):odd')->text, 'Last NameAge',
    'select a with odd';

is pQuery('td:first')->text, 'First Name',
    'select first';

is pQuery('td:last')->text, '62.83',
    'select last';

is pQuery('td:contains(Blue)')->size, 3,
    '3 tds contain Blue';

# is pQuery(':header')->size, 2,
#     'Two Headers';
