use Test::More tests => 3;
use strict;
use warnings;

use pQuery;

is pQuery->html, undef, "HTML of empty object is undef";

open FILE, 't/document1.html' or die $!;
my $html = do {local $/; <FILE>};
close FILE;
chomp $html;

my $html2 = pQuery($html)->html;

# XXX Work around HTML::TreeBuilder quirks
$html2 =~ s{(?<=</body>)\s*(?=\n)}{};
$html2 =~ s{(<html>|</head>)}{$1\n  }g;

is $html2, $html, 'HTML output matches HTML input';

my $html3 = '<p>Foo <b>bar</b> baz</p>';

is pQuery($html3)->html, $html3, 'HTML Snippet';
