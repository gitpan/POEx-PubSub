
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'POEx-PubSub',
  NAME      => 'POEx::PubSub',
  AUTHOR    => 'Nicholas\ Perez\ \<nperez\@cpan\.org\>',
  ABSTRACT  => 'A\ second\ generation\ publish\/subscribe\ component\ for\ the\ POE\ framework',
  VERSION   => '0.092440',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'gpl') : ()),
  PREREQ_PM    => {
    "POEx::Role::SessionInstantiation" => '0.092440',
    "MooseX::AttributeHelpers" => '0.21',
    "POE::API::Peek" => '2.15',
  },
);
