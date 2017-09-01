#!/usr/bin/perl

# sort_to_dirs
# Copyleft (ↄ) 2011
# Z. Cliffe Schreuders

# Moves all files into directories based on their filenames (excluding extensions)


use warnings;
use strict;
use File::Glob ':glob';
use File::Copy;

my ($src, $dest) = @ARGV;
if(!$src || !$dest) {
	print "Using current directory\n";
	$src = $dest = '.';
}

# append a trailing / if it's not there
$src .= '/' if($src !~ /\/$/);
$dest .= '/' if($dest !~ /\/$/);

foreach my $file(bsd_glob("$src*")) {
	if(-r $file) {
		my $newdir = filename($file);
		if($newdir =~ s/(.*)\..*/$1/g) {
			mkdir "$dest$newdir";
			print "moving $file to $dest$newdir/".filename($file)."\n";
			move $file, "$dest$newdir/".filename($file);
		}
	}
}

# removes path
sub filename {
	my ($title) = @_;
	$title =~ s/(.*\/)(.*)/$2/;
	return $title;
}
