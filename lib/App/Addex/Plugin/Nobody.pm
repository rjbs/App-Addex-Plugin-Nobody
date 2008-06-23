use strict;
use warnings;

package App::Addex::Plugin::Hiveminder;
use 5.006; # our
use Sub::Install;

=head1 NAME

App::Addex::Plugin::Hiveminder - automatically add "to Hiveminder.com" addrs

=head2 VERSION

version 0.001

=cut

our $VERSION = '0.001';

=head1 DESCRIPTION

Hiveminder (L<http://hiveminder.com>) offers Pro customers the ability to
assign tasks to anybody with an email address, even if they don't already use
Hiveminder.  With a Hiveminder Pro account, you get a "secret."  Then, to
assign a task to C<bob@example.com>, you would send mail to
C<bob@example.com.secret.with.hm>.

This plugin makes every entry in your address book appear to have an extra
email address that will send to the C<with.hm> assignment address.

=head1 CONFIGURATION

First, you have to add the plugin to your Addex configuration file's top
section:

  plugin = App::Addex::Plugin::Hiveminder

Then you'll need to setup at least a "secret" variable, which is your
assign-by-email secret from your Hiveminder Pro account.

  [App::Addex::Plugin::Hiveminder]
  secret = closetdiscodancer

With that done, every Entry in your AddressBook will now have an additional
EmailAddress.  It will C<receive> but not C<send>, will be based on the email
address of the Entry's default address, and will have the label "todo."

To use a label other than "todo" specify a value for C<todo_label> in the
plugin configuration.

To specify that an entry's task assignment address should be built on an
address other than its default address, specify the label of the address to use
in that entry's C<todos_to> field.  Alternately, if the C<todos_to> begins and
ends with a slash, it will be treated as a regex and matched against the
entry's addresses.

So, by way of example, if an address has these addresses:

  - home : alfa@example.com
  - other: bravo@example.com
  - work : charlie@example.com

The todo address will be C<alfa@example.com.secret.with.hm>.  If C<todos_to>
were C<other>, the todo address would be C<bravo@example.com.secret.with.hm>.
If C<todos_to> were C</charlie/>, it would be
c<charlie@example.com.secret.with.hm>.

If the entry had an address with the label "todo," no address will be inserted
into the returned list.  If the entry had an address with the label "todo-via"
it will be used to form the todo address, and will be suppressed from output.
This is useful if your contact uses a specific address only for his
Hiveminder account, as the recipient of a C<with.hm> request cannot accept the
request to a different address.

=cut

sub _form_addr {
  my ($mixin, $addr, $secret) = @_;
  return "$addr.$secret.with.hm";
}

sub import {
  my ($mixin, %arg) = @_;
  die "no 'secret' config value for $mixin" unless %arg and $arg{secret};
  $arg{todo_label} ||= 'todo';

  require App::Addex::Entry;
  my $original_sub = App::Addex::Entry->can('emails');

  my $new_emails = sub {
    my ($self) = @_;

    my @emails = grep { $_->receives } $self->$original_sub;

    return @emails if grep { $_->label eq $arg{todo_label} } @emails;

    my $todo_via = "$arg{todo_label}-via";
    if (my @indices = grep { $emails[$_]->label eq $todo_via } 0..$#emails) {
      for (@indices) {
        my $email = $emails[$_];
        splice @emails, $_, 1, App::Addex::Entry::EmailAddress->new({
          address => $mixin->_form_addr($email->address, $arg{secret}),
          label   => $arg{todo_label},
          sends   => 0,
        });
      }

      return @emails;
    }

    my $email = $emails[0];

    # XXX: Totally lifted from AddressBook::Apple.  Put it somewhere more
    # sharey. -- rjbs, 2008-02-17
    CHECK_DEFAULT: {
      if (@emails > 1 and my $default = $self->field('todos_to')) {
        my $check;
        if ($default =~ m{\A/(.+)/\z}) {
          $default = qr/$1/;
          $check   = sub { $_[0]->address =~ $default };
        } else {
          $check   = sub { $_[0]->label eq $default };
        }

        for my $i (0 .. $#emails) {
          if ($check->($emails[$i])) {
            $email = $emails[$i];
            last CHECK_DEFAULT;
          }
        }

        warn "no email found for " . $self->name . " matching $default\n";
      }
    }

    push @emails, App::Addex::Entry::EmailAddress->new({
      address => $mixin->_form_addr($emails[0]->address, $arg{secret}),
      label   => $arg{todo_label},
      sends   => 0,
    });
    
    return @emails;
  };

  Sub::Install::reinstall_sub({
    code => $new_emails,
    into => 'App::Addex::Entry',
    as   => 'emails',
  });
}

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2008 Ricardo Signes, all rights reserved.

This program is free software; you may redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
