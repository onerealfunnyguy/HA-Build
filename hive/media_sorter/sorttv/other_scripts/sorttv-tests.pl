#!/usr/bin/perl

# SortTV tests
# Copyleft (ↄ) 2012
# Z. Cliffe Schreuders

# Some tests for SortTV...

# WARNING: If you have an unusual sorttv.conf it may affect this script's ability to do the tests
# If you have played with the settings, and this script is reporting errors,
#  just move your config file out of the way before running this testing script

# This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

# Note, this does not test everything: for example, extraction of compressed files

use warnings;
use strict;

use File::Path qw(make_path);
use File::Spec::Functions "rel2abs";
use File::Basename;
use File::Path;
use FileHandle;

my $scriptpath = dirname(rel2abs($0));
my $test_directory = "$scriptpath/test_directory";
my $to_sort = "$scriptpath/test_directory/sort";
my $tv_dir = "$scriptpath/test_directory/TV";
my $movie_dir = "$scriptpath/test_directory/Movies";
my $misc_dir = "$scriptpath/test_directory/Misc";
my $music_dir = "$scriptpath/test_directory/Music";
my $log_file = "$scriptpath/test.log";

my $failed_count = my $passed_count = 0;
my $standard_renaming = "\"--rename-tv-format=[SHOW_NAME] - [EP1]\" --rename-media=TRUE";
my $standard_tvdb_renaming = "\"--rename-tv-format=[SHOW_NAME] - [EP1][EP_NAME1]\" --rename-media=TRUE";
my $movie_rename = "\"--rename-tv-format=[MOVIE_TITLE] [YEAR2]/[MOVIE_TITLE] [YEAR1]\"";

my $logfile = "$scriptpath/test-status.log";
my $log;

