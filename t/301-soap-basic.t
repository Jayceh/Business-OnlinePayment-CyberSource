#!/usr/bin/perl
use strict;
use warnings;
use Env qw( CYBS_ID CYBS_KEY );
use Test::More;

#testing/testing is valid and seems to work...

BEGIN {
    eval 'use Checkout::CyberSource::SOAP';
    plan skip_all => 'Skipping without Checkout::CyberSource::SOAP' if $@;
	no Checkout::CyberSource::SOAP;
}

plan skip_all => 'You MUST set ENV variable CYBS_ID and CYBS_KEY to test this!'
		unless $CYBS_ID && $CYBS_KEY;

$Business::OnlinePayment::CyberSource::BACKEND = 'SOAP';
use Business::OnlinePayment;

my $tx = Business::OnlinePayment->new('CyberSource');

$tx->content(
	login          => $CYBS_ID,
	password       => $CYBS_KEY,
	type           => 'CC',
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
	expiration     => '1225',
	customer_ip    => '0.0.0.0',
);
$tx->test_transaction(1);    # test, dont really charge

$tx->submit();

is( $Business::OnlinePayment::CyberSource::BACKEND, 'SOAP',
	'Backend is SOAP'
);

ok( $tx->is_success, 'transaction successful' )
	or diag $tx->error_message;

note( $tx->order_number );

ok ( $tx->order_number, 'order_number exists' );
done_testing;
