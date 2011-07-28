package Business::OnlinePayment::CyberSource::Role::SOAPI;
use strict;
use warnings;
use Moose::Role;
use namespace::autoclean;
BEGIN {
	# VERSION

	use Carp;
	use English qw( -no_match_vars );
	eval "use CyberSource::SOAPI";
	croak 'unable to load CyberSource::SOAPI' if $EVAL_ERROR;
	no English;
}

has config => (
	is       => 'rw',
	isa      => 'HashRef[Str]',
	traits   => ['Hash'],
	required => 1,
	lazy     => 1,
	default  => sub {
		my $self = shift;

		# The default is /etc/
		my $conf_file = ( $self->can('conf_file') && $self->conf_file )
			|| '/etc/cybs.ini';

		my $config = { CyberSource::SOAPI::cybs_load_config($conf_file) };

		return $config;
	},
	handles  => {
		get_config => 'get',
	},
);
1;

# ABSTRACT: Role that abstracts CyberSource::SOAPI
