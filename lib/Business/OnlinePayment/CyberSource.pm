package Business::OnlinePayment::CyberSource;
use 5.010;
use strict;
use warnings;
use Carp;
our @CARP_NOT = qw(Business::OnlinePayment);
BEGIN {
	# VERSION
}
use Moose;
use namespace::autoclean;
use MooseX::NonMoose;

use Business::OnlinePayment::CyberSource::Error;
extends 'Business::OnlinePayment';

BEGIN {
	# determine which backend to use

	use Env qw( CYBERSOURCE_BACKEND );
	our $BACKEND
		= $BACKEND             ? $BACKEND
		: $CYBERSOURCE_BACKEND ? $CYBERSOURCE_BACKEND
		:                        'SOAP'
		;

	use Module::Load::Conditional qw( can_load requires );

	my $_;
	given ( $BACKEND ) {
		when ( /SOAPI/
				&& can_load(
					modules => { 'CyberSource::SOAPI'          => undef },
				)
			) {
			with 'Business::OnlinePayment::CyberSource::Role::SOAPI';
		}
		when ( /SOAP/
				&& can_load(
					modules => { 'Checkout::CyberSource::SOAP' => undef },
				)
			) {
			with 'Business::OnlinePayment::CyberSource::Role::SOAP';
		}
		when ( $_ ne 'SOAP' and $_ ne 'SOAPI' ) {
			croak 'BACKEND is not set to SOAPI or SOAP';
		}
		default {
			croak 'Unable to load CyberSource::SOAPI or '
				. 'Checkout::CyberSource::SOAP';
		}
	}
	no Env;
	no Module::Load::Conditional;
}

__PACKAGE__->meta->make_immutable;
1;

# ABSTRACT: CyberSource backend for Business::OnlinePayment

