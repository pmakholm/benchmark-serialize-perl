package Benchmark::Serialize;

# Originaly at: 
#   http://idisk.mac.com/christian.hansen/Public/perl/serialize.pl
# Updated by Peter Makholm, June 2009
#   http://gist.github.com/130005
#   - Added Data::Dumper and a current set of YAML/JSON modules
#   - added tags for the -b option: :core, :yaml, :json
# see bottom of this script for benchmark results.

use strict;
use warnings;

=head1 NAME

Benchmark::Serialize - Benchmarks of serialization modules

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Benchmark::Serialise qw(cmpthese);

    my $structure = {
        array  => [ 'a' .. 'j' ],
        hash   => { 'a' .. 'z' ]
        string => 'x' x 200,
    };

    cmpthese( -5, $structure, qw(:core :json :yaml) );

=head1 DESCRIPTION

This module encapsulates some basic benchmarks to help you choose a module
for serializing data. Note that using this module is only a part of chosing a
serialization format. Other factors than the benchmarked might be of
relevance!

=head2 Functions

This module provides the following functions

=over 5

=item cmpthese(COUNT, STRUCTURE, BENCHMARKS ...)

Benchmark COUNT interations of a list of modules. A benchmark is either a name
of a supported module, a tag, or a hash ref containing at least an inflate, a
deflate, and a name attribute:

  {
      name    => 'JSON::XS',
      deflate => sub { JSON::XS::encode_json($_[0]) }
      inflate => inflate  => sub { JSON::XS::decode_json($_[0]) }
  }

By default Benchmark::Serialize will try to use the name attribute as a module
to be loaded. This can be overridden by having a packages attribute with an
arrayref containing modules to be loaded.

=back

=head2 Benchmark tags

The following tags are supported

=over 5

=item :all     - All modules with premade benchmarks 

=item :default - A default set of serialization modules

=item :core    - Serialization modules included in core

=item :json    - JSON modules

=item :yaml    - YAML modules

=back

=cut

use Benchmark          qw[timestr];
use UNIVERSAL::require qw[];

use Exporter qw(import);
our @EXPORT_OK   = qw( cmpthese );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

my $benchmarks = {
    'Bencode' => {
        deflate  => sub { Bencode::bencode($_[0])                },
        inflate  => sub { Bencode::bdecode($_[0])                }
    },    
    'Convert::Bencode' => {
        deflate  => sub { Convert::Bencode::bencode($_[0])       },
        inflate  => sub { Convert::Bencode::bdecode($_[0])       }
    },
    'Convert::Bencode_XS' => {
        deflate  => sub { Convert::Bencode_XS::bencode($_[0])    },
        inflate  => sub { Convert::Bencode_XS::bdecode($_[0])    }
    },
    'Data::Dumper' => {
        deflate  => sub { Data::Dumper->Dump([ $_[0] ])          },
        inflate  => sub { my $VAR1; eval $_[0]                   },
        default  => 1,
        core     => 1,
    },
    'Data::Taxi' => {
        deflate  => sub { Data::Taxi::freeze($_[0])              },
        inflate  => sub { Data::Taxi::thaw($_[0])                },
    },
    'FreezeThaw' => {
        deflate  => sub { FreezeThaw::freeze($_[0])              },
        inflate  => sub { FreezeThaw::thaw($_[0])                },
        default  => 1
    },
    'JSON::PP' => {
        deflate  => sub { JSON::PP::encode_json($_[0])           },
        inflate  => sub { JSON::PP::decode_json($_[0])           },
        default  => 1,
        json     => 1
    },
    'JSON::XS' => {
        deflate  => sub { JSON::XS::encode_json($_[0])           },
        inflate  => sub { JSON::XS::decode_json($_[0])           },
        default  => 1,
        json     => 1
    },    
    'Storable' => {
        deflate  => sub { Storable::nfreeze($_[0])               },
        inflate  => sub { Storable::thaw($_[0])                  },
        default  => 1,
        core     => 1,
    },
    'PHP::Serialization' => {
        deflate  => sub { PHP::Serialization::serialize($_[0])   },
        inflate  => sub { PHP::Serialization::unserialize($_[0]) }
    },
    'RPC::XML' => {
        deflate  => sub { RPC::XML::response->new($_[0])         },
        inflate  => sub { RPC::XML::ParserFactory->new->parse($_[0])    },
        packages => ['RPC::XML', 'RPC::XML::ParserFactory']
    },
    'YAML::Old' => {
        deflate  => sub { YAML::Old::Dump($_[0])                 },
        inflate  => sub { YAML::Old::Load($_[0])                 },
        default  => 1,
        yaml     => 1
    },
    'YAML::XS' => {
        deflate  => sub { YAML::XS::Dump($_[0])                  },
        inflate  => sub { YAML::XS::Load($_[0])                  },
        default  => 1,
        yaml     => 1
    },
    'YAML::Tiny' => {
        deflate  => sub { YAML::Tiny::Dump($_[0])                },
        inflate  => sub { YAML::Tiny::Load($_[0])                },
        default  => 1,
        yaml     => 1
    },
    'XML::Simple' => {
        deflate  => sub { XML::Simple::XMLout($_[0])             },
        inflate  => sub { XML::Simple::XMLin($_[0])              },
        default  => 1
    }
};

