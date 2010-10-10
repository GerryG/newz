#!/usr/bin/env perl

use Image::Grab;
use Image::Magick;

my %gravity = (
	tl => "NorthWest",
	tr => "NorthEast",
	bl => "SouthWest",
	br => "SouthEast",
);

	my $self = shift;

	my $caption = 'I Can Has Newz?';
	my $img_url = 'http://...';
	my $img_name = 'image.jpg';

	$caption =~ s/[^\w\s]+//g;

	my $image = _load_image( $img_name );
	#die("Annote1: text => $text, gravity => $gravity{$align}, font => $font, fill => $text_color");
	$image->Annotate(text => $caption, gravity => "SoutWest", font => 'impact.ttf', fill => 'green', pointsize => 40);
	_write_image($image, $img_name);

# utility functions
sub _img_size {
my ($fontsize, $font) = (shift, shift);
	my $h = int($fontsize*1.2);
	#imagettfbbox($fontsize,0,$font,'Mjg')
        #$h = abs(max($sz_array[0] - $sz_array[2], $sz_array[4] - $sz_array[6]));
	my $w = int($fontsize*9);
	#imagettfbbox($fontsize,0,$font,' ')
        #$w = abs(max($sz_array[7] - $sz_array[1], $sz_array[5] - $sz_array[3]));
	($h, $w);
}

sub _load_image {
my $file = shift;
my $im = Image::Magick->new;
	die ("Image? $file I:$im") unless (defined($im) && defined($file));
	$im->ReadImage($file);
	$im;
}

sub _get_image {
	my $pic = new Image::Grab;
	$pic->url( shift );
	$pic->grab;
	$pic;
}

sub _write_image {
	my $file = $_[1] || 'image.jpg'; 
	my $image = $_[0];
	$file =~ s/\.(\w+)/_out.$1/;
	# Now to save the image to disk
	#open(IMAGE, ">$file");
	#binmode IMAGE;  # for MSDOS derivations.
	#print IMAGE $_[0];
	#close IMAGE;
	$image->Write($file);
	return $file;
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
