use strict;
use Test::More;
use Test::Mojo;

require 't/lite-01.pl';

my $t = Test::Mojo->new();
$t->get_ok('/');
my $dom = $t->tx->res->dom;
like($dom->html->head->link->attr('href'), qr!app\.css\?nc=\d+!, "relative stylesheet url");
like($dom->html->body->img->attr('src'), qr!/t\.gif\?nc=\d+!, "absolute image url");
is($dom->html->head->script->attr('src'), '/foo.js', "non-existent js");

$t->get_ok('/p1');
$dom = $t->tx->res->dom;
like(my $src = $dom->html->head->script->attr('src'), qr!/app.js\?v=12&nc=\d+!, "url with query param");
is($dom->html->head->link->attr('href'), 'mem.css', "url to inline css");
my $time = time() + 1000;

utime $time, $time, 't/public/app.js';
$t->get_ok('/p1');
$dom = $t->tx->res->dom;
is($dom->html->head->script->attr('src'), $src, "mtime cached");

$t->get_ok('/p1/p2');
$dom = $t->tx->res->dom;
like($dom->html->head->link->attr('href'), qr!\./style\.css\?nc=\d+!, "relative url from sub path");

done_testing;
