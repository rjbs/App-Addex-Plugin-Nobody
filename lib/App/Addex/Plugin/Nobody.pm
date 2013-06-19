use strict;
use warnings;

package App::Addex::Plugin::Nobody;
use 5.006; # our
use Sub::Install;
# ABSTRACT: automatically add a recipient that goes nowhere

=head1 DESCRIPTION

The only valid "To" header that doesn't imply delivery somewhere
looks something like this:

  To: undisclosed-recipients: ;

This plugin adds a virtual entry to your address book with that address.

=head1 CONFIGURATION

First, you have to add the plugin to your Addex configuration file's top
section:

  plugin = App::Addex::Plugin::Nobody

You can supply the following options for the plugin:

  name  - the "full name" to use (default: "Undisclosed Recipients")
  nick  - the nick (if any) to provide (default: nobody)
  group - the name of the address group (default: undisclosed-recipients)
          this option is not well-validated, so maybe you should leave it alone

The entry will have a true C<skip_hiveminder> field, to avoid bizarre
interactions with the Hiveminder plugin.

=cut

sub import {
  my ($mixin, %arg) = @_;


  my $group_name = $arg{group} || 'undisclosed-recipients';

  require App::Addex::Entry;

  my $nobody = App::Addex::Entry->new({
    name   => $arg{name} || 'Undisclosed Recipients',
    nick   => exists $arg{nick} ? $arg{nick} : 'nobody',
    fields => { skip_hiveminder => 1 },
    emails => [
      App::Addex::Entry::EmailAddress->new({
        address  => "$group_name: ;",
        sends    => 0,
        receives => 1,
      }),
    ],
  });

  my $caller = caller;
  my $original_sub = $caller->can('entries');

  my $new_entries = sub {
    my ($self) = @_;

    my @entries = $self->$original_sub;

    return (@entries, $nobody);
  };

  Sub::Install::reinstall_sub({
    code => $new_entries,
    into => $caller,
    as   => 'entries',
  });
}

1;