=head1 SYNOPSIS

  use Business::OnlinePayment;

  ####
  # One step transaction, the simple case.
  ####

  my $tx = Business::OnlinePayment->new("CyberSource",
                                       conf_file => '/path/to/cybs.ini'");
  $tx->content(
             type           => 'VISA',
             action         => 'Normal Authorization',
             invoice_number => '00000001',
             items          => [{'number'     => 0,
                                 'name'       => 'Test 1',
                                 'quantity'   => 1,
                                 'unit_price' => '25.00'},
                                {'number'     => 1,
                                 'name'       => 'Test 2',
                                 'quantity'   => 1,
                                 'unit_price' => '50.00'},
                                {'number'     => 3,
                                 'name'       => '$5 off',
                                 'type'       => 'COUPON',
                                 'quantity'   => 1,
                                 'unit_price' => '5.00'},
                                ],
             first_name     => 'Peter',
             last_name      => 'Bowen',
             address        => '123 Anystreet',
             city           => 'Orem',
             state          => 'UT',
             zip            => '84097',
             country        => 'US',
             email          => 'foo@bar.net',
             card_number    => '4111 1111 1111 1111',
             expiration     => '0906',
             cvv2           => '1234', #optional
             referer        => 'http://valid.referer.url/',
             user           => 'cybesource_user',
             fraud_check    => 'true',
             fraud_threshold => '90',
  );
  $tx->submit();

  if($tx->is_success()) {
      print "Card processed successfully: ".$tx->authorization."\n";
  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

  ####
  # Two step transaction, authorization and capture.
  # If you don't need to review order before capture, you can
  # process in one step as above.
  ####

  my $tx = Business::OnlinePayment->new("CyberSource",
                                       conf_file => '/path/to/cybs.ini'");
  $tx->content(
             type           => 'VISA',
             action         => 'Authorization Only',
             invoice_number => '00000001',
             items          => [{'number'   => 0,
                                 'name'     => 'iPod Mini',
                                 'quantity' => 1,
                                 'unit_price' => '25.00'},
                                {'number'   => 1,
                                 'name'     => 'Extended Warranty',
                                 'quantity' => 1,
                                 'unit_price' => '50.00'},
                                ],
             first_name     => 'Peter',
             last_name      => 'Bowen',
             address        => '123 Anystreet',
             city           => 'Orem',
             state          => 'UT',
             zip            => '84097',
             country        => 'US',
             email          => 'foo@bar.net',
             card_number    => '4111 1111 1111 1111',
             expiration     => '0906',
             cvv2           => '1234', #optional
             referer        => 'http://valid.referer.url/',
             user           => 'cybesource_user',
             fraud_check    => 'true',
             fraud_threshold => '90',
  );
  $tx->submit();

  if($tx->is_success()) {
      # get information about authorization
      $authorization = $tx->authorization
      $order_number = $tx->order_number;
      $security_key = $tx->security_key;
      $avs_code = $tx->avs_code; # AVS Response Code
      $cvv2_response = $tx->cvv2_response; # CVV2/CVC2/CID Response Code
      $cavv_response = $tx->cavv_response; # Cardholder Authentication
                                           # Verification Value (CAVV) Response
                                           # Code

      # now capture transaction
      my $capture = new Business::OnlinePayment("CyberSource");

      $capture->content(
          action              => 'Post Authorization',
          order_number        => $order_number,
          merchant_descriptor => 'IPOD MINI',
          amount              => '75.00',
          security_key        => $security_key,
      );

      $capture->submit();

      if($capture->is_success()) {
          print "Card captured successfully: ".$capture->authorization."\n";
      } else {
          print "Card was rejected: ".$capture->error_message."\n";
      }

  } else {
      print "Card was rejected: ".$tx->error_message."\n";
  }

=head1 DESCRIPTION

For detailed information see L<Business::OnlinePayment>.

=head1 API

=over 4

=item C<load_config()>

loads C<cybs.ini>

=item C<map_fields>

=item C<request_merge>

=item C<set_defaults>

=back

=head1 SUPPORTED TRANSACTION TYPES

=head2 Visa, MasterCard, American Express, Discover

Content required: type, login, action, amount, first_name, last_name, card_number, expiration.

=head2 Checks

Currently not supported (TODO)

=head1 NOTE

=head2 cybs.ini

The cybs.ini default home is /etc/cybs.ini - if you would prefer it to
live someplace else specify that in the new.

A few notes on cybs.ini - most settings can be overwritten by the submit
call - except for the following exceptions:

  sendToProduction

From a systems perspective, this should be hard so that there is NO
confusion as to which server the request goes against.

You can set the business rules from the ini - the following rules are supported

  businessRules_declineAVSFlags

  businessRules_ignoreAVSResult

  businessRules_ignoreCVResult

=head2 Full Name vs. First & Last

Unlike Business::OnlinePayment, Business::OnlinePayment::CyberSource
requires separate first_name and last_name fields.  I should probably
Just split them apart.  If you feel industrious...

=head2 Settling

To settle an authorization-only transaction (where you set action to
'Authorization Only'), submit the request ID code in the field
"order_number" with the action set to "Post Authorization".

You can get the transaction id from the authorization by calling the
order_number method on the object returned from the authorization.
You must also submit the amount field with a value less than or equal
to the amount specified in the original authorization.

=head2 Items

Item fields map as follows:

=over

=item *

productCode -> type

(adult_content, coupon, default, electronic_good, electronic_software, gift_certificate, handling_only, service, shipping_and_handling, shipping_only, stored_value, subscription)

=item *

productSKU  -> SKU

=item *

productName -> name

=item *

quantity    -> quantity

=item *

taxAmount   -> tax

=item *

unitPrice   -> unit_price

=back

See the Cybersource documentation for the significance of these fields (type can be confusing)

=head1 COMPATIBILITY

This module implements the Simple Order API 1.x from Cybersource.

=head1 THANK YOU

=over 4

=item Jason Kohles

For writing BOP - I didn't have to create my own framework.

=item Ivan Kohler

Tested the first pre-release version and fixed a number of bugs.
He also encouraged me to add better error reporting for system
errors.  He also added failure_status support.

=item Jason (Jayce^) Hall

Adding Request Token Requirements (Among other significant improvements... )

=back

=head1 SEE ALSO

perl(1). L<Business::OnlinePayment>.

=head1 TODO

=over 4

=item Full Documentation

=item Electronic Checks

=item Pay Pal

=item Full support including Level III descriptors

=back

=cut
