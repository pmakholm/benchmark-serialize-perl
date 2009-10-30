#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Benchmark::Serialize;

my @benchmark          = ();      # package names of benchmarks to run
my $iterations         = -1;      # integer
my $structure          = {
    array  => [ 'a' .. 'j' ],
    hash   => { 'a' .. 'z' },
    string => 'x' x 200
};

Getopt::Long::Configure( 'bundling' );
Getopt::Long::GetOptions(
    'b|benchmark=s@' => \@benchmark,
    'deflate!'       => \$Benchmark::Serialize::benchmark_deflate,
    'inflate!'       => \$Benchmark::Serialize::benchmark_inflate,
    'i|iterations=i' => \$iterations,
    'o|output=s'     => \$Benchmark::Serialize::output,
    's|structure=s'  => sub {
        die "Structure option requires YAML.\n"
        unless YAML->require;

        $structure = YAML::LoadFile( $_[1] );
    }
) or exit 1;

@benchmark = ("all") unless @benchmark;

Benchmark::Serialize::cmpthese($iterations, $structure, @benchmark);

