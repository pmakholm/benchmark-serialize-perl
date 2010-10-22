use JSON::XS;
use File::Slurp;

JSON::XS->new()->pretty(1)->decode( scalar read_file( "google-data/pretty.json" ) );
