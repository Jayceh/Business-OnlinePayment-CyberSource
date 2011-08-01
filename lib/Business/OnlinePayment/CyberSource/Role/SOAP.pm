package Business::OnlinePayment::CyberSource::Role::SOAP;
use 5.010;
use strict;
use warnings;
use Carp;
BEGIN {
	# VERSION

	use Module::Load::Conditional qw( can_load requires );

	if ( can_load( modules => { 'Checkout::CyberSource::SOAP' => undef } ) ) {
		requires 'Checkout::CyberSource::SOAP';
	}
	no Module::Load::Conditional;
}
use Moose::Role;
use namespace::autoclean;

has config => (
	is       => 'rw',
	isa      => 'HashRef[Str]',
	traits   => ['Hash'],
	required => 1,
);

sub submit {
	my $self = shift;

	my $content = { $self->content };

	my $month = substr( $content->{expiration}, 0, 2 );
	my $year  = substr( $content->{expiration}, 2, 2 );

	my $data = {
		firstname       => $content->{first_name},
		lastname        => $content->{last_name},
		address1        => $content->{address},
		city            => $content->{city},
		state           => $content->{state},
		zip             => $content->{zip},
		country         => $content->{country},
		email           => $content->{email},
		ip              => $content->{customer_ip},
		amount          => $content->{amount},
		quantity        => 1,
		currency        => 'USD',
		cardnumber      => $content->{card_number},
		exp_month       => $month,
		exp_year        => $year,
	};

	# I don't really understand the need for colum maps but w/e
	my $column_map = {
		firstName       => "firstname",
		lastName        => "lastname",
		street1         => "address1",
		city            => "city",
		state           => "state",
		postalCode      => "zip",
		country         => "country",
		email           => "email",
		ipAddress       => "ip",
		unitPrice       => "amount",
		quantity        => "quantity",
		currency        => "currency",
		accountNumber   => "cardnumber",
		expirationMonth => "exp_month",
		expirationYear  => "exp_year",
	};

	my $checkout = Checkout::CyberSource::SOAP->new(
		id         => $content->{login},
		key        => $content->{password},
		column_map => $column_map,
    );

	$checkout->checkout( $data );

	if ( $checkout->response->success ) {
		$self->is_success(1);
	}
	else {
		$self->error_message( $checkout->response->{error} );
	}
	return 1;
}

1;

# ABSTRACT: Checkout::CyberSource::SOAP backend for Business::OnlinePayment::Cybersource
