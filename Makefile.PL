
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
                       'test' => {
                                   'TESTS' => 't/*.t'
                                 },
                       'NAME' => 'POEx::PubSub',
                       'DISTNAME' => 'POEx-PubSub',
                       'CONFIGURE_REQUIRES' => {
                                                 'ExtUtils::MakeMaker' => '6.31'
                                               },
                       'AUTHOR' => 'Nicholas Perez <nperez@cpan.org>',
                       'BUILD_REQUIRES' => {
                                             'Test::More' => '0',
                                             'POE' => '0'
                                           },
                       'ABSTRACT' => 'A second generation publish/subscribe component for the POE framework',
                       'EXE_FILES' => [],
                       'VERSION' => '1.100910',
                       'PREREQ_PM' => {
                                        'MooseX::Types::Moose' => '0',
                                        'POEx::Role::SessionInstantiation' => '0',
                                        'MooseX::Declare' => '0',
                                        'POE::API::Peek' => '0',
                                        'MooseX::Types::Structured' => '0',
                                        'Sub::Exporter' => '0',
                                        'aliased' => '0',
                                        'constant' => '0',
                                        'Carp' => '0',
                                        'MooseX::Types' => '0',
                                        'POEx::Types' => '0',
                                        'Moose' => '0'
                                      },
                       'LICENSE' => 'perl'
                     );


delete $WriteMakefileArgs{BUILD_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.56) };

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



