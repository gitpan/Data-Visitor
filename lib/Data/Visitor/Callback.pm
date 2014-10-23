#!/usr/bin/perl

package Data::Visitor::Callback;
use base qw/Data::Visitor/;

use strict;
use warnings;

use Scalar::Util qw/blessed refaddr/;

__PACKAGE__->mk_accessors( qw/callbacks class_callbacks ignore_return_values/ );

sub new {
	my ( $class, %callbacks ) = @_;

	my $ignore_ret = 0;
	if	( exists $callbacks{ignore_return_values} ) {
		$ignore_ret = delete $callbacks{ignore_return_values};
	}

	my @class_callbacks = grep { $_->can("isa") } keys %callbacks;

	$class->SUPER::new({
		ignore_return_values => $ignore_ret,
		callbacks => \%callbacks,
		class_callbacks => \@class_callbacks,
	});
}

sub visit {
	my ( $self, $data ) = @_;

	my $replaced_hash = local $self->{_replaced} = ($self->{_replaced} || {}); # delete it after we're done with the whole visit

	local *_ = \$_[1]; # alias $_

	if ( ref $data and exists $replaced_hash->{ refaddr($data) } ) {
		return $_[1] = $replaced_hash->{ refaddr($data) };
	} else {
		my $ret = $self->SUPER::visit( $self->callback( visit => $data ) );

		$replaced_hash->{ refaddr($data) } = $_ if ref $data and ( not ref $_ or refaddr($data) ne refaddr($_) );

		return $ret;
	}
}

sub visit_value {
	my ( $self, $data ) = @_;

	$self->callback( value => $data );
	$self->callback( ( ref($data) ? "ref_value" : "plain_value" ) => $data );
}

sub visit_object {
	my ( $self, $data ) = @_;

	my $ignore = $self->ignore_return_values;

	my $new_data = $self->callback( object => $data );
	$self->_register_mapping( $data, $new_data );
	$data = $new_data unless $ignore;

	foreach my $class ( @{ $self->class_callbacks } ) {
		last unless blessed($data);
		my $new_data = $self->callback( $class => $data ) if $data->isa($class);
		$data = $new_data unless $ignore;
	}

	$data;
}

BEGIN {
	foreach my $reftype ( qw/array hash glob scalar code/ ) {
		no strict 'refs';
		*{"visit_$reftype"} = eval '
			sub {
				my ( $self, $data ) = @_;
				my $new_data = $self->callback( '.$reftype.' => $data );
				$self->_register_mapping( $data, $new_data );
				if ( ref $data eq ref $new_data ) {
					return $self->_register_mapping( $data, $self->SUPER::visit_'.$reftype.'( $new_data ) );
				} else {
					return $self->_register_mapping( $data, $self->visit( $new_data ) );
				}
			}
		' || die $@;
	}
}

sub callback {
	my ( $self, $name, $data ) = @_;

	if ( my $code = $self->callbacks->{$name} ) {
		my $ret = $self->$code( $data );
		return $self->ignore_return_values ? $data : $ret ;
	} else {
		return $data;
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Data::Visitor::Callback - A Data::Visitor with callbacks.

=head1 SYNOPSIS

	use Data::Visitor::Callback;

	my $v = Data::Visitor::Callback->new(
		value => sub { ... },
		array => sub { ... },
	);

	$v->visit( $some_perl_value );

=head1 DESCRIPTION

This is a L<Data::Visitor> subclass that lets you invoke callbacks instead of
needing to subclass yourself.

=head1 METHODS

=over 4

=item new %opts, %callbacks

Construct a new visitor.

The options supported are:

=over 4

=item ignore_return_values

When this is true (off by default) the return values from the callbacks are
ignored, thus disabling the fmapping behavior as documented in
L<Data::Visitor>.

This is useful when you want to modify $_ directly

=back

=back

=head1 CALLBACKS

Use these keys for the corresponding callbacks.

The callback is in the form:

	sub {
		my ( $visitor, $data ) = @_;

		# or you can use $_, it's aliased

		return $data; # or modified data
	}

Within the callback $_ is aliased to the data, and this is also passed in the
parameter list.

Any method can also be used as a callback:

	object => "visit_ref", # visit objects anyway

=over 4

=item visit

Called for all values

=item value

Called for non objects, non container (hash, array, glob or scalar ref) values.

=item ref_value

Called after C<value>, for references to regexes, globs and code.

=item plain_value

Called after C<value> for non references.

=item object

Called for blessed objects.

Since L<Data::Visitor/visit_object> will not recurse downwards unless you
delegate to C<visit_ref>, you can specify C<visit_ref> as the callback for
C<object> in order to enter objects.

It is reccomended that you specify the classes you want though, instead of just
visiting any object forcefully.

=item Some::Class

You can use any class name as a callback. This is clled only after the
C<object> callback.

=item array

Called for array references.

=item hash

Called for hash references.

=item glob

Called for glob references.

=item scalar

Called for scalar references.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2006 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut


