#!/usr/bin/env perl

use lib '/Users/phillipadsmith/perl5/lib/perl5';
use lib '/usr/local/lib/perl5/5.12.1/';
use lib '/usr/local/lib/perl5/site_perl/5.12.1/';

use feature ':5.10';
use 5.012; # automatically turns on strict
use Image::Grab;


use Mojolicious::Lite;

get '/' => 'index';

post '/add_caption' => sub {
	my $self = shift;

	my $caption = $self->param('caption') || 'I Can Has Newz?';
	my $img_url = $self->param('img_url') || 'http://...';
	my $img_name;
	
	$caption =~ s/[^\w\s]+//g;

	_get_image_and_save( $img_url, $img_name );

	$self->render(
		template => 'welcome',
		layout   => 'caption',
		caption   => $caption,
		img_url   => $img_url,
	);
} => 'add_caption';

sub _get_image_and_save {
	
    my $file = $_[1] || 'image.jpg'; 
    my $pic = new Image::Grab;
    $pic->url( $_[0] );
    $pic->grab;
    # Now to save the image to disk
    open(IMAGE, ">$file") || die "$file: $!";
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