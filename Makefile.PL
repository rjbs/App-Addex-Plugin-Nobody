use inc::Module::Install;

all_from('lib/App/Addex/Plugin/Nobody.pm');

requires('App::Addex'    => 0.018); # plugins, Mutt output fixes
requires('Sub::Install'  => 0.000); # minimum unknown

extra_tests;

repository('http://github.com/rjbs/app-addex-plugin-nobody');
auto_manifest;

WriteAll();
