#!/usr/bin/perl

# move_dupe_names
# Copyleft (ↄ) 2011
# Z. Cliffe Schreuders

# Searches two directories and moves dupes (by name) to another location
# Supply three directories: directory to remove dupes, dir to compare, destination for dupes.


use File::Copy;
use File::Glob ':glob';
use warnings;
use strict;

my ($dir_src, $dir2_compare, $dir_dest_for_dupes) = @ARGV;
unless (@ARGV == 3 && -e $dir_src && -e $dir2_compare && -e $dir_dest_for_dupes) {
	print "Usage: supply three directories...\n";
	print "Directory to remove dupes, dir to compare, destination for dupes.\n";
	exit(1);
}

# append a trailing / if it's not there
$dir_src .= '/' if($dir_src !~ /\/$/);
$dir2_compare .= '/' if($dir2_compare !~ /\/$/);
$dir_dest_for_dupes .= '/' if($dir_dest_for_dupes !~ /\/$/);

foreach my $src(bsd_glob("$dir_src*")) {
	my $name1 = filename($src);
	foreach my $src2(bsd_glob("$dir2_compare*")) {
		my $name2 = filename($src2);
		if($name1 eq $name2) {
			print "moving dupe ($src) to $dir_dest_for_dupes".filename($name2)."\n";
			move $src, "$dir_dest_for_dupes".filename($src);
		}
	}
}

# removes path
sub filename {
	my ($title) = @_;
	$title =~ s/(.*\/)(.*)/$2/;
	return $title;
}
