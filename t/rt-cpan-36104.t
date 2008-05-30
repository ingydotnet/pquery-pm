use lib 'lib';
use Test::More tests => 7;
use pQuery;

my $foo = do { local $/; <DATA> };

my $html = eval { pQuery($foo)->html };
like($html, qr/</, "Saw some HTML with DOCTYPE and XML signature...");
is($@, "", "...without dying");

$foo =~s/<\?xml.*\n//;

$html = eval { pQuery($foo)->html };
like($html, qr/</, "Saw some HTML just with a DOCTYPE...");
is($@, "", "...without dying");

$foo =~s/<!DOCTYPE.*\n//;

$html = eval { pQuery($foo)->html };
like($html, qr/</, "Saw some HTML...");
is($@, "", "...without dying");

my $p = pQuery($foo);

$p->find("link[rel=stylesheet]")->each(sub {
    ok(1, "Got a stylesheet");
});

__DATA__
<?xml version="1.0"?>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "">
<html>
<head>
<link rel="stylesheet" href="test.css" type="text/css"/>
</head>
<body> <p> Hello World </p> </body>
</html>
