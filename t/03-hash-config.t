#!/usr/bin/perl
use strict;
use warnings;
use Env qw( CYBS_ID CYBS_KEY_DIR );
use Test::More;

#testing/testing is valid and seems to work...

BEGIN {
    eval 'use CyberSource::SOAPI';
    plan skip_all => 'Skipping without CyberSource::SOAPI' if $@;
}

plan skip_all => 'You MUST set ENV variable CYBS_ID and CYBS_KEY_DIR to test this!'
		unless $CYBS_ID && $CYBS_KEY_DIR;

plan skip_all => 'CYBS_KEY_DIR: "' . $CYBS_KEY_DIR . '" does not exist'
	unless -d $CYBS_KEY_DIR;

$Business::OnlinePayment::CyberSource::BACKEND = 'SOAPI';
use Business::OnlinePayment;

my $tx
	= Business::OnlinePayment->new(
		'CyberSource',
		config => {
			merchantID       => $CYBS_ID,
			keysDirectory    => $CYBS_KEY_DIR,
			targetAPIVersion => '1.60',
		},
	);

$tx->content(
	type           => 'VISA',
	action         => 'Normal Authorization',
	description    => 'Business::OnlinePayment visa test',
	amount         => '49.95',
	invoice_number => '100100',
	first_name     => 'Tofu',
	last_name      => 'Beast',
	address        => '123 Anystreet',
	city           => 'Anywhere',
	state          => 'UT',
	zip            => '84058',
	country        => 'US',
	email          => 'tofu@beast.org',
	card_number    => '4111111111111111',
	expiration     => '12/25',
);
$tx->test_transaction(1);    # test, dont really charge
$tx->submit();

is( $Business::OnlinePayment::CyberSource::BACKEND, 'SOAPI',
	'use SOAPI backend'
);

ok( $tx->is_success, 'transaction successful' )
	or diag $tx->error_message;

ok( $tx->security_key, 'check security key exists' )
	or diag $tx->error_message;
done_testing;
