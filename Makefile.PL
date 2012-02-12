
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Visitor style traversal of Perl data structures",
  "AUTHOR" => "Yuval Kogman <nothingmuch\@woobling.org>, Marcel Gr\303\274nauer <marcel\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Test::More" => "0.88",
    "Test::Requires" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-Visitor",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::Visitor",
  "PREREQ_PM" => {
    "Class::Load" => "0.06",
    "Moose" => "0.89",
    "Task::Weaken" => 0,
    "Tie::ToObject" => "0.01",
    "namespace::clean" => "0.19"
  },
  "VERSION" => "0.28",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



