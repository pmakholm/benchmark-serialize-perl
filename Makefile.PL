use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Benchmark::Serialize',
    AUTHOR              => q{Peter Makholm <peter@makholm.net>},
    VERSION_FROM        => 'lib/Benchmark/Serialize.pm',
    ABSTRACT_FROM       => 'lib/Benchmark/Serialize.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Benchmark-Serialize-*' },
);
