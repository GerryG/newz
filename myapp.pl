#!/usr/bin/env perl

#use lib '/Users/phillipadsmith/perl5/lib/perl5';
#use lib '/usr/local/lib/perl5/5.12.1/';
#use lib '/usr/local/lib/perl5/site_perl/5.12.1/';

#use feature ':5.10';
#use 5.012; # automatically turns on strict
use Image::Grab;
use GD;
use Image::Magick;

use Mojolicious::Lite;

get '/' => 'index';

post '/add_caption' => sub {
	my $self = shift;

	my $caption = $self->param('caption') || 'I Can Has Newz?';
	my $img_url = $self->param('img_url') || 'http://...';
	my $img_name;

	$caption =~ s/[^\w\s]+//g;

	#$image = _get_image( $img_url, $img_name );
	my $obj = {};
	&create($obj,$img_url, $caption, 'bl', "impact.ttf");

	$self->render(
		template => 'welcome',
		layout   => 'caption',
		caption   => $caption,
		img_url   => $img_url,
	);
} => 'add_caption';

sub create {
my ($this,$image,$text,$align,$font,
    $fontsize,$resize_width, $padding, $text_color, $shadow_color)
         = (shift,shift,shift,shift,shift,
            shift||15, shift || 0, shift||5, shift||-1, shift||-1);
my (@align, $c, $dbg, $font_height, $i, $inc, $left, $lf_width,
$line_beginning, $line_width, $row_spacing, $space_width, @text_elements,
$text_elements, $top);

	$$this{img} = undef;
	#ErrorHandler,

	# second, make sure its an image
	my ($width, $height, $attr);
	if (!(list($width, $height, $$this{imgtype}, $attr) = Image::Magick::Ping($image))) {
		&error("Error: Cannot get parameters of specified image,");
	}

	# ensure position is correct
	if (!grep($align==$_,('tl','tr','bl','br'))) {
		$align = 'tl';
	}

	# fix up the font size
	$fontsize =~ s/\s*(.*)(px)?\s*/$1/;
	if ($fontsize == '' || !is_int($fontsize)) {
		$fontsize = 15;
		&error("Error: Invalid font specified!,");
	}

	if ($$this{imgtype} == 1) {		# gif
		$$this{img} = imagecreatefromgif($image);
	} elsif ($$this{imgtype} == 2) {		# jpg
		$$this{img} = imagecreatefromjpeg($image);
	} elsif ($$this{imgtype} == 3) {		# png
		$$this{img} = imagecreatefrompng($image);
	} else { } # i don't care about other formats'

	if (!$$this{img}) {
		&error("Error: Cannot use specified image");
	}

	# see if we need to resize the image first
	if ($resize_width != 0){

		# todo: Add a 'max-width, max-height' parameter... 
		my $ratio = $width / $resize_width;
		my $resize_height = int($height / $ratio);

		my $thumb_img = imagecreatetruecolor($resize_width, $resize_height);
		if (!imagecopyresampled($thumb_img, $$this{img}, 0, 0, 0, 0, $resize_width, $resize_height, $width, $height)) {
			&error("Error: Could not resize image!");
		}

		# fix these
		$height = $resize_height;
		$width = $resize_width;

		# destroy original object
		imagedestroy($$this{img});
		$$this{img} = $thumb_img;
	}

	# allocate colors for text
	if ($text_color == -1) {
		$text_color = $$this{img}->colorAllocate(255, 255, 255);
	} elsif ((ref $text_color) == "ARRAY") {
		$text_color = $$this{img}->colorAllocate($$text_color[0], $$text_color[1], $$text_color[2]);
	}

	# allocate colors for text shadow
	if ($shadow_color == -1) {
		$shadow_color = $$this{img}->colorAllocate(0, 0, 0);
	} elsif ((ref $text_color) == "ARRAY") {
		$shadow_color = $$this{img}->colorAllocate( $$shadow_color[0], $$shadow_color[1], $$shadow_color[2]);
	}

	# next, we should try to create the text.. hopefully it wraps nicely
	$ENV{'GDFONTPATH'} = `pwd`;		# hack, just in case

	# grab the font height, M is supposed to be big, with any random chars lying around
	($font_height, $space_width) = $this->img_size($fontsize,$font);
	$row_spacing = int($font_height * .2);	# purely arbitrary value


	# try and do our best imitation of wordwrapping
	$text =~ s/\r?\n//g;
	@text_elements = split(' ',$text);

	# adjust this depending on alignment
	$top = $padding + $font_height;
	$left = $padding;

	# initialize
	$line_width = 0;
	$line_beginning = 0;		# index of beginning of line
	$inc = 1;
	$c = $#text_elements+1;
	$i = 0;

	if ($align[0] == 'b'){
		$top = $height - $padding;
		$font_height = $font_height * -1;
		$row_spacing  = $row_spacing * -1;
		$inc = -1;
		$i = $c -1;
	}

	$dbg = get_get_var('dbg');
	$line_beginning = $i;

	# draw text elements starting from alignment position.. 
	for (;$i >= 0 && $i < $c;$i += $inc){

		$lf_width = $this->img_width(imagettfbbox($fontsize,0,$font,$text_elements[$i]));

		# add a space
		if ($i != $line_beginning) {
			$lf_width += $space_width;
		}

		# see if we've exceeded the max width
		if ($lf_width + $line_width + $padding * 2 > $width){

			# draw it out then!
			if (substr($align,1,1) == 'r') {
				$left = $width - $padding - $line_width;
			}

			if (substr($align,0,1) == 'b') {
				$text = join(' ',@text_elements[$i+1..$line_beginning-$i]);
			} else {
				$text = join(' ',@text_elements[$line_beginning..$i - $line_beginning]);
			}

			# draw the text
			imagettftext($this->img,$fontsize,0,$left-1,$top+1,$shadow_color,$font,$text);
			imagettftext($this->img,$fontsize,0,$left,$top,$text_color,$font,$text);

			# keep moving, reset params
			$top += $font_height + $row_spacing;
			$line_beginning = $i;
			$line_width = $lf_width;

		}else{
			# keep trucking
			$line_width += $lf_width;
		}
	}

	# get the last line too
	if ($line_width != 0){
		if ($align[1] == 'r') {
			$left = $width - $padding - $line_width;
		}

		if ($align[0] == 'b') {
			$text = implode(' ',array_slice($text_elements,$i+1,$line_beginning-$i));
		} else {
			$text = implode(' ',array_slice($text_elements,$line_beginning,$i - $line_beginning));
		}

		imagettftext($this->img,$fontsize,0,$left-1,$top+1,$shadow_color,$font,$text);
		imagettftext($this->img,$fontsize,0,$left,$top,$text_color,$font,$text);
	}

	imagecolordeallocate($this->img,$shadow_color);
	imagecolordeallocate($this->img,$text_color);

	restore_error_handler();

	return 1;
}

