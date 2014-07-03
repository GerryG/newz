#!/usr/bin/env perl

#use lib '/Users/phillipadsmith/perl5/lib/perl5';
#use lib '/usr/local/lib/perl5/5.12.1/';
#use lib '/usr/local/lib/perl5/site_perl/5.12.1/';

use feature ':5.10';
use 5.012; # automatically turns on strict
use Image::Grab;
use Image::Magick;
use MIME::Base64 qw(encode_base64);
use File::Temp qw/ tempfile tempdir /;

use Mojolicious::Lite;

my %gravity = (
	tl => "NorthWest",
	tr => "NorthEast",
	bl => "SouthWest",
	br => "SouthEast",
);

get '/' => 'index';

post '/add_caption' => sub {
	my $self = shift;

	my $caption = $self->param('caption') || 'I Can Has Newz?';
	my $img_url = $self->param('img_url') || 'http://...';
	my $img_name;
  	
  	my($text, $image, $x,);

	$caption =~ s/[^\w\s]+//g;

   my $file =  _get_image_and_save( $img_url, undef );

  $image = Image::Magick->new;
  $x = $image->Read("$file");
  warn "$x" if "$x";

  uc($text = "$caption");
  
  $image->Annotate(font=>'impact.ttf', pointsize=>40, fill=>'white', stroke => 'black', strokewidth => '1', text=>$text, x=> '40', y => '40');
    
  $x = $image->Write("public/$file.jpg");
   warn "$x" if "$x";
	
	$self->render(
		template => 'welcome',
		layout   => 'caption',
		caption   => $caption,
		img_url   => $img_url,
		file	  => $file,
	);
} => 'add_caption';

sub _get_image_and_save {
	my $rand_name = rand() * 1000;
	my $filename = $_[1] || $rand_name;
    my $pic = new Image::Grab;
    $pic->url( $_[0] );
    $pic->grab;
    # Now to save the image to disk
	open(IMAGE, ">$filename");
    binmode IMAGE;  # for MSDOS derivations.
    print IMAGE $pic->image;
    close IMAGE;
    return $filename;
}

app->start;

__DATA__

@@ index.html.ep
% layout 'caption';
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
<img src="/<%= $file %>.jpg" />
<br /><br />
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
