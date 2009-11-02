package Benchmark::Serialize;

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
        deflate  => sub { RPC::XML::response->new($_[0])->as_string         },
        inflate  => sub { RPC::XML::ParserFactory->new->parse($_[0])->value },
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
our $output             = 'chart'; # chart or list

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

        $results->{deflate}->{$name} = timeit_deflate( $iterations, $structure, $benchmark )
            if $benchmark_deflate;

        $results->{inflate}->{$name} = timeit_inflate( $iterations, $structure, $benchmark )
            if $benchmark_inflate;

        $results->{size}->{$name}    = length( $benchmark->{deflate}->($structure) );
    }

    output( 'Sizes', "size", $output, $results->{size}, $width )
        if $benchmark_size;

    output( 'Deflate', "time", $output, $results->{deflate}, $width )
        if $benchmark_deflate;

    output( 'Inflate', "time", $output, $results->{inflate}, $width )
        if $benchmark_inflate;
}

sub output {
    my $title  = shift;
    my $type   = shift;
    my $output = shift;
    printf( "\n%s\n", $title );
    if ( $type eq "size" ) {
        ($output eq "list") ? &size_list : &size_chart ; 
    } elsif ( $type eq "time" ) {
        ($output eq "list") ? &time_list : &time_chart ; 

    } else {
        warn("Unknown data type: $type");
    }
}

sub time_chart {
    my $results = shift;
    Benchmark::cmpthese($results);
}

sub time_list {
    my $results = shift;
    my $width   = shift;
    foreach my $title ( sort keys %{ $results } ) {
        printf( "%-${width}s %s\n", $title, timestr( $results->{ $title } ) );
    }
}

sub size_chart {
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

sub size_list {
    my $results = shift;
    my $width   = shift;
    foreach my $title ( sort keys %{ $results } ) {
        printf( "%-${width}s : %d bytes\n", $title, $results->{ $title } );
    }
}

sub timeit_deflate {
    my ( $iterations, $structure, $benchmark ) = @_;
    my $deflate = $benchmark->{deflate};
    return Benchmark::timethis( $iterations, sub { &$deflate($structure) }, '', 'none' );
}

sub timeit_inflate {
    my ( $iterations, $structure, $benchmark ) = @_;
    my $inflate = $benchmark->{inflate};
    my $deflated = $benchmark->{deflate}->($structure);
    return Benchmark::timethis( $iterations, sub { &$inflate($deflated)  }, '', 'none' );
}

sub width {
    return length( ( sort { length $a <=> length $b } @_ )[-1] );
}

=head1 RESULTS

See the README file for example results.

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

1;
