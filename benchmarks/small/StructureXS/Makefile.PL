use ExtUtils::MakeMaker;

$CC = 'g++';

# Generate the C++, XS, and Perl files that we need.

my $protoxs = "protoxs --cpp_out=. --out=. structure.proto";

print "Generating C++ and Perl/XS sources...\n";
print "$protoxs\n";

`$protoxs`;

# Now write the Makefile.

WriteMakefile(
              'NAME'          => 'StructureXS',
              'VERSION_FROM'  => 'StructureXS.pm',
              'OPTIMIZE'      => '-O2 -Wall',
              'CC'            => $CC,
              'LD'            => '$(CC)',
              'CCFLAGS'       => '-fno-strict-aliasing',
              'OBJECT'        => 'structure.pb.o StructureXS.o',
              'INC'           =>  "",
              'LIBS'          => [" -lprotobuf"],
              'XSOPT'         => '-C++',
              clean           => { FILES => "StructureXS.* structure.pb.* lib" }
             );