our $benchmark_deflate  = 1;       # boolean
our $benchmark_inflate  = 1;       # boolean
our $benchmark_size     = 1;       # boolean
our $output             = 'chart'; # chart or time

sub cmpthese {
    my $iterations = shift;
    my $structure  = shift;
    my %benchmark;
    for my $spec (@_) {
        if ( ref $spec eq "HASH" ) {
            $benchmark{ $spec->{name} } = $spec; 

        } elsif ( $spec eq "all" or $spec eq ":all" ) {
            $benchmark { $_ } = $benchmarks->{ $_ } for keys %{ $benchmarks };
        
        } elsif ( $spec eq "default" ) {
            $benchmark{ $_ } = $benchmarks->{ $_ } for grep { $benchmarks->{ $_ }->{default} } keys %{ $benchmarks };
        
        } elsif ( $spec =~ /^:(.*)/ ) {
            $benchmark{ $_ } = $benchmarks->{ $_ } for grep { $benchmarks->{ $_ }->{$1} } keys %{ $benchmarks };
        
        } elsif ( exists $benchmarks->{ $spec } ) {
            $benchmark{ $spec } = $benchmarks->{ $spec }
        
        } else {
            warn "Unknown benchmark '$spec'.";
        }
    }

    my $width   = width(keys %benchmark);
    my $results = { };

    print "\nModules\n";

    BENCHMARK:

    foreach my $name ( sort keys %benchmark ) {

        my $benchmark = $benchmark{$name};
        my @packages  = ( exists($benchmark->{packages}) ? @{ $benchmark->{packages} } : $name );

        $_->require or next BENCHMARK for @packages;

        printf( "%-${width}s : %s\n", $packages[0], $packages[0]->VERSION );

        $results->{deflate}->{$name} = time_deflate( $iterations, $structure, $benchmark )
            if $benchmark_deflate;

        $results->{inflate}->{$name} = time_inflate( $iterations, $structure, $benchmark )
            if $benchmark_inflate;

        $results->{size}->{$name}    = length( $benchmark->{deflate}->($structure) );
    }

    output( 'Sizes', "size", $results->{size}, $width )
        if $benchmark_size;

    output( 'Deflate', $output, $results->{deflate}, $width )
        if $benchmark_deflate;

    output( 'Inflate', $output, $results->{inflate}, $width )
        if $benchmark_inflate;
}

sub output {
    my $title  = shift;
    my $output = shift;
    printf( "\n%s\n", $title );
    return ( $output eq 'size' ) ? &output_size_chart
         : ( $output eq 'time' ) ? &output_time 
         :                         &output_chart;
}

sub output_chart {
    my $results = shift;
    Benchmark::cmpthese($results);
}

sub output_time {
    my $results = shift;
    my $width   = shift;
    foreach my $title ( sort keys %{ $results } ) {
        printf( "%-${width}s %s\n", $title, timestr( $results->{ $title } ) );
    }
}

