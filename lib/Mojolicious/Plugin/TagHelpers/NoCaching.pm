package Mojolicious::Plugin::TagHelpers::NoCaching;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::URL;
use Mojo::Path;

sub register {
	my ($plugin, $app, $cfg) = @_;
	
	$cfg->{key} = 'nc' unless defined $cfg->{key};
	
	$plugin->{url2path} = {};
	$plugin->{path2key} = {};
	$plugin->{cfg}      = $cfg;
	
	$app->helper(stylesheet_nc => sub {
		my $self = shift;
		
		if (@_ % 2) {
			# this is css url
			my $href = $plugin->_nc_href($self, shift);
			unshift @_, $href;
		}
		
		$self->stylesheet(@_);
	});
	
	$app->helper(javascript_nc => sub {
		my $self = shift;
		
		if (@_ % 2) {
			# this is script url
			my $href = $plugin->_nc_href($self, shift);
			unshift @_, $href;
		}
		
		$self->javascript(@_);
	});
	
	$app->helper(image_nc => sub {
		my $self = shift;
		
		my $href = $plugin->_nc_href($self, shift);
		unshift @_, $href;
		
		$self->image(@_);
	});
}

sub _href2filepath {
	my ($controller, $href) = @_;
	
	if ($href =~ m!^[a-z]+://!i) {
		my $url   = Mojo::URL->new($href);
		my $c_url = $controller->req->url->to_abs;
		
		if ($url->host ne $c_url->host) {
			# external url
			return;
		}
		
		$href = $url->path;
	}
	else {
		# remove any query parameters
		$href =~ s/\?.+//;
		
		if ($href !~ m!^/!) {
			# relative url
			$href = Mojo::Path->new($controller->req->url->path)->to_dir . $href;
		}
	}
	
	my $static =$controller->app->static;
	my $asset = $static->file($href)
		or return;
	
	$asset->is_file
		or return;
	
	my $path = Mojo::Path->new($asset->path)->canonicalize;
	my $ok;
	for my $p (@{$static->paths}) {
		$ok = $path->contains($p)
			and last;
	}
	# check is found file is inside public directory
	$ok or return;
	
	return $path;
}

sub _nc_key {
	my ($self, $path) = @_;
	return (stat($path))[9];
}

sub _nc_href {
	my ($self, $controller, $href) = @_;
	
	unless (exists $self->{url2path}{$href}) {
		$self->{url2path}{$href} = _href2filepath($controller, $href);
	}
	
	my $path = $self->{url2path}{$href}
		or return $href;
	
	unless (exists $self->{path2key}{$path}) {
		$self->{path2key}{$path} = $self->_nc_key($path);
	}
	
	my $key = $self->{path2key}{$path}
		or return $href;
	
	$href .= index($href, '?') == -1 ?  '?' : '&';
	$href .= $self->{cfg}{key} . '=' . $key;
	
	# fix for https://github.com/kraih/mojo/issues/565
	return Mojo::URL->new($href);
}

1;
