use Test::More tests => 7;
use strict;
use warnings;

use pQuery;


# Test html() method
# Test toHtml() method
# Test with non DOM objects
# Multiple 


is pQuery->html, undef, "html of empty object is undef";
is pQuery->toHtml, undef, "toHtml of empty object is undef";

is pQuery('<p>aaa <b>bbb</b> ccc</p>')->toHtml,
    '<p>aaa <b>bbb</b> ccc</p>',
    'toHtml of single tree works';

is pQuery('<p>aaa <b>bbb</b> ccc</p>')->html,
    'aaa <b>bbb</b> ccc',
    'html of single tree works';

open FILE, 't/document1.html' or die $!;
my $html = do {local $/; <FILE>};
close FILE;
chomp $html;

my $html2 = pQuery($html)->toHtml;

# XXX Work around HTML::TreeBuilder quirks
$html2 =~ s{(?<=</body>)\s*(?=\n)}{};
$html2 =~ s{(<html>|</head>)}{$1\n  }g;

is $html2, $html, 'toHtml output matches toHtml input';

my $html3 = '<p>Foo <b>bar</b> baz</p>';

is pQuery($html3)->toHtml, $html3, 'toHtml Snippet';

is pQuery($html3)->html, 'Foo <b>bar</b> baz', 'innerHTML works';

