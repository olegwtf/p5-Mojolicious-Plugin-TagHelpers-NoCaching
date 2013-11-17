use strict;
use Test::More;
use Test::Mojo;

require 't/lite-02.pl';

my $t = Test::Mojo->new();
$t->get_ok('/');
my $dom = $t->tx->res->dom;
like($dom->html->head->link->attr('href'), qr!p1/style\.css\?v=\d+!, "stylesheet url with key");
like($dom->html->head->script->attr('src'), qr!/app\.js\?v=\d+!, "js url with key");
like($dom->html->body->img->attr('src'), qr!/t\.gif\?v=\d+!, "image url with key");
$t->text_like('body > script', qr!var\s+a!, "inline script");

done_testing;
