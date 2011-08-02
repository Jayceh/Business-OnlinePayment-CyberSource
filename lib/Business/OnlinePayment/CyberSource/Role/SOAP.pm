package Business::OnlinePayment::CyberSource::Role::SOAP;
use 5.010;
use strict;
use warnings;
use Carp;
our @CARP_NOT = qw( Business::OnlinePayment Class::MOP::Method::Wrapped );
@Business::OnlinePayment::CARP_NOT = __PACKAGE__;

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

before submit => sub {
	my $self = shift;

	my $content = { $self->content };

	my $_;
	$content->{$_} // croak "$_ not defined"
		for qw( expiration address amount card_number city country email
			first_name customer_ip last_name state zip );
};

sub submit {
	my $self = shift;

	my $content = { $self->content };

	my $month = substr( $content->{expiration}, 0, 2 );
	my $year  = substr( $content->{expiration}, 2, 4 );

	my $data = {
		'expiry.month'  => $month,
		'expiry.year'   => $year,
		address1        => $content->{address},
		amount          => $content->{amount},
		cardnumber      => $content->{card_number},
		city            => $content->{city},
		country         => $content->{country},
		currency        => 'USD',
		email           => $content->{email},
		firstname       => $content->{first_name},
		ip              => $content->{customer_ip},
		lastname        => $content->{last_name},
		quantity        => '1',
		state           => $content->{state},
		zip             => $content->{zip},
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
		expirationMonth => "expiry.month",
		expirationYear  => "expiry.year",
	};

	my $production = $self->test_transaction ? 0 : 1;

	my $checkout = Checkout::CyberSource::SOAP->new(
		id         => $content->{login},
		key        => $content->{password},
		column_map => $column_map,
		production => "$production",
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

=head1 METHODS

=over 4

=item * C<submit>

See L<Business::OnlinePayment> for more information on this method

=back

=cut
