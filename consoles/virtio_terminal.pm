# Copyright © 2016-2019 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, see <http://www.gnu.org/licenses/>.
package consoles::virtio_terminal;

use 5.018;
use strict;
use warnings;
use autodie;

use base 'consoles::console';

use Socket qw(SOCK_NONBLOCK PF_UNIX SOCK_STREAM sockaddr_un);
use Errno qw(EAGAIN EWOULDBLOCK);
use English -no_match_vars;
use Carp 'croak';
use Scalar::Util 'blessed';
use Cwd;
use consoles::serial_screen ();
use testapi 'check_var';
use IO::Socket::INET;

our $VERSION;

=head1 NAME

consoles::virtio_terminal

=head1 SYNOPSIS

Provides functions to allow the testapi to interact with a text only console.

=head1 DESCRIPTION

This console can be requested when the backend (usually QEMU/KVM) and guest OS
support virtio serial and virtio console. The guest also needs to be in a state
where it can start a tty on the virtual console. By default openSUSE and SLE
automatically start agetty when the kernel finds the virtio console device, but
another OS may require some additional configuration.

It may also be possible to use a transport other than virtio. This code just
requires a UNIX socket which inputs and outputs terminal ASCII/ANSI codes.

=head1 SUBROUTINES/METHODS

=cut

sub new {
    my ($class, $testapi_console, $args) = @_;
    my $self = $class->SUPER::new($testapi_console, $args);
    $self->{socket_fd}      = 0;
    $self->{console_num}    = $self->{args}->{console_num} // 0;
    $self->{snapshots}      = {};
    $self->{preload_buffer} = '';

    # W/A for backward compatibility
    if (defined($self->{socked_path})) {
        my ($i) = $self->{socked_path} =~ /virtio_console(\d+)$/;
        die("Missing console_num in socked_path") unless (defined($i));
    }
    return $self;
}

sub screen {
    my ($self) = @_;
    return $self->{screen};
}

sub disable {
    my ($self) = @_;
    if ($self->{socket_fd} > 0) {
        close $self->{socket_fd};
        $self->{socket_fd} = 0;
        $self->{screen}    = undef;
    }
}

sub save_snapshot {
    my ($self, $name) = @_;

    if (defined($self->{screen})) {
        $self->{snapshots}->{$name} = $self->{screen}->peak();
    } else {
        $self->{snapshots}->{$name} = '';
    }
}

sub load_snapshot {
    my ($self, $name) = @_;

    if (defined($self->{screen})) {
        $self->{screen}->{carry_buffer} = $self->{snapshots}->{$name};
    } else {
        $self->{preload_buffer} = $self->{snapshots}->{$name};
    }
}

=head2 open_socket

  open_socket();

Opens a socket to the host end of the virtio_console. This need to be
corresponding to the console which was created by qemu-backend.

Returns the file descriptor for the open socket, otherwise it dies.

=cut
sub open_socket {
    my ($self) = @_;
    my $fd;
    my $port;
    my $vars = \%bmwqemu::vars;
    bmwqemu::log_call(console_num => $self->{console_num});

    $port = 62600 + $self->{console_num} + 10 * ($vars->{WORKER_INSTANCE} // 0);
    $fd   = IO::Socket::INET->new(PeerAddr => '127.0.0.1', PeerPort => $port, Proto => 'tcp')
      or die('Connection to virtio_terminal nr ' . $self->{console_num} . ' failed on port ' . $port);

    return $fd;
}

sub activate {
    my ($self) = @_;
    if (!check_var('VIRTIO_CONSOLE', 0)) {
        $self->{socket_fd}              = $self->open_socket unless $self->{socket_fd};
        $self->{screen}                 = consoles::serial_screen::->new($self->{socket_fd});
        $self->{screen}->{carry_buffer} = $self->{preload_buffer};
        $self->{preload_buffer}         = '';
    }
    else {
        croak 'VIRTIO_CONSOLE is set 0, so no virtio-serial and virtconsole devices will be available to use with this console.';
    }
    return;
}

sub is_serial_terminal {
    return 1;
}

1;
