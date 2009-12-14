use strict;
use warnings;
use Test::More;
use Regexp::Common qw(Email::Address);
use Email::Address;

return plan skip_all => 'Set TEST_USER and TEST_PASSWORD to access a mailbox for these tests' unless $ENV{TEST_USER} and $ENV{TEST_PASSWORD};

eval "use Test::WWW::Mechanize::Catalyst 'CiderWebmail'";
if ($@) {
    plan skip_all => 'Test::WWW::Mechanize::Catalyst required';
    exit;
}

plan tests => 12;

ok( my $mech = Test::WWW::Mechanize::Catalyst->new, 'Created mech object' );

$mech->get_ok( 'http://localhost/' );

$mech->submit_form(with_fields => { username => $ENV{TEST_USER}, password => $ENV{TEST_PASSWORD} }); #FIXME should be a test, too, but we don't know the test plan yet...

# Find all message links:
# <a href="http://localhost/mailbox/INBOX/27668" onclick="return false" id="link_27668">

my @links = $mech->find_all_links(id_regex => qr{\Alink_\d+\z});

my $link = $links[0];

$mech->get_ok($link->url);
$mech->follow_link_ok({ url_regex => qr{/reply/sender/?\z} }, "replying");

# check if address fields are filled like:
# <input value="johann.aglas@atikon.com" name="to">
# <input value="ss@atikon.com" name="from">

check_email($mech, 'to');
check_email($mech, 'from', 1);

$mech->back;

$mech->follow_link_ok({ url_regex => qr{/forward/?\z} }, "forwarding");

check_email($mech, 'from', 1);

$mech->back;

$mech->follow_link_ok({ url_regex => qr{/reply/all/?\z} }, "reply to all");

check_email($mech, 'to');
check_email($mech, 'from', 1);

$mech->back;

$mech->follow_link_ok({ url_regex => qr{/view_source} }, 'view source');

sub check_email {
    my ($mech, $field, $empty) = @_;

    my $value = $mech->value(lc $field);
    $empty = $empty ? '^$|' :  '';
    like($value, qr($empty$RE{Email}{Address}), $mech->uri . ": '$field' field contains an email address");
}