{
	# initialise output
	$log = FileHandle->new("$logfile", "a") or out("warn", "WARN: Could not open log file $logfile: $!\n");
	out("Testing SortTV\n", "~" x 6,"\n");
	display_time();
	out("Operating system: $^O\n");

	# here we list all the tests

	test_sorttv("TV regex (no network)",
		"--no-network $standard_renaming", 
		"test/Pioneer One Season 1 Episode 1.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01.avi",
		"Pioneer One 1x2.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E02.avi",
		"Pioneer One/Season 1/2.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E02.avi",
		"Pioneer One/Season 1/s1e2.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E02.avi",
		"Pioneer One 102.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E02.avi",
		"Pioneer One - 102.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E02.avi",
		"Pioneer One 1-2.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E02.avi",
		"Pioneer One/Season 1/102.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E02.avi",
		"Pioneer One S1E2.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E02.avi",
		);

	test_sorttv("thetvdb naming",
		"--fetch-tv-images=NEW_SHOWS $standard_tvdb_renaming",
		"Pioneer One Season 1 Episode 1.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01 - Earthfall.avi",
		);

	test_sorttv("thetvdb image downloads (expected to fail on Windows)",
		"--fetch-tv-images=NEW_SHOWS $standard_tvdb_renaming",
		"Pioneer One Season 1 Episode 1.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01 - Earthfall.tbn;$tv_dir/Pioneer One/folder.jpg;$tv_dir/Pioneer One/fanart.jpg;$tv_dir/Pioneer One/banner.jpg;$tv_dir/Pioneer One/season01.jpg;$tv_dir/Pioneer One/Season 1/folder.jpg",
		);

	test_sorttv("substitutions (w/tvdb)",
		"\"--show-name-substitute=lalala-->Pioneer One\" $standard_tvdb_renaming", 
		"lalala 1x1.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01 - Earthfall.avi",
		);

	test_sorttv("delete",
		"--delete=*.avi --no-network $standard_renaming", 
		"Show 1x1.avi"=>"!$tv_dir/Show/Season 1/Show - S01E01.avi;!$to_sort/Show 1x1.avi",
		);

	test_sorttv("ignore",
		"--ignore=*.avi --no-network $standard_renaming", 
		"Show 1x1.avi"=>"!$tv_dir/Show/Season 1/Show - S01E01.avi;$to_sort/Show 1x1.avi",
		);

	test_sorttv("consider file extensions, with exceptions",
		"--consider-media-file-extensions=TRUE --non-media-extension=mpg --no-network $standard_renaming", 
		"Show 1x1.avi"=>"$tv_dir/Show/Season 1/Show - S01E01.avi",
		"Show 1x2.ava"=>"!$tv_dir/Show/Season 1/Show - S01E02.ava;$misc_dir/Show 1x2.ava",
		"Show 1x3.mpg"=>"!$tv_dir/Show/Season 1/Show - S01E02.mpg;$misc_dir/Show 1x3.mpg",
		);

	test_sorttv("not considering file extensions, with exceptions",
		"--consider-media-file-extensions=FALSE --non-media-extension=jpg --no-network $standard_renaming", 
		"Show 1x1.ava"=>"$tv_dir/Show/Season 1/Show - S01E01.ava",
		"Show 1x2.jpg"=>"!$tv_dir/Show/Season 1/Show - S01E02.jpg;$misc_dir/Show 1x2.jpg",
		);

	test_sorttv("file size out of range",
		"--filesize-range=170MB-400MB --no-network $standard_renaming",
		"Show 1x1.avi"=>"!$tv_dir/Show/Season 1/Show - S01E01.avi;$to_sort/Show 1x1.avi",
		);

	test_sorttv("file size in range",
		"--filesize-range=0MB-400MB --no-network $standard_renaming",
		"Show 1x1.avi"=>"$tv_dir/Show/Season 1/Show - S01E01.avi",
		);

	test_sorttv("file age too new",
		"--sort-only-older-than-days=1 --no-network $standard_renaming",
		"Show 1x1.avi"=>"!$tv_dir/Show/Season 1/Show - S01E01.avi;$to_sort/Show 1x1.avi",
		);

	test_sorttv("no renaming",
		"--rename-media=FALSE",
		"Show 1x1.avi"=>"$tv_dir/Show/Season 1/Show 1x1.avi",
		);

	test_sorttv("TV renaming 1x1",
		"\"--rename-tv-format=[SHOW_NAME] ~ [EP2]\" --rename-media=TRUE --no-network",
		"Show 1x1.avi"=>"$tv_dir/Show/Season 1/Show ~ 1x1.avi",
		);

	test_sorttv("TV renaming 1x01",
		"\"--rename-tv-format=[SHOW_NAME] ~ [EP3]\" --rename-media=TRUE --no-network",
		"Show 1x1.avi"=>"$tv_dir/Show/Season 1/Show ~ 1x01.avi",
		);

	test_sorttv("TV renaming 01 w/quality",
		"\"--rename-tv-format=[EP4][QUALITY]\" --rename-media=TRUE --no-network",
		"Show 1x1.avi"=>"$tv_dir/Show/Season 1/01.avi",
		"Show 1x1 1080p.avi"=>"$tv_dir/Show/Season 1/01 HD.avi",
		"Show 1x1 DVDRip.avi"=>"$tv_dir/Show/Season 1/01 SD.avi",
		"Show 1x1 Bluray.avi"=>"$tv_dir/Show/Season 1/01 HD.avi",
		);

	test_sorttv("rename with dots",
		"--use-dots-instead-of-spaces=TRUE --no-network $standard_renaming", 
		"test/Pioneer One Season 1 Episode 1.avi"=>"$tv_dir/Pioneer.One/Season.1/Pioneer.One.-.S01E01.avi",
		);

	test_sorttv("no season directories",
		"--use-season-directories=FALSE --no-network $standard_renaming", 
		"test/Pioneer One Season 1 Episode 1.avi"=>"$tv_dir/Pioneer One/Pioneer One - S01E01.avi",
		);

	test_sorttv("season directory naming",
		"\"--season-title=Series.\" --season-double-digits=TRUE --no-network $standard_renaming", 
		"test/Pioneer One Season 1 Episode 1.avi"=>"$tv_dir/Pioneer One/Series.01/Pioneer One - S01E01.avi",
		);

	test_sorttv("tvdb matches",
		"--match-files-based-on-tvdb-lookups=TRUE $standard_tvdb_renaming", 
		"test/Pioneer One - Earthfall.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01 - Earthfall.avi",
		"test/Pioneer One 2010-06-16.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01 - Earthfall.avi",
		"test/Pioneer One - 2010-06-16.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01 - Earthfall.avi",
		);

	test_sorttv("tvdb id substitute",
		"\"--tvdb-id-substitute:test-->83949\" $standard_renaming", 
		"test s1e1.avi"=>"$tv_dir/The Guild/Season 1/The Guild - S01E01.avi",
		);

	test_sorttv("sort by copy",
		"--sort-by=COPY $standard_renaming --no-network", 
		"test/Pioneer One s1e1.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01.avi;$to_sort/test/Pioneer One s1e1.avi",
		);

	test_sorttv("sort by hard link (expected to fail on Windows)",
		"--sort-by=PLACE-HARDLINK $standard_renaming --no-network", 
		"test/Pioneer One s1e1.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01.avi;$to_sort/test/Pioneer One s1e1.avi",
		);

	test_sorttv("sort by move",
		"--sort-by=MOVE $standard_renaming --no-network", 
		"test/Pioneer One s1e1.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01.avi;!$to_sort/test/Pioneer One s1e1.avi",
		);

	test_sorttv("sort by place symlink (expected to fail on Windows)",
		"--sort-by=PLACE-SYMLINK $standard_renaming --no-network", 
		"test/Pioneer One s1e1.avi"=>"*$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01.avi;$to_sort/test/Pioneer One s1e1.avi",
		);

	test_sorttv("sort by replace with symlink (expected to fail on Windows)",
		"--sort-by=MOVE-AND-LEAVE-SYMLINK-BEHIND $standard_renaming --no-network", 
		"test/Pioneer One s1e1.avi"=>"$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01.avi;*$to_sort/test/Pioneer One s1e1.avi",
		);

	test_sorttv("ignore dirs",
		"--treat-directories=IGNORE $standard_renaming --no-network", 
		"test/Pioneer One s1e1.avi"=>"!$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01.avi;$to_sort/test/Pioneer One s1e1.avi",
		);

	test_sorttv("TV season directory as a file to sort",
		"--treat-directories=AS_FILES_TO_SORT $standard_renaming --no-network", 
		"Pioneer One Season 1/test.avi"=>"$tv_dir/Pioneer One/Season 1/test.avi",
		"test/Pioneer One Season 1/test.avi"=>"$misc_dir/test/Pioneer One Season 1/test.avi",
		);

	test_sorttv("movie directory as a file to sort",
		"--treat-directories=AS_FILES_TO_SORT $movie_rename", 
		"RIP: A Remix Manifesto/test.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/test.avi",
		);

	test_sorttv("movie directory as a file to sort (based on sort-movie-directories)",
		"$movie_rename --sort-movie-directories=TRUE", 
		"RIP: A Remix Manifesto/test.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/test.avi",
		);

	test_sorttv("require-show-directories-already-exist, when they don't",
		"--require-show-directories-already-exist=TRUE $standard_renaming --no-network", 
		"Pioneer One s1e1.avi"=>"!$tv_dir/Pioneer One/Season 1/Pioneer One - S01E01.avi",
		);

	test_sorttv("Windows file names",
		"--force-windows-compatible-filenames=TRUE $standard_renaming --no-network", 
		"A*@ s1e1.avi"=>"$tv_dir/A-\@/Season 1/A-@ - S01E01.avi",
		);

	test_sorttv("Unix file names (expected to fail on Windows)",
		"--force-windows-compatible-filenames=FALSE $standard_renaming --no-network", 
		"A*@ s1e1.avi"=>"$tv_dir/A*\@/Season 1/A*@ - S01E01.avi",
		);

	test_sorttv("flatten-non-eps",
		"--flatten-non-eps=TRUE $standard_renaming --no-network", 
		"test/test/thisisatest.txt"=>"$misc_dir/test-test-thisisatest.txt",
		);

	test_sorttv("not flatten-non-eps",
		"--flatten-non-eps=FALSE $standard_renaming --no-network", 
		"test/test/thisisatest.txt"=>"$misc_dir/test/test/thisisatest.txt",
		);

	test_sorttv("tvdb episode name required, but none available",
		"--tvdb-episode-name-required=TRUE $standard_tvdb_renaming", 
		"Pioneer One Season 1 Episode 10.avi"=>"!$tv_dir/Pioneer One/Season 1/Pioneer One - S01E10.avi",
		);

	test_sorttv("movie sorting into subdirectory, with no image downloads",
		"$movie_rename  --rename-media=TRUE --fetch-movie-images=FALSE", 
		"RIP: A Remix Manifesto.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi;!$movie_dir/RiP!- A Remix Manifesto 2009/folder.jpg",
		);

	test_sorttv("movie renaming format",
		"\"--rename-movie-format=[MOVIE_TITLE] [YEAR2]\" --rename-media=TRUE --fetch-movie-images=FALSE", 
		"RIP: A Remix Manifesto.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009.avi",
		);

	test_sorttv("movie sorting, with year margin of error (1)",
		"$movie_rename  --year-tolerance-for-error=1 --rename-media=TRUE --fetch-movie-images=FALSE", 
		"RIP: A Remix Manifesto 2011.avi"=>"!$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		"RIP: A Remix Manifesto 2010.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		"RIP: A Remix Manifesto 2009.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		"RIP: A Remix Manifesto 2008.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		"RIP: A Remix Manifesto 2007.avi"=>"!$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		);

	test_sorttv("movie sorting, with year margin of error (2)",
		"$movie_rename  --year-tolerance-for-error=2 --rename-media=TRUE --fetch-movie-images=FALSE", 
		"RIP: A Remix Manifesto 2012.avi"=>"!$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		"RIP: A Remix Manifesto 2011.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		"RIP: A Remix Manifesto 2010.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		"RIP: A Remix Manifesto 2009.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		"RIP: A Remix Manifesto 2008.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		"RIP: A Remix Manifesto 2007.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/RiP!- A Remix Manifesto (2009).avi",
		);

	test_sorttv("movie renaming w/quality",
		"\"--rename-movie-format=[MOVIE_TITLE] [YEAR2][QUALITY]\" --rename-media=TRUE --fetch-movie-images=FALSE",
		"RIP: A Remix Manifesto DVD.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009 SD.avi",
		);

	test_sorttv("movie renaming w/rating",
		"\"--rename-movie-format=[MOVIE_TITLE] [YEAR2] [RATING]\" --rename-media=TRUE --fetch-movie-images=FALSE",
		"RIP: A Remix Manifesto DVD.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009 NR.avi",
		"Night of the Living Dead.avi"=>"$movie_dir/Night of the Living Dead 1968 R.avi",
		);

	test_sorttv("sort movie without renaming",
		"--rename-media=FALSE --fetch-movie-images=FALSE", 
		"RIP: A Remix Manifesto DVD.avi"=>"$movie_dir/RIP: A Remix Manifesto DVD.avi",
		);

	test_sorttv("movie images downloads into subdirectory",
		"$movie_rename --fetch-movie-images=TRUE", 
		"RIP: A Remix Manifesto.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009/fanart.jpg;$movie_dir/RiP!- A Remix Manifesto 2009/folder.jpg;$movie_dir/RiP!- A Remix Manifesto 2009/movie.tbn",
		);

	test_sorttv("movie images downloads into same directory",
		"\"--rename-movie-format=[MOVIE_TITLE] [YEAR2]\" --rename-media=TRUE --fetch-movie-images=TRUE", 
		"RIP: A Remix Manifesto.avi"=>"$movie_dir/RiP!- A Remix Manifesto 2009.tbn;$movie_dir/RiP!- A Remix Manifesto 2009.jpg;$movie_dir/RiP!- A Remix Manifesto 2009-fanart.jpg",
		);

	test_sorttv("music files",
		"", 
		"My Music - test.mp3"=>"$music_dir/My Music - test.mp3",
		"test/My Music - test.mp3"=>"$music_dir/test/My Music - test.mp3",
		);

	out("~~~\nAll tests complete:\n$passed_count tests passed\n$failed_count tests failed\n");

	exit;
}

# conducts a test
# arguments:
# 1: the description of the test
# 2: options for SortTV
# 3: the file to start with
# 4: and the files that result (separated by ;)
#    files starting with ! indicate that the file should NOT exist after the sort
#    files starting with * indicate that the file should be a symlink
sub test_sorttv {
	my ($testing, $command, %files) = @_;
	out("~~~\nTesting: $testing...\n");
	foreach my $file (keys %files) {
		make_paths();
		my $mkdir = "$to_sort/".path($file);
		make_path($mkdir);
		
		out("\tCreating $to_sort/$file\n");
		create_file("$to_sort/$file");
		
		my $run = "perl ../sorttv.pl --directory-to-sort=$to_sort --tv-directory=$tv_dir --movie-directory=$movie_dir --music-directory=$music_dir --misc-dir=$misc_dir --sort-by=MOVE --treat-directories=RECURSIVELY_SORT_CONTENTS --log-file=$log_file --force-windows-compatible-filenames=TRUE $command";
		out("\tRunning: $run\n");
		system $run;
		my @results = split ';', $files{$file};
		print("--\nTesting $testing:\n");
		foreach (@results) {
			# files starting with ! indicate that the file should NOT exist after the sort
			my $message = "";
			if($_ =~ /^!/) {
				$message = "not ";
			} elsif($_ =~ /^[*]/) {
				$message = "symlink ";
			}
			if($_ !~ /^[!*]/ && -f $_ || $_ =~ s/^!// && ! -f $_ || $_ =~ s/^[*]// && -l $_) {
				out("Test PASSED: $file resulted in $_ ${message}existing\n");
				$passed_count++;
				#<STDIN>;
			} else {
				out("Test FAILED!: $file did not result in $_ ${message}existing\n");
				$failed_count++;
				out("Press Enter to continue\n");
				<STDIN>;
			}
		}
		rmtree($test_directory);
	}
}

# removes filename
sub path {
	my ($title) = @_;
	if($title =~ s/(.*)(?:\/|\\)(.*)/$1/) {
		return $title."/";
	} else {
		return "";
	}
}

sub create_file {
	my ($file) = @_;
	open(FH,">$file") or warn "Can't create $file: $!";
	close(FH);
}

sub make_paths {
	out("\tMaking paths\n");
	rmtree($test_directory);
	make_path($to_sort);
	make_path($tv_dir);
	make_path($movie_dir);
	make_path($misc_dir);
	make_path($music_dir);
}

sub display_time {
	my ($second, $minute, $hour, $dayofmonth, $month, $yearoffset) = localtime();
	my $year = 1900 + $yearoffset;
	my $thetime = "$hour:$minute:$second, $dayofmonth-$month-$year";
	out("$thetime\n"); 
}

sub out {
	my (@msg) = @_;
	print @msg;
	print $log @msg if(defined $log);
}