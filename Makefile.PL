use inc::Module::Install;

name          ('App-Addex-Plugin-Nobody');
author        ('Ricardo Signes <rjbs@cpan.org>');
license       ('perl');
version_from  ('lib/App/Addex/Plugin/Nobody.pm');

requires('App::Addex'    => 0.018); # plugins, Mutt output fixes
requires('Sub::Install'  => 0.000); # minimum unknown

extra_tests;

WriteAll();
