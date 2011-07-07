
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'English' => '0',
    'File::Find' => '0',
    'File::Temp' => '0',
    'Module::Build' => '0.3601',
    'Path::Class' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0.94',
    'Test::Perl::Critic::Progressive' => '0',
    'Try::Tiny' => '0',
    'perl' => '5.004'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Given a starting date, a number of days and a list of days to be skipped, returns the date X number of days away.',
  'dist_author' => [
    'Alan Young <harleypig@gmail.com>'
  ],
  'dist_name' => 'DateTimeX-Duration-SkipDays',
  'dist_version' => '0.001',
  'license' => 'perl',
  'module_name' => 'DateTimeX::Duration::SkipDays',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Carp' => '0',
    'DateTime' => '0',
    'DateTime::Event::Holiday::US' => '0',
    'DateTime::Format::Flexible' => '0'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
