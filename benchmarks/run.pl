#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

use Benchmark::Serialize qw( cmpthese );
use Benchmark::Serialize::Library::ProtocolBuffers;
use Benchmark::Serialize::Library::ProtocolBuffers::XS;

my @benchmark          = ();      # package names of benchmarks to run
my $iterations         = -1;      # integer
my $dir;                          # Directory containing benchmark

my $protocolbuffers; # Can't process inline as we might need the structure

Getopt::Long::Configure( 'bundling' );
Getopt::Long::GetOptions(
    'dir=s'          => \$dir,
    'b|benchmark=s@' => \@benchmark,
    'i|iterations=i' => \$iterations,
    'deflate!'       => \$Benchmark::Serialize::benchmark_deflate,
    'inflate!'       => \$Benchmark::Serialize::benchmark_inflate,
    'o|output=s'     => \$Benchmark::Serialize::output,
    'v|verbose!'     => \$Benchmark::Serialize::verbose,
) or exit 1;

@benchmark = qw(:core JSON::XS Data::MessagePack :ProtocolBuffers) unless @benchmark;

my $structure = do "$dir/structure.pl";

if ( -e "$dir/structure.proto" ) {
    Benchmark::Serialize::Library::ProtocolBuffers->register( "Google::ProtocolBuffers" => "$dir/structure.proto" );
}

if ( -d "$dir/StructureXS" ) {
    require blib;
    blib->import( "$dir/StructureXS" );

    Benchmark::Serialize::Library::ProtocolBuffers::XS->register("StructureXS");
}

cmpthese($iterations, $structure, @benchmark);

