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

1;

# ABSTRACT: Checkout::CyberSource::SOAP backend for Business::OnlinePayment::Cybersource
