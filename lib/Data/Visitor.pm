#!/usr/bin/perl

package Data::Visitor;
use base qw/Class::Accessor/;

use strict;
use warnings;

use Scalar::Util ();

our $VERSION = "0.01";

sub visit {
	my ( $self, $data ) = @_;

	if ( Scalar::Util::blessed( $data ) ) {
		return $self->visit_object( $data );
	} elsif ( my $reftype = ref $data ) {
		if ( $reftype eq "HASH" or $reftype eq "ARRAY" ) {
			my $method = lc "visit_$reftype";
			return $self->$method( $data );
		}
	}
	
	return $self->visit_value( $data );
}

sub visit_object {
	my ( $self, $object ) = @_;

	return $self->visit_value( $object );
}

sub visit_value {
	my ( $self, $value ) = @_;

	return $value;
}

sub visit_hash {
	my ( $self, $hash ) = @_;

	if ( not defined wantarray ) {
		$self->visit( $_ ) for ( values %$hash );
	} else {
		return { map { $_ => $self->visit( $hash->{$_} ) } keys %$hash }
	}
}

sub visit_array {
	my ( $self, $array ) = @_;

	if ( not defined wantarray ) {
		$self->visit( $_ ) for @$array;	
	} else {
		return [ map { $self->visit( $_ ) } @$array ];
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Data::Visitor - A visitor for Perl data structures

=head1 SYNOPSIS

	use base qw/Data::Visitor/;

	sub visit_value {
		my ( $self, $data ) = @_;

		return $whatever;
	}

	sub visit_array {
		my ( $self, $data ) = @_;

		# ...

		return $self->SUPER::visit_array( $whatever );
	}

=head1 DESCRIPTION

This module is a simple visitor implementation for Perl values.

It has a main dispatcher method, C<visit>, which takes a single perl value and
then calls the methods appropriate for that value.

The visitor pattern is 

=head1 METHODS

=over 4

=item visit $data

This method takes any Perl value as it's only argument, and dispatches to the
various other visiting methods, based on the data's type.

=item visit_object $object

If the value is a blessed object, C<visit> calls this method. The base
implementation will just forward to C<visit_value>.

=item visit_array $array_ref

This method is called when the value is an array reference.

=item visit_value $value

If the value is anything else, this method is called. The base implementation
will return $value.

=back

=head1 RETURN VALUE

This object can be used as an C<fmap> of sorts - providing an ad-hoc functor
interface for Perl data structures.

In void context this functionality is ignored, but in any other context the
default methods will all try to return a value of similar structure, with it's
children also fmapped.

=head1 SUBCLASSING

Create instance data using the L<Class::Accessor> interface. L<Data::Validator>
inherits L<Class::Accessor> to get a sane C<new>.

Then override the callback methods in any way you like. To retain visitor
behavior, make sure to retain the functionality of C<visit_array> and
C<visit_hash>.

=cut


