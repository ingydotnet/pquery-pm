use inc::Module::Install;

name            'pQuery';
all_from        'lib/pQuery.pm';

requires        'HTML::TreeBuilder' => 0;

use_test_base;

WriteAll;
