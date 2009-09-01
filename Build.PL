
use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
  module_name   => 'POEx::PubSub',
  license       => 'gpl',
  dist_abstract => "A\ second\ generation\ publish\/subscribe\ component\ for\ the\ POE\ framework",
  dist_name     => "POEx\-PubSub",
  dist_author   => [
"Nicholas\ Perez\ \<nperez\@cpan\.org\>",
  ],
  requires      => {
    "POEx::Role::SessionInstantiation" => '0.092440',
    "MooseX::AttributeHelpers" => '0.21',
    "POE::API::Peek" => '2.15',
  },
  script_files => [ qw() ],
);

$build->create_build_script;