# utility functions
sub img_size {
my ($fontsize, $font) = (shift, shift);
	my $h = int($fontsize*1.2);
	#imagettfbbox($fontsize,0,$font,'Mjg')
        #$h = abs(max($sz_array[0] - $sz_array[2], $sz_array[4] - $sz_array[6]));
	my $w = int($fontsize*9);
	#imagettfbbox($fontsize,0,$font,' ')
        #$w = abs(max($sz_array[7] - $sz_array[1], $sz_array[5] - $sz_array[3]));
	($h, $w);
}

sub _get_image_and_save {

    my $file = $_[1] || 'image.jpg'; 
    my $pic = new Image::Grab;
    $pic->url( $_[0] );
    $pic->grab;
    # Now to save the image to disk
	open(IMAGE, ">$file");
    binmode IMAGE;  # for MSDOS derivations.
    print IMAGE $pic->image;
    close IMAGE;
    return $file;
}

sub _write_caption_to_image {}

sub _output_image_to_fs {}



app->start;

__DATA__

@@ index.html.ep
% layout 'caption';
<img src="http://localhost:8080/newz/cat.jpg" /><br />
URL is: http://localhost:8080/newz/cat.jpg
<br />
<%= form_for add_caption => (method => 'post') => {%>
Image URL
<%= input 'img_url', type => 'text' %>
<br />
What's your caption?
<%= input 'caption', type => 'text' %>
<input type="submit" value="Add caption" />
<%}%>

@@ welcome.html.ep
Photo with this caption: <%= $caption %>
And this url: <%= $img_url %>
<%= include 'menu' %>

@@ menu.html.ep
<%= link_to index => {%>
Try again
<%}%>

@@ layouts/caption.html.ep
<!doctype html><html>
<head><title>I Can Has Newz?</title></head>
<body><%= content %>
</body>
</html>