sub output_size_chart {
    my $results = shift;
    my @vals    = sort { $a->[1] <=> $b->[1] } map { [ $_, $results->{$_} ] } keys %$results;

    my @rows    = ( [
        '',
        'bytes',
        map { $_->[0] } @vals,
    ] );

    my @col_width = map { length ( $_ ) } @{ $rows[0] };

    for my $row_val ( @vals ) {
        my @row;

        push @row, $row_val->[0], $row_val->[1];
        $col_width[0] = ( length ( $row_val->[0] ) > $col_width[0] ? length( $row_val->[0] ) : $col_width[0] );
        $col_width[1] = ( length ( $row_val->[1] ) > $col_width[1] ? length( $row_val->[1] ) : $col_width[1] );

        # Columns 2..N = performance ratios
        for my $col_num ( 0 .. $#vals ) {
            my $col_val = $vals[$col_num];
            my $out;

            if ( $col_val->[0] eq $row_val->[0] ) {
                $out = "--";
            } else {
                $out = sprintf( "%.0f%%", 100*$row_val->[1]/$col_val->[1] - 100 );
            }

            push @row, $out;
            $col_width[$col_num+2] = ( length ( $out ) > $col_width[$col_num+2] ? length ( $out ) : $col_width[$col_num+2]);
        }
        push @rows, \@row;
    }

    # Pasted from Benchmark.pm
    # Equalize column widths in the chart as much as possible without
    # exceeding 80 characters.  This does not use or affect cols 0 or 1.
    my @sorted_width_refs = 
       sort { $$a <=> $$b } map { \$_ } @col_width[2..$#col_width];
    my $max_width = ${$sorted_width_refs[-1]};

    my $total = @col_width - 1 ;
    for ( @col_width ) { $total += $_ }

    STRETCHER:
    while ( $total < 80 ) {
        my $min_width = ${$sorted_width_refs[0]};
        last
           if $min_width == $max_width;
        for ( @sorted_width_refs ) {
            last 
                if $$_ > $min_width;
            ++$$_;
            ++$total;
            last STRETCHER
                if $total >= 80;
        }
    }

    # Dump the output
    my $format = join( ' ', map { "%${_}s" } @col_width ) . "\n";
    substr( $format, 1, 0 ) = '-';
    for ( @rows ) {
        printf $format, @$_;
    }
}

sub output_size {
    my $results = shift;
    my $width   = shift;
    foreach my $title ( sort keys %{ $results } ) {
        printf( "%-${width}s : %d bytes\n", $title, $results->{ $title } );
    }
}

sub time_deflate {
    my ( $iterations, $structure, $benchmark ) = @_;
    my $deflate = $benchmark->{deflate};
    return Benchmark::timethis( $iterations, sub { &$deflate($structure) }, '', 'none' );
}

sub time_inflate {
    my ( $iterations, $structure, $benchmark ) = @_;
    my $inflate = $benchmark->{inflate};
    my $deflated = $benchmark->{deflate}->($structure);
    return Benchmark::timethis( $iterations, sub { &$inflate($deflated)  }, '', 'none' );
}

sub width {
    return length( ( sort { length $a <=> length $b } @_ )[-1] );
}

=head1 AUTHOR

Peter Makholm, C<< <peter at makholm.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-benchmark-serialize at
rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Benchmark-Serialize>.  I will
be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

This module started out as a script written by Christian Hansen, see 
http://idisk.mac.com/christian.hansen/Public/perl/serialize.pl

=head1 COPYRIGHT & LICENSE

Copyright 2009 Peter Makholm.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


__DATA__
Modules
Bencode             : 1.31
Convert::Bencode    : 1.03
Convert::Bencode_XS : 0.06
Data::Dumper        : 2.121_14
Data::Taxi          : 0.95
FreezeThaw          : 0.45
JSON::PP            : 2.24000
JSON::XS            : 2.24
PHP::Serialization  : 0.31
RPC::XML            : 1.41
Storable            : 2.20
XML::Simple         : 2.18
YAML::Old           : 0.81
YAML::Tiny          : 1.39
YAML::XS            : 0.32

Deflate
                        Rate YAML::Old Data::Taxi PHP::Serialization XML::Simple JSON::PP RPC::XML YAML::Tiny Bencode Data::Dumper Convert::Bencode FreezeThaw YAML::XS Storable Convert::Bencode_XS JSON::XS
YAML::Old              257/s        --       -85%               -89%        -90%     -91%     -92%       -94%    -96%         -97%             -97%       -97%     -98%     -99%                -99%    -100%
Data::Taxi            1737/s      577%         --               -26%        -35%     -38%     -47%       -62%    -76%         -82%             -82%       -82%     -86%     -94%                -96%     -99%
PHP::Serialization    2353/s      817%        35%                 --        -12%     -16%     -28%       -48%    -67%         -75%             -75%       -76%     -82%     -92%                -95%     -99%
XML::Simple           2668/s      940%        54%                13%          --      -5%     -18%       -41%    -63%         -72%             -72%       -72%     -79%     -91%                -94%     -99%
JSON::PP              2815/s      997%        62%                20%          6%       --     -14%       -38%    -61%         -70%             -71%       -71%     -78%     -90%                -94%     -99%
RPC::XML              3272/s     1175%        88%                39%         23%      16%       --       -28%    -55%         -65%             -66%       -66%     -74%     -89%                -93%     -98%
YAML::Tiny            4516/s     1660%       160%                92%         69%      60%      38%         --    -38%         -52%             -53%       -53%     -65%     -84%                -90%     -98%
Bencode               7226/s     2717%       316%               207%        171%     157%     121%        60%      --         -23%             -24%       -25%     -43%     -75%                -84%     -96%
Data::Dumper          9402/s     3565%       441%               300%        252%     234%     187%       108%     30%           --              -2%        -3%     -26%     -68%                -79%     -95%
Convert::Bencode      9567/s     3629%       451%               307%        259%     240%     192%       112%     32%           2%               --        -1%     -25%     -67%                -78%     -95%
FreezeThaw            9654/s     3663%       456%               310%        262%     243%     195%       114%     34%           3%               1%         --     -24%     -67%                -78%     -95%
YAML::XS             12752/s     4871%       634%               442%        378%     353%     290%       182%     76%          36%              33%        32%       --     -56%                -71%     -94%
Storable             29119/s    11250%      1576%              1137%        992%     934%     790%       545%    303%         210%             204%       202%     128%       --                -34%     -86%
Convert::Bencode_XS  44126/s    17100%      2440%              1775%       1554%    1468%    1249%       877%    511%         369%             361%       357%     246%      52%                  --     -78%
JSON::XS            202569/s    78858%     11561%              8508%       7493%    7096%    6091%      4386%   2703%        2055%            2017%      1998%    1489%     596%                359%       --

Inflate
                       Rate YAML::Old XML::Simple PHP::Serialization Data::Taxi JSON::PP YAML::Tiny Convert::Bencode FreezeThaw RPC::XML Bencode Data::Dumper YAML::XS Convert::Bencode_XS Storable JSON::XS
YAML::Old             190/s        --        -45%               -73%       -79%     -83%       -90%             -91%       -93%     -93%    -95%         -98%     -99%               -100%    -100%    -100%
XML::Simple           345/s       82%          --               -50%       -61%     -68%       -82%             -84%       -87%     -88%    -91%         -97%     -98%                -99%     -99%    -100%
PHP::Serialization    692/s      265%        100%                 --       -23%     -37%       -63%             -68%       -73%     -76%    -81%         -94%     -95%                -99%     -99%     -99%
Data::Taxi            894/s      371%        159%                29%         --     -18%       -52%             -58%       -66%     -69%    -76%         -92%     -94%                -98%     -99%     -99%
JSON::PP             1093/s      476%        217%                58%        22%       --       -42%             -49%       -58%     -62%    -70%         -90%     -93%                -98%     -98%     -99%
YAML::Tiny           1876/s      889%        443%               171%       110%      72%         --             -12%       -28%     -34%    -49%         -84%     -87%                -96%     -97%     -98%
Convert::Bencode     2129/s     1023%        516%               208%       138%      95%        14%               --       -18%     -26%    -42%         -81%     -86%                -96%     -97%     -98%
FreezeThaw           2597/s     1269%        652%               276%       191%     138%        38%              22%         --      -9%    -30%         -77%     -83%                -95%     -96%     -97%
RPC::XML             2860/s     1408%        728%               314%       220%     162%        52%              34%        10%       --    -22%         -75%     -81%                -94%     -95%     -97%
Bencode              3688/s     1845%        968%               433%       313%     237%        97%              73%        42%      29%      --         -68%     -75%                -93%     -94%     -96%
Data::Dumper        11387/s     5903%       3196%              1546%      1174%     941%       507%             435%       338%     298%    209%           --     -24%                -77%     -82%     -87%
YAML::XS            14975/s     7795%       4235%              2065%      1576%    1270%       698%             603%       477%     424%    306%          32%       --                -70%     -76%     -83%
Convert::Bencode_XS 49227/s    25853%      14150%              7017%      5408%    4402%      2524%            2212%      1795%    1621%   1235%         332%     229%                  --     -21%     -44%
Storable            62453/s    32825%      17978%              8930%      6888%    5612%      3229%            2833%      2305%    2084%   1593%         448%     317%                 27%       --     -29%
JSON::XS            88311/s    46458%      25464%             12668%      9781%    7976%      4607%            4047%      3300%    2988%   2294%         676%     490%                 79%      41%       --
