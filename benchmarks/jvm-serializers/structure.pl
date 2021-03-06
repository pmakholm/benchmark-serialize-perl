# The standard test value.
{
	media => {
		uri => "http://javaone.com/keynote.mpg",
		title => "Javaone Keynote",
		width => 640,
		height => 480,
		format => "video/mpg4",
		duration => 18000000,    # half hour in milliseconds
		size => 58982400,        # bitrate * duration in seconds / 8 bits per byte
		bitrate => 262144,  # 256k
		person => ["Bill Gates", "Steve Jobs"],
		player => 0,
		copyright => "None",
	},

	image => [
		{
			uri => "http://javaone.com/keynote_large.jpg",
			title => "Javaone Keynote",
			width => 1024,
			height => 768,
			size => 1,
		},
		{
			uri => "http://javaone.com/keynote_small.jpg",
			title => "Javaone Keynote",
			width => 320,
			height => 240,
			size => 0,
		}
	]
}
