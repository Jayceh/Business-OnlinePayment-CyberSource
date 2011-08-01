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

	my $checkout = Checkout::CyberSource::SOAP->new(
		id         => $content->{login},
		key        => $content->{password},
		production => $self->test_transaction //= 0,
		column_map => {
			firstName       => $content->{first_name},
			lastName        => $content->{last_name},
			street1         => $content->{address},
			city            => $content->{city},
			state           => $content->{state},
			zip             => $content->{zip},
			country         => $content->{country},
			email           => $content->{email},
			ipAddress       => $content->{customer_ip},
			accountNumber   => $content->{card_number},
			expirationMonth => $month,
			expirationYear  => $year,
			unitPrice       => $content->{amount},
		},
    );

	my $response = $checkout->checkout;

	if ( $response->success ) {
		$self->is_success(1);
	}
	else {
		$self->error_message( $response->error->{message} );
	}
	return 1;
}

1;

# ABSTRACT: Checkout::CyberSource::SOAP backend for Business::OnlinePayment::Cybersource
