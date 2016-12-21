requires 'Carp';
requires 'Carp::Always';
requires 'Class::Accessor::Fast';
requires 'Config';
requires 'Crypt::DES';
requires 'Cwd';
requires 'Data::Dumper';
requires 'Digest::MD5';
requires 'DynaLoader';
requires 'Exporter';
requires 'Exception::Class';
requires 'ExtUtils::MakeMaker';
# waiting for https://rt.cpan.org/Public/Bug/Display.html?id=106808
conflicts 'ExtUtils::MakeMaker', '>= 7.06';;
requires 'ExtUtils::testlib';
requires 'Fcntl';
requires 'File::Basename';
requires 'File::Find';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'File::Which';
requires 'IO::Handle';
requires 'IO::Select';
requires 'IO::Socket';
requires 'IO::Socket::UNIX';
requires 'IPC::Run::Debug';
requires 'IPC::System::Simple';
requires 'JSON';
requires 'JSON::XS';
requires 'Mojo::URL';
requires 'Mojo::UserAgent';
requires 'Mojolicious::Lite';
requires 'Net::DBus';
requires 'Net::SNMP';
requires 'Net::SSH2';
requires 'POSIX';
requires 'Perl::Tidy';
requires 'Term::ANSIColor';
requires 'Test::Compile';
requires 'Test::More';
requires 'Test::Simple';
requires 'Thread::Queue';
requires 'Time::HiRes';
requires 'XML::LibXML';
requires 'base';
requires 'constant';
requires 'strict';
requires 'warnings';

on 'test' => sub {
  requires 'Perl::Critic';
  requires 'Test::Output';
  requires 'Test::Fatal';
  requires 'Test::Pod';
  requires 'Test::MockModule';
  requires 'Pod::Coverage';
  requires 'Devel::Cover';
};

feature 'coverage', 'coverage for travis' => sub {
  requires 'Devel::Cover::Report::Coveralls';
};
