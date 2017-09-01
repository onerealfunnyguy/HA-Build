#!/usr/bin/perl

# SortTV
# Copyleft (ↄ) 2010-2013
# Z. Cliffe Schreuders
#
# Sorts tv shows into tvshow/series directories;
# If the dirs don't exist they are created;
# Updates xbmc via the web interface;
# Unsorted files are moved to a dir if specifed;
# Lots of other features.
#
# Other contributers:
# salithus - xbmc forum
# schmoko - xbmc forum
# CoinTos - xbmc forum
# gardz - xbmc forum
# Patrick Cole - z@amused.net
# Martin Guillon - farfromrefug
# red_five - xbmc forum
# Fox - xbmc forum
# TechLife - xbmc forum
# frozenesper - xbmc forum
# deranjer - xbmc forum
# iamwudu - xbmc forum
# Nicolas Leclercq - https://sourceforge.net/u/exzz/
# Justin Metheny
#
# Please goto the xbmc forum to discuss SortTV:
# http://forum.xbmc.org/showthread.php?t=75949
# 
# Get the latest version from here:
# http://sourceforge.net/projects/sorttv/files/
# 
# Cliffe's website:
# http://z.cliffe.schreuders.org/
# 
# Please consider a $5 donation if you find this program helpful.
# http://sourceforge.net/donate/index.php?group_id=330009
# If you prefer to donate via bitcoin, contact me for details

# This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.

use warnings;
use strict;
use utf8;

use File::Copy::Recursive "dirmove", "dircopy";
use File::Copy;
use File::Glob ':glob';
use LWP::Simple qw($ua getstore get is_success);
use File::Spec::Functions "rel2abs";
use File::Basename;
use TVDB::API;
use WWW::TheMovieDB;
use JSON::Parse 'parse_json';
use XML::Simple;
use File::Find;
use File::Path qw(make_path);
use FileHandle;
use Fcntl ':flock';
use Getopt::Long;
use Getopt::Long qw(GetOptionsFromString);
use IO::Socket;

# Global config variables
my $man = my $help = 0;
my ($sortdir, $tvdir, $miscdir, $musicdir, $moviedir, $matchtype);
my ($xbmcoldwebserver, $xbmcaddress);
my $xbmcport = 9090;
my ($newshows, $new, $log);
my @musicext = ("aac","aif","iff","m3u","mid","midi","mp3","mpa","ra","ram","wave","wav","wma","ogg","oga","ogx","spx","flac","m4a", "pls");
my @videoext = ("avi","mpg","mpe","mpeg-1","mpeg-2","m4v","mkv","mov","mp4","mpeg","ogm","wmv","divx","dvr-ms","3gp","m1s","mpa","mp2","m2a","mp2v","m2v","m2s","qt","asf","asx","wmx","rm","ram","rmvb","3g2","flv","swf","aepx","ale","avp","avs","bdm","bik","bin","bsf","camproj","cpi","dat","dmsm","dream","dvdmedia","dzm","dzp","edl","f4v","fbr","fcproject","hdmov","imovieproj","ism","ismv","m2p","mod","moi","mts","mxf","ogv","pds","prproj","psh","r3d","rcproject","scm","smil","sqz","stx","swi","tix","trp","ts","veg","vf","vro","webm","wlmp","wtv","xvid","yuv","3gp2","3gpp","3p2","aaf","aep","aetx","ajp","amc","amv","amx","arcut","arf","avb","axm","bdmv","bdt3","bmk","camrec","cine","clpi","cmmp","cmmtpl","cmproj","cmrec","cst","d2v","d3v","dce","dck","dcr","dcr","dir","dmb","dmsd","dmsd3d","dmss","dpa","dpg","dv","dv-avi","dvr","dvx","dxr","dzt","evo","eye","f4p","fbz","fcp","flc","flh","fli","gfp","gts","hkm","ifo","imovieproject","ircp","ismc","ivf","ivr","izz","izzy","jts","jtv","m1pg","m21","m21","m2t",
	"m2ts","m2v","mgv","mj2","mjp","mk3d","mnv","mp21","mp21","mpgindex","mpl","mpls","mpv","mqv","msdvd","mse","mswmm","mtv","mvd","mve","mvp","mvp","mvy","ncor","nsv","nuv","nvc","ogx","pgi","photoshow","piv","plproj","pmf","ppj","prel","pro","prtl","pxv","qtl","qtz","rcd","rdb","rec","rmd","rmp","rms","roq","rsx","rum","rv","rvl","sbk","scc","screenflow","seq","sfvidcap","siv","smi","smk","stl","svi","swt","tda3mt","tivo","tod","tp","tp0","tpd","tpr","tsp","tvs","usm","vc1","vcpf","vcv","vdo","vdr","vep","vfz","vgz","viewlet","vlab","vp6","vp7","vpj","vsp","wcp","wmd","wmmp","wmx","wp3","wpl","wvx","xej","xel","xesc","xfl","xlmv","zm1","zm2","zm3","zmv");
my @subtitleext = ("ssa", "srt", "sub");
my @imageext = ("jpg", "jpeg", "tbn");
my (@whitelist, @blacklist, @deletelist, @sizerange, @filestosort, @nonmediaext);
my (%showrenames, %showtvdbids);
my $REDO_FILE = my $checkforupdates = my $moveseasons = my $windowsnames = my $tvdbrename = my $lookupseasonep = my $extractrar = my $useseasondirs = my $displaylicense = my $useextensions = "TRUE";
my $usedots = my $rename = my $seasondoubledigit = my $removesymlinks = my $needshowexist = my $flattennonepisodefiles = my $tvdbrequired = my $sort_movie_dir = "FALSE";
my $dryrun = "";
my $seasontitle = "Season ";
my $sortby = "MOVE";
my $duplicateimages = "SYMLINK";
my $sortolderthandays = my $poll = my $verbose = 0;
my $ifexists = "SKIP";
my $renameformat = "[SHOW_NAME] - [EP1][EP_NAME1]";
my $movierenameformat = "[MOVIE_TITLE] [YEAR2]/[MOVIE_TITLE] [YEAR1]";
my $fetchmovieimages = "TRUE";
my $treatdir = "RECURSIVELY_SORT_CONTENTS";
my $fetchimages = "NEW_SHOWS";
my $imagesformat = "POSTER";
my $scriptpath = dirname(rel2abs($0));
my $logfile = "$scriptpath/sorttv.log";
my $tvdblanguage = "en";
my $movielanguage = "en";
my $tvdb;
my $tmdb;
my $yeartoleranceforerror = 1;
my $forceeptitle = ""; # HACK for limitation in TVDB API module
# download timeout
$ua->timeout(20);
my $dir_perms;

my @optionlist = (
	"misc-dir|non-episode-dir|misc=s" => sub { set_directory($_[1], \$miscdir); },
	"xbmc-old-web-server|xbmc-web-server|xo=s" => \$xbmcoldwebserver,
	"xbmc-remote-control|xr=s" => \$xbmcaddress,
	"xbmc-remote-control-port|xrp=i" => \$xbmcport,
	"match-type|ms=s" => \$matchtype,
	"flatten-non-eps|fne=s" => \$flattennonepisodefiles,
	"check-for-updates|up=s" => \$checkforupdates,
	"treat-directories|td=s" => \$treatdir,
	"consider-media-file-extensions|ext=s" => \$useextensions,
	"if-file-exists|e=s" => \$ifexists,
	"extract-compressed-before-sorting|rar=s" => \$extractrar,
	"show-name-substitute=s" =>
		sub {
			if($_[1] =~ /(.*)-->(.*)/) {
				my ($key, $val) = ($1, $2);
				$key = fixtitle($key);
				$showrenames{$key} = $val;
			}
		},
	"whitelist|white=s" =>
		sub {
			# puts the shell pattern in as a regex
			push @whitelist, glob2pat($_[1]);
		},
	"blacklist|black|ignore=s" =>
		sub {
			# puts the shell pattern in as a regex
			push @blacklist, glob2pat($_[1]);
		},
	"deletelist|delete=s" =>
		sub {
			# puts the shell pattern in as a regex
			push @deletelist, glob2pat($_[1]);
		},
	"tvdb-id-substitute|tis=s" => 
		sub { 
			if($_[1] =~ /(.*)-->(.*)/) {
				my ($key, $val) = ($1, $2);
				$key = fixtitle($key);
				$showtvdbids{$key} = $val;
			}
		},
	"tvdb-episode-name-required|nreq=s" => \$tvdbrequired,
	"display-license|dl=s" => \$displaylicense,
	"log-file|o=s" => \$logfile,
	"fetch-show-title|fst=s" => \$tvdbrename,
	"rename-media|rename-episodes|rn=s" => \$rename,
	"tv-lookup-language|lookup-language|lang=s" => \$tvdblanguage,
	"movie-lookup-language|lang=s" => \$movielanguage,
	"fetch-tv-images|fetch-images|fi=s" => \$fetchimages,
	"fetch-movie-images|fmi=s" => \$fetchmovieimages,
	"images-format|im=s" => \$imagesformat,
	"duplicate-images|csi=s" => \$duplicateimages,
	"require-show-directories-already-exist|rs=s" => \$needshowexist,
	"force-windows-compatible-filenames|fw=s" => \$windowsnames,
	"rename-tv-format|rename-format|rf=s" => \$renameformat,
	"rename-movie-format|rf=s" => \$movierenameformat,
	"remove-symlinks|rs=s" => \$removesymlinks,
	"use-dots-instead-of-spaces|dots=s" => \$usedots,
	"sort-by|by=s" => \$sortby,
	"sort-only-older-than-days|age=i" => \$sortolderthandays,
	"year-tolerance-for-error|yerr=i" => \$yeartoleranceforerror,
	"poll-time|poll=s" =>
		sub {
			my $ptime = $_[1];
			# convert times to seconds
			if ($ptime =~ /^(.*)(?:secs?|s)$/) {
				$ptime = $1;
			} elsif ($ptime =~ /^(.*)(?:mins?|m)$/) {
				$ptime = $1 * 60;
			} elsif ($ptime =~ /^(.*)(?:hrs?|hours?|h)$/) {
				$ptime = $1 * 3600;
			} elsif ($ptime =~ /^(.*)(?:days?|d)$/) {
				$ptime = $1 * 86400;
			} elsif ($ptime =~ /(\d+)/) {
				out("warn", "WARN: interpreting $ptime as $1 seconds\n");
				$ptime = $1;
			} else {
				out("warn", "WARN: invalid poll time: $ptime. Must be secs, hrs, days etc.\n");
				$ptime = 0;
			}
			$poll = $ptime;
		},
	"season-double-digits|sd=s" => \$seasondoubledigit,
	"match-files-based-on-tvdb-lookups|tlookup=s" => \$lookupseasonep,
	"use-season-directories|sd=s" => \$useseasondirs,
	"season-title|st=s" => \$seasontitle,
	"verbose|v" => \$verbose,
	"dry-run|n" => 
		sub {
			$dryrun = "DRYRUN ";
			out("std", "DRY RUN MODE: No file operations will occur on the to-sort directory, some directories may be created at the destination.\n");
		},
	"filesize-range|fsrange=s" =>
		sub {
			# Extract the min & max values, can mix and match postfixes
			if ($_[1] !~ /(.*)-(.*)/) {
				out ("warn", "WARN: invalid filesize range format. Must be 125MB-350MB, etc. Received: $_[1]");
				return;
			}
			my $minfilesize = $1;
			my $maxfilesize = $2;

			$minfilesize =~ s/MB//;
			$maxfilesize =~ s/MB//;
			# Fix filesizes passed in to all MB
			if ($minfilesize =~ /(.*)GB/) {
				$minfilesize = $1 * 1024;
			}
			if ($maxfilesize =~ /(.*)GB/) {
				$maxfilesize = $1 * 1024;
			}
			# Save as MB range
			push @sizerange, "$minfilesize-$maxfilesize";
		},
	"no-network|nn" => 
		sub {
			out("verbose", "INFO: Disabling all network enabled features\n");
			$xbmcoldwebserver = $xbmcaddress = $moviedir = "";
			$tvdbrename = $fetchimages = $lookupseasonep = $checkforupdates = "FALSE";
			$renameformat =~ s/\[EP_NAME\d\]//;
		},
	"read-config-file|conf=s" => 
		sub {
			get_config_from_file($_[1]);
		},
	"file-to-sort|file=s" => 
		sub {
			if(-r $_[1]) {
				push @filestosort, $_[1];
			} else {
				out("warn", "WARN: file $_[1] does not exist\n");
			}
			out("verbose", "\@filestosort: @filestosort\n");
		},
	"directory-to-sort|sort=s" => sub { set_directory($_[1], \$sortdir); },
	"tv-directory|directory-to-sort-into|tvdir=s" => 
		sub {
			if($_[1] eq "KEEP_IN_SAME_DIRECTORIES") {
				out("std", "INFO: disabling everything except tv sorts within the same directory");
				$miscdir = "";
				$musicdir = "";
				$moviedir = "";
				$tvdir = "KEEP_IN_SAME_DIRECTORIES";
			} else {
				set_directory($_[1], \$tvdir);
			}
		},
	"movie-directory|movie=s" => sub { set_directory($_[1], \$moviedir); },
	"sort-movie-directories|mdsort=s" => \$sort_movie_dir,
	"movie-language|mlang=s" => \$movielanguage,
	"music-directory|music=s" => sub { set_directory($_[1], \$musicdir); },
	"music-extension|me=s" => \@musicext,
	"non-media-extension|nm=s" => \@nonmediaext,
	"dir-permissions|dp=s" => \$dir_perms,
	"h|help|?" => \$help, man => \$man
);

# current episode being sorted
my ($showname, $year, $series, $episode, $pureshowname) = "";

{ # Main bare block

	out("std", "SortTV\n", "~" x 6,"\n");

	# ensure only one copy running at a time
	if(open SELF, "< $0") {
		flock SELF, LOCK_EX | LOCK_NB  or die "SortTV is already running, exiting.\n";
	}
	check_for_updates() if $checkforupdates eq "TRUE";

	get_config_from_file("$scriptpath/sorttv.conf");

	# we declare all the possible options through command line
	# each option can have multiple variables (|) and can be used like
	# "--opt" or "--opt=value" or "opt=value" or "opt value" or "-opt value" etc
	process_args();

	display_license() if $displaylicense eq "TRUE";

	# we stop the script and show the help if help or man option was used
	showhelp() if $help or $man;

	# ensure at least one input and one output
	if((!defined($sortdir) && ! scalar @filestosort) || (!defined($tvdir) && !defined($moviedir) && !defined($musicdir) && !defined($miscdir))) {
		out("warn", "Incorrect usage or configuration (missing sort or sort-to directories)\n");
		out("warn", "run 'perl sorttv.pl --help' for more information about how to use SortTV\n");
		exit;
	}

	# if uses thetvdb, set it up
	if($renameformat =~ /\[EP_NAME\d]/i || $fetchimages ne "FALSE" 
	|| $lookupseasonep ne "FALSE" || $lookupseasonep ne "FALSE") {
		my $TVDBAPIKEY = "FDDBDB916D936956";
		$tvdb = TVDB::API::new($TVDBAPIKEY);

		$tvdb->setLang($tvdblanguage);
		my $hashref = $tvdb->getAvailableMirrors();
		$tvdb->setMirrors($hashref);
		$tvdb->chooseMirrors();
		unless (-e "$scriptpath/.cache" || mkdir "$scriptpath/.cache") {
			out("warn", "WARN: Could not create cache dir: $scriptpath/cache $!\n");
			exit;
		}
		$tvdb->setCacheDB("$scriptpath/.cache/.tvdb.db");
		$tvdb->setUserAgent("SortTV");
		$tvdb->setBannerPath("$scriptpath/.cache/");
	}

	# if uses moviedb, set it up
	if($moviedir) {
		$tmdb = new WWW::TheMovieDB({
			'key'=>'e3df0ef251745a7833d9e9114fc9b0c1',
			'language'=>$movielanguage
		});
	}

	$log = FileHandle->new("$logfile", "a") or out("warn", "WARN: Could not open log file $logfile: $!\n") if $logfile;
	display_sortdirs();
	out("std", "Polling every $poll seconds...\n") if $poll;

	do {
		display_time();
		sort_directory($sortdir, @filestosort);

		if($xbmcoldwebserver && $newshows) {
			sleep(4);
			# update xbmc video library
			get "http://$xbmcoldwebserver/xbmcCmds/xbmcHttp?command=ExecBuiltIn(updatelibrary(video))";
			# notification of update
			get "http://$xbmcoldwebserver/xbmcCmds/xbmcHttp?command=ExecBuiltIn(Notification(,NEW EPISODES NOW AVAILABLE TO WATCH\n$newshows, 7000))";
		}
		if($xbmcaddress && $newshows) {
			update_xbmc();
		}

		sleep($poll);
	} while ($poll);
	
	$log->close if(defined $log);
	exit;
}

# notifies the user if a newer version is available
# gets the version of the latest release from sourceforge, and compares that to the local version
sub check_for_updates {
	my ($version, $localmaj, $localmin, $currentversion, $currentmaj, $currentmin);
	if(open (VER, "$scriptpath/.sorttv.version")) {
		chomp($version = <VER>);
	}
	if($version =~ /(\d+).(\d+)/) {
		($localmaj, $localmin) = ($1, $2);
	}
	$currentversion = get "http://sourceforge.net/p/sorttv/code/ci/master/tree/.sorttv.version?format=raw";
	# exit if network problems
	return unless $currentversion;
	if($currentversion =~ /(\d+).(\d+)/) {
		($currentmaj, $currentmin) = ($1, $2);
		if($localmaj < $currentmaj || ($localmaj == $currentmaj && $localmin < $currentmin)) {
			out("std", "UPDATE AVAILABLE: A new version of SortTV is available!\n\tVisit http://sourceforge.net/projects/sorttv/ to get the latest version.\n\tLocal version: $version, latest release: $currentversion\n");
		}
	} else {
		# got something, but it does not conform to a valid version number
		out("std", "Unable to determine latest release. A new version of SortTV may be available.\n\tVisit http://sourceforge.net/projects/sorttv/ to get the latest version.\n\tLocal version: $version\n");
	}
}

sub update_xbmc {
	my $sock = new IO::Socket::INET (
		PeerAddr => $xbmcaddress,
		PeerPort => $xbmcport,
		Proto => 'tcp', 6 );
	if($sock) {
		print $sock '{"id":1,"method":"VideoLibrary.Scan","params":[],"jsonrpc":"2.0"}';
		print $sock '{"jsonrpc": "2.0", "method": "VideoLibrary.ScanForContent", "id": 1}\n';
		print $sock "{\"jsonrpc\":\"2.0\",\"method\":\"GUI.ShowNotification\",\"params\":{\"title\":\"New Shows Available to Watch\",\"message\":\"$new\",\"image\":\"\"},\"displaytime\":10000,\"id\":1}\n";
		close($sock);
	} else {
		out("warn", "WARN: Could not connect to xbmc server: $!\n");
	}
}

# checks for the old way we specified options, and converts
sub check_for_old_style_options {
	my @list = @_;
	foreach (@list) {
		if($_ =~ /(^[^:= 	]+):(.+)$/) {
			$_ = "$1=$2";
		}
	}
	@ARGV = @list;
}

# processes the arguments, checks for old style, calls GetOptions, then uses what is left
sub process_args {
	check_for_old_style_options(@ARGV);
	GetOptions(@optionlist);
	set_directory($ARGV[0], \$sortdir) if defined $ARGV[0];
	set_directory($ARGV[1], \$tvdir) if defined $ARGV[1];
}

# displays an overview of the sorting that is being done
sub display_sortdirs {
	out("std", "Sorting:\n\tFrom $sortdir\n") if $sortdir;
	out("std", "\tTV episodes into $tvdir\n") if $tvdir;
	out("std", "\tMovies into $moviedir\n") if $moviedir;
	out("std", "\tMusic into $musicdir\n") if $musicdir;
	out("std", "\tEverything else into $miscdir\n") if $miscdir;
}

# displays the license and asks for a donation
sub display_license {
	out("std", "SortTV is copyleft free open source software.\nYou are free to make modifications and share, as defined by version 3 of the GNU General Public License\n");
	out("std", "If you find this software helpful, \$5 donations are welcomed:\nhttp://sourceforge.net/donate/index.php?group_id=330009\n");
	out("std", "~" x 6,"\n");
}

# used to check that a dir exists, then set the corresponding variable
sub set_directory {
	my ($dir, $dir_variable) = @_;
	# use Unix slashes
	$dir =~ s/\\/\//g;
	if(-e $dir) {
		$$dir_variable = $dir;
		# append a trailing / if it's not there
		$$dir_variable .= '/' if($$dir_variable !~ /\/$/);
	} else {
		out("warn", "WARN: directory does not exist ($dir)\n");
	}
}

sub sort_directory {
	# passed the directory to sort the contents of, and any additional files
	my ($sortd, @files) = @_;
	# escape special characters from  bsd_glob
	my $escapedsortd = $sortd;
	$escapedsortd =~ s/(\[|]|\{|}|-|~)/\\$1/g;

	if($extractrar eq "TRUE") {
		extract_archives($escapedsortd, $sortd);
	}

	FILE: foreach my $file (bsd_glob($escapedsortd.'*'), @files) {
		$showname = "";
		my $nonep = "FALSE";
		my $filename = filename($file);
		out("verbose", "INFO: Currently checking file: $filename\n");
		# check white and black lists
		if(check_lists($file) eq "NEXT") {
			next FILE;
		}
		# check size
		if (check_filesize($file) eq "NEXT") {
			next FILE;
		}
		# check age
		if ($sortolderthandays && -M $file < $sortolderthandays) {
			out("std", "SKIP: $file is newer than $sortolderthandays days old.\n");
			next FILE;
		}
		# treat symlinks separately
		if(-l $file) {
			if($removesymlinks eq "TRUE") {
				out("std", "DELETE: Removing symlink: $file\n");
				unless ($dryrun) {
					unlink($file) or out("warn", "WARN: Could not delete symlink $file: $!\n");
				}
			}
			# otherwise file is a symlink, ignore
		# ignore directories, if so configured
		} elsif(-d $file && $treatdir eq "IGNORE") {
			out("verbose", "INFO: Ignoring Dir: $file\n");
			# ignore directories
		# here we attempt to sort each type of media
		# movie should come last since it will attempt to find a matching movie name on tmdb
		} else {
			# try to find a matching sort method
			unless(is_music($file, $filename) 
			|| is_season_directory($file, $filename) 
			|| is_tv_episode($file, $filename)
			|| is_movie($file, $filename)) {
				# if it does not match the requirements for any sort method,
				# either recursively sort each directory, or the file is an "other" 
				if(-d $file && $treatdir eq "RECURSIVELY_SORT_CONTENTS") {
					out("verbose", "INFO: Entering into directory or compressed file $file\n");
					sort_directory("$file/");
					# removes any empty directories from the to-sort directory and sub-directories 
					finddepth(sub{rmdir},"$sortd");
				} elsif($miscdir && $tvdir ne "KEEP_IN_SAME_DIRECTORIES") {
					# move anything else
					sort_other ("OTHER", "$miscdir", $file);
				}
			}
		}
	}
}

sub is_video_to_be_sorted {
	my ($file, $filename) = @_;
	return ($treatdir eq "AS_FILES_TO_SORT" and -d $file) || ($useextensions eq "FALSE" and -f $file and not is_other($file)) || (-f $file and not is_other($file) and matches_type($filename, @videoext, @imageext, @subtitleext));
}

sub is_music_to_be_sorted {
	my ($file, $filename) = @_;
	return (-f $file and not is_other($file) and matches_type($filename, @musicext));
}

# checks whether this is a movie to be sorted
# if it is, this kicks of the sorting process
sub is_movie {
	my ($file, $filename) = @_;
	# conditions for it to be checked
	if($moviedir && (is_video_to_be_sorted($file, $filename) || (-d $file and $sort_movie_dir eq "TRUE"))) {
		# check regex
		if($filename =~ /(.*?)\s*-?\.?\s*\(?\[?((?:20|19)\d{2})\)?\]?(?:BDRip|\[Eng]|DVDRip|DVD|Bluray|XVID|DIVX|720|1080|HQ|x264|R5)*.*?(\.\w*$)/i
		|| $filename =~ /(.*?)\.?(?:[[\]{}()]|\[Eng]|BDRip|DVDRip|DVD|Bluray|XVID|DIVX|720|1080|HQ|x264|R5)+.*?()(\.\w*$)/i
		|| $filename =~ /(.*?)()(\.\w*$)/i || $filename =~ /(.*)()()/) {
			my $title = $1;
			my $year = $2;
			my $ext = $3;
			$title =~ s/(?:\[Eng]|BDRip|DVDRip|DVD|Bluray|XVID|DIVX|720|1080|HQ|x264|R5|[[\]{}()])//ig;
			# at this point if it is not a known movie it is an "other"
			if(match_and_sort_movie($title, $year, $ext, $file) eq "TRUE") {
				return 1;
			}
		}
	}
	return 0;
}

# checks whether this is a TV episode to be sorted
# if it is, this kicks of the sorting process
sub is_tv_episode {
	my ($file, $filename) = @_;
	# conditions for it to be checked
	if($tvdir && is_video_to_be_sorted($file, $filename)) {
		# check regex
		my $dirsandfile = $file;
		$dirsandfile =~ s/\Q$sortdir\E//;
		
		if($filename =~ /(.*?)(?:\.|\s|-|_|\[)+[Ss]0*(\d+)(?:\.|\s|-|_)*[Ee]0*(\d+).*/
		# "Show/Season 1/S1E1.avi" or "Show/Season 1/1.avi" or "Show Season 1/101.avi" or "Show/Season 1/1x1.avi" or "Show Series 1 Episode 1.avi" etc
		|| $dirsandfile =~ /(.*?)(?:\.|\s|\/|\\|-|\1)*(?:Season|Series|\Q$seasontitle\E)\D?0*(\d+)(?:\.|\s|\/|\\|-|\1)+[Ss]0*\2(?:\.|\s|-|_)*[Ee]0*(\d+).*/i
		|| $dirsandfile =~ /(.*?)(?:\.|\s|\/|\\|-|\1)*(?:Season|Series|\Q$seasontitle\E)\D?0*(\d+)(?:\.|\s|\/|\\|-|\1)+\[?0*\2?\s*[xX-]?\s*0*(\d{1,2}).*/i
		|| $dirsandfile =~ /(.*?)(?:\.|\s|\/|\\|-|\1)*(?:Season|Series|\Q$seasontitle\E)\D?0*(\d+)(?:\.|\s|\/|\\|-|\1)+\d??(?:[ .-]*Episode[ .-]*)?0*(\d{1,2}).*/i
		#  not a date, but is 1x1 or 1-1
		|| ($filename !~ /(\d{4}[-.]\d{1,2}[-.]\d{1,2})/ && $filename =~ /(.*)(?:\.|\s|-|_)+\[?0*(\d+)\s*[xX-]\s*0*(\d+).*/)
		|| $filename =~ /(.*)(?:\.|\s|-|_)+0*(\d)(\d{2})(?:\.|\s).*/
		|| ($matchtype eq "LIBERAL" && filename($file) =~ /(.*)(?:\.|\s|-|_)0*(\d+)\D*0*(\d+).*/)) {
			$pureshowname = $1;
			$pureshowname = fixpurename($pureshowname);
			$showname = fixtitle($pureshowname);
			if($seasondoubledigit eq "TRUE") {
				$series = sprintf("%02d", $2);
			} else {
				$series = $2;
			}
			$episode = $3;
			# extract year if present, for example "Show (2011)"
			if($pureshowname =~ /(.*)(?:\.|\s|-|\(|\[)*\(?((?:20|19)\d{2})(?:\)|\])?/) {
				$year = $2;
			} else {
				$year = "";
			}
			if($pureshowname ne "") {
				if($tvdir !~ /^KEEP_IN_SAME_DIRECTORIES/) {
					return move_episode($pureshowname, $showname, $series, $episode, $year, $file);
				} else {
					rename_episode($pureshowname, $series, $episode, $file);
					return 1;
				}
			}
		# match "Show - Episode title.avi" or "Show - [AirDate].avi"
		} elsif($tvdir && $lookupseasonep eq "TRUE" && (-d $file && $treatdir eq "AS_FILES_TO_SORT" || -f $file && matches_type($filename, @videoext, @imageext, @subtitleext)) && 
		(filename($file) =~ /(.*)(?:\.|\s)(\d{4}[-.]\d{1,2}[-.]\d{1,2}).*/ || filename($file) =~ /(.*)-(.*)(?:\..*)/)) {
			$pureshowname = $1;
			$showname = fixtitle($pureshowname);
			my $episodetitle = fixdate($2);
			$series = "";
			$episode = "";
			# calls fetchseasonep to try and find season and episode numbers: returns array [0] = Season [1] = Episode
			my @foundseasonep = fetchseasonep(resolve_show_name($pureshowname), $episodetitle);
			if(exists $foundseasonep[1]) {
				$series = $foundseasonep[0];
				$episode = $foundseasonep[1];
			}
			if($series ne "" && $episode ne "") {
				if($seasondoubledigit eq "TRUE" && $series =~ /\d+/) {
					$series = sprintf("%02d", $series);
				}
				if($tvdir !~ /^KEEP_IN_SAME_DIRECTORIES/) {
					return move_episode($pureshowname, $showname, $series, $episode, $year, $file);
				} else {
					rename_episode($pureshowname, $series, $episode, $file);
					return 1;
				}
			}
		}
	}
	return 0;
}

# checks whether this is a tv season directory to be sorted as is
# if it is, this kicks of the sorting process
sub is_season_directory {
	my ($file, $filename) = @_;
	# conditions for it to be checked
	if($tvdir && ($treatdir eq "AS_FILES_TO_SORT" && -d $file)) {
		# check regex
		if($file =~ /.*\/(.*)(?:Season|Series|$seasontitle)\D?0*(\d+).*/i && $1) {
			out("verbose", "INFO: Treating $file as directory to sort\n");
			$pureshowname = $1;
			if($seasondoubledigit eq "TRUE") {
				$series = sprintf("%02d", $2);
			} else {
				$series = $2;
			}
			$showname = fixtitle($pureshowname);
			# extract year if present, for example "Show (2011)"
			if($pureshowname =~ /(.*)(?:\.|\s|-|\(|\[)*\(?((?:20|19)\d{2})(?:\)|\])?/) {
				$year = $2;
			} else {
				$year = "";
			}
			if(move_series($pureshowname, $showname, $series, $year, $file)) {
				return 1;
			}
		}
	}
	return 0;
}

# checks whether this is music to be sorted
# if it is, this kicks of the sorting process
sub is_music {
	my ($file, $filename) = @_;
	# conditions for it to be checked
	if($musicdir && is_music_to_be_sorted($file, $filename)) {
		#move to music folder if music
		sort_other ("MUSIC", "$musicdir", $file);
	}
}

# used to sort files into another directory
sub sort_other {
	my ($msg, $destdir, $file) = @_;
	my $newname = $file;
	$newname =~ s/\Q$sortdir\E//; #stripping the $sortdir from the filename
	$newname = escape_myfilename($newname);
	if($flattennonepisodefiles eq "FALSE") {
		my $dirs = path($newname);
		my $filename = filename($newname);
		if(! -d $file && ! -e $destdir . $dirs) {
			# recursively creates the dir structure
			make_path($destdir . $dirs);		
		}
		$newname = $dirs . $filename;
	} else { # flatten
		$newname =~ s/[\\\/]/-/g;
	}
	sort_file($file, $destdir . $newname, $msg);
}

sub get_config_from_file {
	my ($filename) = @_;
	my @arraytoconvert;
	
	if(open (IN, $filename)) {
		out("verbose", "INFO: Reading configuration settings from '$filename'\n");
		while(my $in = <IN>) {
			chomp($in);
			$in =~ s/\\/\//g;
			if($in =~ /^\s*#/ || $in =~ /^\s*$/) {
				# ignores comments and whitespace
			} else {
				# convert from ':' to '=' assignment format
				if($in =~ /(^[^:= 	]+):(.+)$/) {
					$in = "$1=$2";
				}
				GetOptionsFromString("'--$in'", @optionlist);
			}
		}
		close (IN);
	} else {
		out("warn", "WARN: Couldn't open config file '$filename': $!\n");
		out("warn", "INFO: An example config file is available and can make using SortTV easier\n");
	}
}

sub showhelp {
	my $heredoc = <<END;
Usage: sorttv.pl [OPTIONS] [directory-to-sort directory-to-sort-into]

By default SortTV tries to read the configuration from sorttv.conf
	(an example config file is available online)
You can overwrite any config options with commandline arguments, which match the format of the config file (except that each argument starts with "--")

OPTIONS:
--directory-to-sort=dir
	A directory containing files to sort
	For example, set this to where completed downloads are stored

--file-to-sort=file
	A file to be sorted
	This argument can be repeated to add multiple individual files to sort

--tv-directory=dir
	Where to sort episodes into (dir that will contain dirs for each show)
	This directory will contain the structure (Show)/(Seasons)/(episodes)
	Alternatively set this to "KEEP_IN_SAME_DIRECTORIES" for a recursive renaming of files in directory-to-sort

--movie-directory
	Where to sort movies into
	If not specified, movies are not moved

--music-directory=dir
	Where to sort music into
	If not specified, music is not moved

--misc-directory=dir
	Where to put things that are not episodes etc
	If this is supplied then files and directories that SortTV does not believe are episodes will be moved here
	If not specified, non-episodes are not moved

--dry-run
	Dry run mode. No file operations will occur on the to-sort directory.
	Some directories may be created at the destination.

--whitelist=pattern
	Only copy if the file matches one of these patterns
	Uses shell-like simple pattern matches (eg *.avi)
	This argument can be repeated to add more rules

--ignore=pattern
	Don't copy if the file matches one of these blacklist patterns
	Uses shell-like simple pattern matches (eg *.avi)
	This argument can be repeated to add more rules

--delete=pattern
	Delete the source file, if the file matches one of these patterns
	Uses shell-like simple pattern matches (eg *.avi)
	This argument can be repeated to add more rules

	--consider-media-file-extensions=[TRUE|FALSE]
		Consider the file extension before treating certain files as movies or TV episodes
		Recommended: SortTV is aware of a large number of extensions, and this can avoid many false matches
		if not specified, TRUE

--consider-media-file-extensions=[TRUE|FALSE]
	Consider the file extension before treating certain files as movies or TV episodes
	Recommended: SortTV is aware of a large number of extensions, and this can avoid many false matches
	if not specified, TRUE

--non-media-extension=pattern
	These extensions are NEVER movies or TV shows or music, treat them as "others" automatically
	Note: Will not run these file types through tvdb, tmdb, etc.
	Not typically required if consider-media-file-extensions=TRUE
	This argument can be repeated to add multiple extensions

--filesize-range=pattern
	Only copy files which fall within these filesize ranges.
	Examples for the pattern include 345MB-355MB or 1.05GB-1.15GB

--sort-only-older-than-days=number
	Sort only files or directories that are older than this number of days.  
	If not specified or zero, sort everything.

--xbmc-old-web-server=host:port
	host:port for the old xbmc webserver, to automatically update library when new episodes arrive
	Remember to enable the webserver within xbmc, and "set the content" of your TV directory in xbmc.
	If not specified, xbmc is not updated

--xbmc-remote-control=host
	host for the new xbmc communication, to automatically update library when new episodes arrive
	You probably want to set this to "localhost"

--xbmc-remote-control-port=port
	port number for the new xbmc communication
	You probably want to set this to "9090", if that doesn't work, try "80"

--log-file=filepath
	Log to this file
	If not specified, output goes to sorttv.log in the script directory

--verbose
	Output verbosity. Set to TRUE to show messages describing the decision making process.
	If not specified, FALSE

--polling-time={X}
	Tell the script to check for new files to sort every X seconds, minutes, hours, or days
	You could set the script to start on system startup with polling, rather than using scheduling to start the script.
	Valid values include "2secs", "2days", "1min", "3hrs", "30s" etc.
	If not specified, polling is disabled and the script will only sort the directory once.

--read-config-file=filepath
	Secondary config file, overwrites settings loaded so far
	If not specified, only the default config file is loaded (sorttv.conf)

--fetch-show-title=[TRUE|FALSE]
	Fetch show titles from thetvdb.com (for proper formatting)
	If not specified, TRUE

--rename-episodes=[TRUE|FALSE]
	Rename episodes to a new format when moving
	If not specified, FALSE

--rename-tv-format={formatstring}
	the format to use if renaming to a new format (as specified above)
	Hint: including the Episode Title as part of the name slows the process down a bit since titles are retrieved from thetvdb.com
	The formatstring can be made up of:
	[SHOW_NAME]: "My Show"
	[EP1]: "S01E01"
	[EP2]: "1x1"
	[EP3]: "1x01"
	[EP4]: "01" (Episode number only)
	[EP_NAME1]: " - Episode Title"
	[EP_NAME2]: ".Episode Title"
	[QUALITY]: " HD" (or " SD") - extracted from original file name
	If not specified the format is "[SHOW_NAME] - [EP1][EP_NAME1]"
	For example:
		for "My Show S01E01 - Episode Title" (this is the default)
		--rename-format=[SHOW_NAME] - [EP1][EP_NAME1]
		for "My Show.S01E01.Episode Title"
		--rename-format=[SHOW_NAME].[EP1][EP_NAME2]

--rename-movie-format={formatstring}
	The format to use if renaming movies
	The format can be made up of:
		[MOVIE_TITLE]: "My Movie"
		[YEAR1]: "(2011)"
		[YEAR2]: "2011"
		[QUALITY]: " HD" (or " SD") - extracted from original file name
		[RATING]: "PG" - MPAA rating (US)
		/: A sub-directory (folder) - movies can be in their own directories
	If not specified the format is, "[MOVIE_TITLE] [YEAR2]/[MOVIE_TITLE] [YEAR1]"

--use-dots-instead-of-spaces=[TRUE|FALSE]
	Renames episodes to replace spaces with dots
	If not specified, FALSE

--season-title=string
	Season title
	Note: if you want a space it needs to be included
	(eg "Season " -> "Season 1",  "Series "->"Series 1", "Season."->"Season.1")
	If not specified, "Season "

--season-double-digits=[TRUE|FALSE]
	Season format padded to double digits (eg "Season 01" rather than "Season 1")
	If not specified, FALSE

--year-tolerance-for-error=number
	The tolerated variance for year matches.
	This applies to movies and to a lesser extent TV episodes (for sorting purposes).
	For example, if a year is specified in the filename of a movie to sort, it can be off by this many years and still be considered the same movie as one in tmdb database.
	Note that when sorting TV episodes, this is only considered when identifying local directories to sort into, and if a match is not found the year is subsequently ignored.
	If not specified, 1

--match-type=[NORMAL|LIBERAL]
	Match type. 
	LIBERAL assumes all files are episodes and tries to extract season and episode number any way possible.
	If not specified, NORMAL

--match-files-based-on-tvdb-lookups=[TRUE|FALSE]
	Attempt to sort files that are named after the episode title or air date.
	For example, "My show - My episode title.avi" or "My show - 2010-12-12.avi"
	 could become "My Show - S01E01 - My episode title.avi"
	Attempts to lookup the season and episode number based on the episodes in thetvdb.com database.
	Since this involves downloading the list of episodes from the Internet, this will cause a slower sort.
	If not specified, TRUE

--sort-by=[MOVE|COPY|MOVE-AND-LEAVE-SYMLINK-BEHIND|PLACE-SYMLINK|PLACE-HARDLINK]
	Sort by moving or copying the file. If the file already exists because it was already copied it is silently skipped.
	The MOVE-AND-LEAVE-SYMLINK-BEHIND option may be handy if you want to continue to seed after sorting, this leaves a symlink in place of the newly moved file.
	PLACE-SYMLINK does not move the original file, but places a symlink in the sort-to directory (probably not what you want)
	PLACE-HARDLINK does not move the original file, but places a hardlink in the sort-to directory. This might be helpful if you use Linux and you want a sorted and unsorted version on the same partition.
	If not specified, MOVE

--treat-directories=[AS_FILES_TO_SORT|RECURSIVELY_SORT_CONTENTS|IGNORE]
	How to treat directories. 
	AS_FILES_TO_SORT - sorts directories, moving entire directories that represents an episode, also detects and moves directories of entire seasons
	RECURSIVELY_SORT_CONTENTS - doesn't move directories, just their contents, including subdirectories
	IGNORE - ignores directories
	If not specified, RECURSIVELY_SORT_CONTENTS
	
--require-show-directories-already-exist=[TRUE|FALSE]
	Only sort into show directories that already exist
	This may be helpful if you have multiple destination directories. Just set up all the other details in the conf file, 
	and specify the destination directory when invoking the script. Only episodes that match existing directories in the destination will be moved.
	If this is false, then new directories are created for shows that dont have a directory.
	If not specified, FALSE
	
--remove-symlinks=[TRUE|FALSE]
	Deletes symlinks from the directory to sort while sorting.
	This may be helpful if you want to remove all the symlinks you previously left behind using --sort-by=MOVE-AND-LEAVE-SYMLINK-BEHIND
	You could schedule "perl sorttv.pl --remove-symlinks=TRUE" to remove these once a week/month
	If this option is enabled and used at the same time as --sort-by=MOVE-AND-LEAVE-SYMLINK-BEHIND, 
	 then only the previous links will be removed, and new ones may also be created
	If not specified, FALSE

--show-name-substitute=NAME1-->NAME2
	Substitutes names equal to NAME1 for NAME2
	This argument can be repeated to add multiple rules for substitution

--tvdb-id-substitute=NAME1-->TVDB ID
	Substitutes names equal to NAME1 for TVDB ID for lookups
	This argument can be repeated to add multiple rules for substitution

--music-extension=extension
	Define additional extensions for music files (SortTV knows a lot already)
	This argument can be repeated to add multiple additional extensions

--sort-movie-directories=[TRUE|FALSE]
	Attempt to sort entire directories that represent a movie
	The directory (and all its contents AS IS) will be sorted
	Note: Currently, this option WILL NOT rename or sort ANY of the contents of the directory, 
	including the movie. The directory will just be sorted into the movie-directory.
	If not specified, FALSE

--force-windows-compatible-filenames=[TRUE|FALSE]
	Forces MSWindows compatible file names, even when run on other platforms such as Linux
	This may be helpful if you are writing to a Windows share from a Linux system
	If not specified, TRUE

--tv-lookup-language=[en|...]
--movie-lookup-language=[en|...]
	Set language for thetvdb / tmdb lookups, this effects episode and movie titles etc
	Valid values include: it, zh, es, hu, nl, pl, sl, da, de, el, he, sv, eng, fi, no, fr, ru, cs, en, ja, hr, tr, ko, pt
	If not specified, en (English)

--flatten-non-eps=[TRUE|FALSE]
	Should non-episode files loose their directory structure?
	This option only has an effect if a non-episode directory was specified.
	If set to TRUE, they will be renamed after directory they were in.
	Otherwise they keep their directory structure in the new non-episode-directory location.
	If not specified, FALSE

--fetch-images=[NEW_SHOWS|FALSE]
	Download images for shows, seasons, and episodes from thetvdb
	Downloaded images are copied into the sort-to (destination) directory.
	NEW_SHOWS - When new shows, seasons, or episodes are created the associated images are downloaded
	FALSE - No images are downloaded
	if not specified, NEW_SHOWS

--images-format=POSTER
	Sets the image format to use, poster or banner.
	POSTER/BANNER
	if not specified, POSTER

--fetch-movie-images=[TRUE|FALSE]
	Download images for movies
	Downloaded images are copied into the sort-to (destination) directory.
	If not specified, TRUE

--duplicate-images=[SYMLINK|COPY]
	Duplicate images can be symlinked or copied. For example TV season images get placed in the main directory, and in season subdirectories.
	The SYMLINK option is recommended. If symlinks are not available (for example, on Windows), then they will be copied.
	If not specified, SYMLINK.

--if-file-exists=[SKIP|OVERWRITE]
	What to do if a file already exists in the destination
	If not specified, SKIP

--tvdb-episode-name-required=[TRUE|FALSE]
	Only sort tv episodes if the episode name was available from thetvdb
	Note that this only applies if you include the tvdb episode name in the rename format (and have renaming enabled)
	Also note that directories may still be created in the destination, even if the file is skipped due to this rule
	If not specified, FALSE

--extract-compressed-before-sorting=[TRUE|FALSE]
	Extracts the contents of archives (.zip, .rar) into the directory-to-sort while sorting
	If "rar" and "unzip" programs are available they are used.
	If not specified, TRUE

--dir-permissions=[octal]
	Set permissions on new created directories (octal format : 0775)
	If no specified, uses system defined umask

--check-for-updates=[TRUE|FALSE]
	Check for newer versions of SortTV
	If not specified, TRUE

--display-license=[TRUE|FALSE]
	Shows the license and some information about donations when the program starts
	If not specified, TRUE

--no-network
	Disables all the network enabled features such as:
		Disables notifying xbmc
		Disables tvdb title formatting
		Disables fetching images
		Disables looking up files named "Show - EpTitle.ext" or by airdate
		Changes rename format (if applicable) to not include episode titles

EXAMPLES:
Does a sort, as configured in sorttv.conf:
	perl sorttv.pl

The directory-to-sort and directory-to-sort-to can be supplied directly:
To sort a Downloads directory contents into a TV directory
	perl sorttv.pl /home/me/Downloads /home/me/Videos/TV
Alternatively:
	perl sorttv.pl --directory-to-sort=/home/me/Downloads --directory-to-sort-into=/home/me/Videos/TV

To move non-episode files in a separate directory:
	perl sorttv.pl --directory-to-sort=/home/me/Downloads --directory-to-sort-into=/home/me/Videos/TV --non-episode-dir=/home/me/Videos/Non-episodes

To integrate with xbmc (notification and automatic library update):
	perl sorttv.pl --directory-to-sort=/home/me/Downloads --directory-to-sort-into=/home/me/Videos/TV --xbmc-webserver=localhost:8080

And so on...

FURTHER INFORMATION:
Please goto the xbmc forum to discuss SortTV:
http://forum.xbmc.org/showthread.php?t=75949

Get the latest version from here:
http://sourceforge.net/projects/sorttv/files/

Cliffe's website:
http://schreuders.org/

Please consider a \$5 paypal donation if you find this program helpful.

END
	out("std", $heredoc);
	exit;
}

# This subroutine is used to ignore things while looking for a match.
# replaces ".", "_" and removes "the" and ","
# removes numbers and spaces
# removes the dir path
sub fixtitle {
	my ($title) = @_;
	$title = lc($title);
	$title =~ s/,|\.the\.|\bthe\b//ig;
	$title =~ s/\.and\.|\band\b//ig;
	$title =~ s/[&+'_:"!]//ig;
	$title =~ s/(.*\/)(.*)/$2/;
	$title = remdot($title);
	$title =~ s/\d|\s|\(|\)//ig;
	# make sure that didn't remove everything
	if($title) {
		return $title;
	} else {
		return $_[0];
	}
}

# in most cases this is not needed, just cleans up the title slightly
# some of the tv episode regex grab more than the show title, this cleans that up, also removes dots etc
sub fixpurename {
	my ($title) = @_;
	# removes directories
	if($title =~ /\/(.+)/) {
		$title = $1;
	}
	# removes season
	#Some sort of error occured, had TV Show with setup "Spartacus Blood and Sand\Season 1\Spartacus Blood and Sand - Ep1.avi"
	#and the title turned out to be "Season 1\Spartacus blood and Sand"
	#and then got blanked out with this regex... not sure how to fix at original regex
	#so changed this regex to not delete everything after season or series
	$title =~ s/(?:Season.([0-9]{1,3}).|Series.([0-9]{1,3}).|\Q$seasontitle\E.*)//ig;
	# removes dots and special chars
	$title = remdot($title);
	# replace any double spaces with one space
	$title =~ s/\s\s/ /ig;
	return $title;
}

# format a date to YYYY-MM-DD for air date look up
# if not a date send it to fixtitle
sub fixdate {
	my ($title) = @_;
	if($title =~ /(\d{4})[-.](\d{1,2})[-.](\d{1,2})/) {
		my $month = sprintf("%02d", $2);
		my $day = sprintf("%02d", $3);
		return $1."-".$month."-".$day;
	} else {
		return fixtitle($title);
	}
}

# substitutes show names as configured
sub substitute_name {
	my ($from) = @_;
	foreach my $substitute (keys %showrenames) {
		if(fixtitle($from) =~ /^\Q$substitute\E$/i) {
			return $showrenames{$substitute};
		}
	}
	# if no matches, returns unchanged
	return $from;
}

# resolves a raw text string to a show name
# starts by checking if there is a literal rule substituting the string as is
# then removes dots dashes etc, and tries a substution again
# then checks if there is a tvdbid, if so renames using database
sub resolve_show_name {
	my ($title) = @_;
	return tvdb_title(substitute_name(remdot($title)));
}

# Use tvdb IDs to lookup shows
# returns the ID if available, or an empty string
sub substitute_tvdb_id {
	my ($from) = @_;	
	foreach my $substitute (keys %showtvdbids){
		if(fixtitle($from) =~ /^\Q$substitute\E$/i) {
			return $showtvdbids{$substitute};
		}
	}
	# if no matches, returns unchanged
	return $from;
}

# removes dots and underscores for creating dirs
sub remdot {
	my ($title) = @_;
	$title =~ s/\./ /ig;
	$title =~ s/_/ /ig;
	$title =~ s/-/ /ig;
	# remove double spaces
	$title =~ s/\s\s/ /ig;
	# don't start or end on whitespace
	$title =~ s/\s$//ig;
	$title =~ s/^\s//ig;
	return $title;
}

# removes slashes for creating files
sub cleanup_filename {
	my ($title) = @_;
	# remove slashes
	$title =~ s/\\|\//-/ig;
	# remove double spaces
	$title =~ s/\s\s/ /ig;
	# don't start or end on whitespace
	$title =~ s/\s$//ig;
	$title =~ s/^\s//ig;
	return $title;
}

# removes path
sub filename {
	my ($title) = @_;
	$title =~ s/(.*\/)(.*)/$2/;
	return $title;
}

# removes path and extension
sub filename_without_ext {
	my ($title) = @_;
	$title =~ s/(.*\/)(.*)/$2/;
	$title =~ s/(.*)\..*/$1/;
	return $title;
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

# converts to filesystem friendly names
sub escape_myfilename {
	my ($name) = @_;
	if($^O =~ /MSWin/ || $windowsnames eq "TRUE") {
		$name =~ s/[:*?\"<>|]/-/g;
	} else {
		$name =~ s/[\"<>|]/-/g;
	}
	return $name;
}

# turns a simple wildcard pattern into a regex
# this is from the Perl Cookbook
sub glob2pat {
	my $globstr = shift;
	my %patmap = (
		'*' => '.*',
		'?' => '.',
		'[' => '[',
		']' => ']',);
	$globstr =~ s{(.)} { $patmap{$1} || "\Q$1" }ge;
	return '^' . $globstr . '$';
}

# checks whether the file extension matches a known format
# this could be further optimised, by not copying the arrays in each time
sub matches_type {
	my ($file, @extensions) = @_;
	foreach my $ext (@extensions) {
		if($file =~ /.*\Q$ext\E$/) {
			return 1;
		}
	}
	return 0;
}

sub is_other {
	my ($file) = @_;
	foreach my $ext (@nonmediaext) {
		if($file =~ /.*\Q$ext\E$/) {
			return 1;
		}
	}
	return 0;
}

# checks white and black list
# returns "OK" or "NEXT"
sub check_lists {
	my ($filepath) = @_;
	my $file = filename($filepath);
	if(-d $filepath) {
		$file = "$file/"
	}
	# check whitelist, skip if doesn't match one
	my $found = "FALSE";
	foreach my $white (@whitelist) {
		if($file =~ /$white/) {
			$found = "TRUE";
		}
	}
	if($found eq "FALSE" && scalar(@whitelist)) {
		out("std", "SKIP: Doesn't match whitelist: $file\n");
		return "NEXT";
	}
	# check deletelist, delete the source file if it matches any
	foreach my $todelete (@deletelist) {
		if($file =~ /$todelete/) {
			out("std", "DELETE: Matches delete list: $filepath\n");
			unless($dryrun) {
				unlink($filepath) or out("warn", "WARN: File could not be deleted: $!");
			}
			return "NEXT";
		}
	}
	# check blacklist, skip if it matches any
	foreach my $black (@blacklist) {
		if($file =~ /$black/) {
			out("std", "SKIP: Matches ignore list: $file\n");
			return "NEXT";
		}
	}
	return "OK";
}

sub check_filesize {
	my ($file) = @_;

	# only check size if configured, and it is a regular file
	if (! -f $file || @sizerange == 0) {
		return "OK";
	}

	# calculate the size of the file in MB
	my $size = -s $file;
	my $filesize;
	if($size) {
		$filesize = $size / 1024 / 1024;
	} else {
		$filesize = 0;
	}

	# Loop through the size ranges passed in via the config file
	foreach my $size (@sizerange) {
		if ($size =~ /(.*)-(.*)/) {
			my $minfilesize = $1;
			my $maxfilesize = $2;

			# Check the filesize
			if ($minfilesize <= $filesize && $filesize <= $maxfilesize) {
				return "OK";
			}
		}
	}

	# Skip the file as it didn't fall within a specified filesize range
	my $filename = filename($file);
	out("std", "SKIP: Doesn't fit the filesize requirements: $filename\n");
	return "NEXT";
}

sub num_found_in_list {
	my ($find, @list) = @_;
	foreach (@list) {
		if($find == $_) {
			return "TRUE";
		}
	}
	return "FALSE";
}

# extract .rar, .zip files
# tries to use these programs: rar, unrar, unzip, 7zip
# if 7zip is used it will always overwrite existing files
sub extract_archives {
	my ($escapedsortd, $sortd) = @_;
	my $over = "";
	my @errors = (-1, 32512, 256, 768); # 768: CRC error
	foreach my $arfile (bsd_glob($escapedsortd.'*.{rar,zip,7z,gz,bz2}')) {
		my $dest = filename($sortd) . "/" . $arfile . " (extracted by SortTV)";
		if(-e $dest) {
			out("std", "SKIP: already extracted: $dest\n");
			next;
		}
		#my $filename_start = filename($sortd) . "/" . filename($arfile);
		if(bsd_glob($escapedsortd.filename_without_ext($arfile).'*.{part}*')) {
			out("std", "SKIP: parts are still downloading: $arfile\n");
			next;
		}
		if(filename($arfile) =~ /\b.*\.part\d+\.rar$/i && filename($arfile) !~ /\b.*\.part0*1\.rar$/i) {
			out("std", "SKIP: part file: $arfile\n");
			next;
		}

		unless (mkdir($dest)) {
			out("warn", "WARN: could not create directory: $dest ($!), extracting to $sortd\n");
			$dest = $sortd;
		}
		if($arfile =~ /.*\.rar$/) {
			if($ifexists eq "OVERWRITE") {
				$over = "+";
			} else {
				$over = "-";
			}

			if(num_found_in_list(system("rar e -o$over \"$arfile\" \"$dest\""), @errors) eq "FALSE") {
				out("std", "RAR: extracting $arfile into $dest\n");
			} elsif(num_found_in_list(system("unrar e -o$over \"$arfile\" \"$dest\""), @errors) eq "FALSE") {
				out("std", "UNRAR: extracting $arfile into $dest\n");
			} elsif(num_found_in_list(system("7z e -y \"$arfile\" -o\"$dest\""), @errors) eq "FALSE") {
				out("std", "7ZIP: extracting $arfile into $dest\n");
			} elsif(num_found_in_list(system("7za e -y \"$arfile\" -o\"$dest\""), @errors) eq "FALSE") {
				out("std", "7ZIP: extracting $arfile into $dest\n");
			} elsif(num_found_in_list(system("C:\\Program Files\\7-Zip\\7z.exe e -y \"$arfile\" -o\"$dest\""), @errors) eq "FALSE") {
				out("std", "7ZIP: extracting $arfile into $dest\n");
			} else {
				out("std", "WARN: the rar / 7zip program could not be found (or an error occurred), not decompressing $arfile\n");
			}
		} elsif($arfile =~ /.*\.zip$/) {
			if($ifexists eq "OVERWRITE") {
				$over = "-o";
			} else {
				$over = "-n";
			}

			if(num_found_in_list(system("unzip $over \"$arfile\" -d \"$dest\""), @errors) eq "FALSE") {
				out("std", "RAR: extracting $arfile into $dest\n");
			} elsif(num_found_in_list(system("7z e -y \"$arfile\" -o\"$dest\""), @errors) eq "FALSE") {
				out("std", "7ZIP: extracting $arfile into $dest\n");
			} elsif(num_found_in_list(system("7za e -y \"$arfile\" -o\"$dest\""), @errors) eq "FALSE") {
				out("std", "7ZIP: extracting $arfile into $dest\n");
			} elsif(num_found_in_list(system("C:\\Program Files\\7-Zip\\7z.exe e -y \"$arfile\" -o\"$dest\""), @errors) eq "FALSE") {
				out("std", "7ZIP: extracting $arfile into $dest\n");
			} else {
				out("std", "WARN: the unzip / 7zip program could not be found (or an error occurred), not decompressing $arfile\n");
			}
		} elsif($arfile =~ /.*\.(?:7z|gz|bz2)$/) {
			if(num_found_in_list(system("7z e -y \"$arfile\" -o\"$dest\""), @errors) eq "FALSE") {
				out("std", "7ZIP: extracting $arfile into $dest\n");
			} elsif(num_found_in_list(system("7za e -y \"$arfile\" -o\"$dest\""), @errors) eq "FALSE") {
				out("std", "7ZIP: extracting $arfile into $dest\n");
			} elsif(num_found_in_list(system("C:\\Program Files\\7-Zip\\7z.exe e -y \"$arfile\" -o\"$dest\""), @errors) eq "FALSE") {
				out("std", "7ZIP: extracting $arfile into $dest\n");
			} else {
				out("std", "WARN: the 7zip program could not be found (or an error occurred), not decompressing $arfile\n");
			}
		}
	}
}

sub display_time {
	my ($second, $minute, $hour, $dayofmonth, $month, $yearoffset) = localtime();
	my $year = 1900 + $yearoffset;
	my $thetime = "$hour:$minute:$second, $dayofmonth-$month-$year";
	out("std", "$thetime\n"); 
}

sub rename_episode {
	my ($pureshowname, $series, $episode, $file) = @_;

	out("verbose", "INFO: trying to rename $pureshowname season $series episode $episode\n");
	# test if it matches a simple version, or a substituted version of the file to move
	move_an_ep($file, path($file), path($file), $series, $episode);
	return 1;
}

sub dir_matching_show_name {
	my ($tvdir, $pureshowname, $showname, $year) = @_;
	out("verbose", "INFO: trying to move $pureshowname season $series episode $episode\n");
	# try once with a year, then recursively once without
	foreach my $show (bsd_glob($tvdir.'*')) {
		# test if it matches a simple version, or a substituted version of the file to move
		my $subshowname = fixtitle(escape_myfilename(resolve_show_name($pureshowname)));
		if(fixtitle(filename($show)) =~ /^\Q$showname\E$/i || fixtitle(escape_myfilename(filename($show))) =~ /^\Q$subshowname\E$/i) {
			# and if a year is included try finding one where year matches the dir
			if($year) {
				if ($show =~ /.*(?:\.|\s|-|\(|\[)*\(?((?:20|19)\d{2})(?:\)|\])?$/){
					my $diryear = $1;
					if(abs($diryear - $year) <= $yeartoleranceforerror) {
						return $show;
					}
				}
			} else {
				return $show;
			}
		}
	}

	# if we are here then we couldn't find a matching show
	if ($year) {
		out("std", "INFO: Could not find a show directory for $pureshowname matching the year $year, trying ignoring the year...\n");
		return dir_matching_show_name($tvdir, $pureshowname, $showname, "");
	}
	if($needshowexist ne "TRUE" && !$year) {
		# we couldn't find a matching show (and we are not looking for year specific), make DIR
		my $newshow = escape_myfilename(resolve_show_name($pureshowname));
		if($usedots eq "TRUE") {
			$newshow =~ s/\s/./ig;
		}
		my $newshowdir = $tvdir . $newshow;
		out("std", "INFO: making show directory: $newshowdir\n");
		if(mkdir($newshowdir, 0777)) {
			chmod(oct($dir_perms), $newshowdir) if defined $dir_perms;
			fetchshowimages(resolve_show_name($pureshowname), $newshowdir) if $fetchimages ne "FALSE";
			return $newshowdir;
		} else {
			out("warn", "WARN: Could not create show dir: $newshowdir:$!\n");
			return 0;
		}
	}
}

sub dir_matching_season {
	my ($show, $series, $pureshowname, $make_or_check) = @_;

	foreach my $season (bsd_glob($show.'/*')) {
		if(-d $season.'/' && $season =~ /(?:Season|Series|$seasontitle)?\s?0*(\d+)$/i && $1 == $series) {
			return $season;
		}
	}
	# didn't find a matching season, make DIR
	if($make_or_check eq "check") {
		return 0;
	}
	out("std", "INFO: making season directory: $show/$seasontitle$series\n");
	my $newdir = $seasontitle.$series;
	if($usedots eq "TRUE") {
		$newdir =~ s/\s/./ig;
	}
	my $newpath = "$show/$newdir";
	if(mkdir($newpath, 0777)) {
		chmod(oct($dir_perms), $newpath) if defined $dir_perms;
		fetchseasonimages(resolve_show_name($pureshowname), $show, $series, $newpath) if $fetchimages ne "FALSE";
		return $newpath; # try again now that the dir exists
	} else {
		out("warn", "WARN: Could not create season dir: $!\n");
		return 0;
	}
}

# attempts to sort an episode by searching for and possibly creating the dirs in which to place it
# if a year is included in the show name, trys to find the show&year or warns and trys w/o year
sub move_episode {
	my ($pureshowname, $showname, $series, $episode, $year, $file) = @_;
	my $show = dir_matching_show_name($tvdir, $pureshowname, $showname, $year);
	if($show) {
		out("verbose", "INFO: found a matching show:\n\t$show\n");
		my $season;
		if($useseasondirs eq "TRUE") {
			$season = dir_matching_season($show, $series, $pureshowname, "make");
		} else {
			out("verbose", "INFO: not using a season directory.\n");
			$season = $show;
		}
		if($season) {
			out("verbose", "INFO: found a matching season directory:\n\t$season\n");
			move_an_ep($file, $season, $show, $series, $episode);
			return 1;
		}
	} else {
		out("verbose", "SKIP: Show directory does not exist: " . $tvdir . escape_myfilename(resolve_show_name($pureshowname))."\n");
	}
	return 0;
}

sub fetchshowimages {
	my ($fetchname, $newshowdir) = @_;
	if($^O =~ /MSWin/) {
		out("std", "WARN: not downloading TV images, not supported on Windows.\n");
		return;
	}
	out("std", "DOWNLOAD: downloading images for $fetchname\n");

	my ($poster, $fanart, $banner);
	eval {
		$SIG{ALRM} = sub {die "timed out\n"};
		alarm 20;

		$poster = $tvdb->getSeriesPoster($fetchname);
		$fanart = $tvdb->getSeriesFanart($fetchname);
		$banner = $tvdb->getSeriesBanner($fetchname);

		alarm 0;
		$SIG{ALRM} = sub {};
	};
	if($@ eq "timed out\n") {
		out("verbose", "INFO: Timed out downloading TV images.\n");
	} elsif($@) {
		out("verbose", "INFO: Failed to download TV images: $@.\n");
	}

	if($dryrun) {
		out("std", "DRYRUN: not copying images.\n");
		return;
	}
	copy ("$scriptpath/.cache/$fanart", "$newshowdir/fanart.jpg") if $fanart && -e "$scriptpath/.cache/$fanart";
	copy ("$scriptpath/.cache/$banner", "$newshowdir/banner.jpg") if $banner && -e "$scriptpath/.cache/$banner";
	copy ("$scriptpath/.cache/$poster", "$newshowdir/poster.jpg") if $poster && -e "$scriptpath/.cache/$poster";
	# if configured to symlink
	my $ok = 1;
	if($duplicateimages eq "SYMLINK") {
		if ($poster && -e "$scriptpath/.cache/$poster" && $imagesformat eq "POSTER") {
			$ok = eval{symlink "$newshowdir/poster.jpg", "$newshowdir/folder.jpg";};
		} elsif ($banner && -e "$scriptpath/.cache/$banner" && $imagesformat eq "BANNER") {
			$ok = eval{symlink "$newshowdir/banner.jpg", "$newshowdir/folder.jpg";};
		}
	}
	# if not symlink, or symlink failed
	if($duplicateimages ne "SYMLINK" || !defined $ok) {
		if($poster && -e "$scriptpath/.cache/$poster" && $imagesformat eq "POSTER") {
			copy "$newshowdir/poster.jpg", "$newshowdir/folder.jpg";
		} elsif ($banner && -e "$scriptpath/.cache/$banner" && $imagesformat eq "BANNER") {
			copy "$newshowdir/banner.jpg", "$newshowdir/folder.jpg";
		}
	}
}

sub fetchseasonimages {
	my ($fetchname, $newshowdir, $season, $seasondir) = @_;
	if($^O =~ /MSWin/) {
		out("std", "WARN: not downloading TV images, not supported on Windows.\n");
		return;
	}
	out("std", "DOWNLOAD: downloading season image for $fetchname\n");

	my ($banner, $bannerwide);
	eval {
		$SIG{ALRM} = sub {die "timed out\n"};
		alarm 20;

		$banner = $tvdb->getSeasonBanner($fetchname, $season);
		$bannerwide = $tvdb->getSeasonBannerWide($fetchname, $season);

		alarm 0;
		$SIG{ALRM} = sub {};
	};
	if($@ eq "timed out\n") {
		out("verbose", "INFO: Timed out downloading TV images.\n");
	} elsif($@) {
		out("verbose", "INFO: Failed to download TV images: $@.\n");
	}

	if($dryrun) {
		out("std", "DRYRUN: not copying images.\n");
		return;
	}
	my $snum = sprintf("%02d", $season);
	copy ("$scriptpath/.cache/$banner", "$newshowdir/season${snum}.jpg") if $banner && -e "$scriptpath/.cache/$banner" && $imagesformat eq "POSTER";
	copy ("$scriptpath/.cache/$bannerwide", "$newshowdir/season${snum}.jpg") if $bannerwide && -e "$scriptpath/.cache/$bannerwide" && $imagesformat eq "BANNER";
	my $ok = 1;
	if (-e "$newshowdir/season$snum.jpg") {
		# if configured to symlink
		if($duplicateimages eq "SYMLINK") {
			$ok = eval{symlink "$newshowdir/season$snum.jpg", "$seasondir/folder.jpg";};
		}
		# if not symlink, or symlink failed
		if($duplicateimages ne "SYMLINK" || !defined $ok) {
			copy "$newshowdir/season$snum.jpg", "$seasondir/folder.jpg";
		}
	}
}

sub fetchepisodeimage {
	if($^O =~ /MSWin/) {
		out("std", "WARN: not downloading TV images, not supported on Windows.\n");
		return;
	}
	my ($fetchname, $newshowdir, $season, $seasondir, $episode, $newfilename) = @_;

	my $epimage;
	eval {
		$SIG{ALRM} = sub {die "timed out\n"};
		alarm 10;

		$epimage = $tvdb->getEpisodeBanner($fetchname, $season, $episode);

		alarm 0;
		$SIG{ALRM} = sub {};
	};
	if($@ eq "timed out\n") {
		out("verbose", "INFO: Timed out downloading TV episode image.\n");
	} elsif($@) {
		out("verbose", "INFO: Failed to download TV episode image: $@.\n");
	}

	if($dryrun) {
		out("std", "DRYRUN: not copying images.\n");
		return;
	}
	eval { # ignore errors
		my $newimagepath = "$seasondir/$newfilename";
		$newimagepath =~ s/(.*)(\..*)/$1.tbn/;
		copy ("$scriptpath/.cache/$epimage", $newimagepath) if $epimage && -e "$scriptpath/.cache/$epimage";
	};
}

# lookup episode details based on show name and episode title or air date
sub fetchseasonep {
	my ($show, $eptitle) = @_;
	# make sure we have all the series data in cache
	my $seriesall = $tvdb->getSeries(resolve_show_name($show));
	my @seasonep;
	# get the show name from the hash
	my $showtitle = $seriesall->{'SeriesName'};
	if(defined $showtitle) {
		if($eptitle =~ /\d{4}-\d{2}-\d{2}/){
			out("verbose", "INFO: Looking for episode of $showtitle aired on $eptitle.\n");
			# get episode details from show title and air date
			my $epdetails = $tvdb->getEpisodeByAirDate($showtitle, $eptitle);
			if(defined($epdetails)) {
				$seasonep[0] = $epdetails->[0]->{'SeasonNumber'};
				$seasonep[1] = $epdetails->[0]->{'EpisodeNumber'};
				#temporary solution to episode number over 49
				$forceeptitle = $epdetails->[0]->{'EpisodeName'} if $seasonep[1] >= 50;
				# pass back the Season Number and Episode Number in an array
				return @seasonep;
			}
		} else {
			out("verbose", "INFO: Looking for episode of $showtitle named $eptitle.\n");
			my $season = 1;
			# work through the seasons
			while(1) {
				my @epid;
				my $seasonok = "FALSE";
				eval {
					$SIG{ALRM} = sub {die "timed out\n"};
					out("verbose", "INFO: Fetching season $season episode list.\n");
					alarm 1;
					@epid = $tvdb->getSeason($showtitle, $season);
					alarm 0;
					$SIG{ALRM} = sub {};
					$seasonok = "TRUE";
				};
				# if no more seasons, exit loop
				if($@) {
					if($@ eq "timed out\n") {
						out("verbose", "INFO: Timed out getting season $season details, likely does not exist.\n");
					} else {
						out("verbose", "INFO: Failed to get season $season details: $@.\n");
					}
					last;
				} elsif($seasonok eq "FALSE") {
					last; # if no more seasons, exit loop
				}
				# testing showed that the episode list contains some undefs, so know how many good values we will get
				my $numdefined = scalar(@{$epid[0]});
				my $spot = 1;
				# process each episode id
				# keep looping if the season exists and it has eps
				while($epid[0] && $numdefined) {
					if(defined($epid[0][$spot])) {
						my $epdetails = $tvdb->getEpisodeId($epid[0][$spot]);
						# ignore any errors
						eval{ if($epdetails && exists $epdetails->{'EpisodeName'}) {
							# compare the Episode to the one in the search
							if(fixtitle($epdetails->{'EpisodeName'}) =~ /^\Q$eptitle\E$/) {
								$seasonep[0] = $epdetails->{'SeasonNumber'};
								$seasonep[1] = $epdetails->{'EpisodeNumber'};
								#temporary solution to episode number over 49
								$forceeptitle = $epdetails->{'EpisodeName'} if $seasonep[1] >= 50;
								# pass back the Season Number and Episode Number in an array
								return @seasonep;
							}
						}};
					}
					if($spot < $numdefined) {
						$spot++;
					} else {
						last;
					}
				}
				$season++;
			}
		}
	} else {
		out("std", "WARN: Failed to get " . $show . " series information on the tvdb.com.\n");
	}
	return @seasonep;
}

# if the option is enabled, looks up the show title using the substitute_tvdb_id then the filename
# returns the title with the format from thetvdb.com, or if not found the original string
sub tvdb_title {
	my ($filetitle) = @_;
	# if the show name is only special chars then leave as is
	if (!$filetitle) {
		$filetitle = $pureshowname;
	}
	if($tvdbrename eq "TRUE") {
		my $id_sub = substitute_tvdb_id($filetitle);
		if($id_sub =~ /^[+-]?\d+$/) {
			my $newname = $tvdb->getSeriesName($id_sub);
			if($newname) {
				return $newname;
			}
		}
		my $retval;
		$retval = $tvdb->getSeries($filetitle);
		# if it finds one return it
		if(defined($retval)) {
			return $retval->{'SeriesName'};
		}		
	}
	return $filetitle;
}

# for now, just finds quality as specified in the file name
sub extract_quality {
	my ($file) = @_;
	my $filename = filename($file);
	foreach my $qual ("Bluray", "BlurayRip", "HD", "720p", "1080p", "High definition") {
		if($filename =~ /\b$qual\b/i) {
			# look no further
			return " HD";
		}
	}
	foreach my $qual ("DVD", "SD", "DVDRip") {
		if($filename =~ /\b$qual\b/i) {
			return " SD";
		}
	}
}

sub move_an_ep {
	my($file, $season, $show, $series, $episode) = @_;
	my $newfilename = filename($file);
	my $newpath;
	my $sendxbmcnotifications = $xbmcoldwebserver;
	$sendxbmcnotifications or $sendxbmcnotifications = $xbmcaddress;
	
	my $ep1 = sprintf("S%02dE%02d", $series, $episode);
	if($rename eq "TRUE") {
		my $ext = my $eptitle = "";
		unless(-d $file) {
			$ext = $file;
			$ext =~ s/(.*\.)(.*)/\.$2/;
		}
		if($renameformat =~ /\[EP_NAME(\d)]/i) {
			out("verbose", "INFO: Fetching episode title for ", resolve_show_name($pureshowname), " Season $series Episode $episode.\n");
			my $name = "";
			# HACK - setConf maxEpisode apparently doesn't register, temporary fix
			if(defined($forceeptitle)&& $forceeptitle ne "") {
				# set it if you had to force a ep title
				$name = $forceeptitle;
				# forget so we can be fresh for the next file
				$forceeptitle = "";
			} else {
				my $showtitle = substitute_tvdb_id(resolve_show_name($pureshowname));
				# if that episode exists
				my $tvdbname;
				eval { # try
					$tvdbname = $tvdb->getEpisodeName($showtitle, $series, $episode);
				};
				if($tvdbname) {
					$name = $tvdbname;
				} else {
					# if the episode name is required, and not available, skip this file
					if($tvdbrequired eq "TRUE") {
						out("warn", "SKIP: Failed to retrieve episode name from thetvdb\n");
						return;
					}
				}
			}
			my $format = $1;
			if($name) {
				$name =~ s/\s+$//;
				# support for utf8 characters in episode names
				eval { # try
					require Encode;
					$eptitle = " - " . Encode::decode_utf8( $name ) if $format == 1;
					$eptitle = "." . Encode::decode_utf8( $name ) if $format == 2;
				};
				if($@) { # catch
					out("warn", "WARN: Could not encode episode title: $@.\n");
				};

			} else {
				out("warn", "WARN: Could not get episode title for ", resolve_show_name($pureshowname), " Season $series Episode $episode.\n");
			}
		}
		my $sname = resolve_show_name($pureshowname);
		my $ep2 = sprintf("%dx%d", $series, $episode);
		my $ep3 = sprintf("%dx%02d", $series, $episode);
		my $ep4 = sprintf("%02d", $episode);
		# create the new file name
		$newfilename = $renameformat;
		$newfilename =~ s/\[SHOW_NAME]/$sname/ig;
		$newfilename =~ s/\[EP1]/$ep1/ig;
		$newfilename =~ s/\[EP2]/$ep2/ig;
		$newfilename =~ s/\[EP3]/$ep3/ig;
		$newfilename =~ s/\[EP4]/$ep4/ig;
		$newfilename =~ s/\[EP_NAME\d]/$eptitle/ig;
		if($newfilename =~ /\[QUALITY]/i) {
			my $quality = extract_quality($file);
			$newfilename =~ s/\[QUALITY]/$quality/ig;
		}
		# keep any "part 1" etc on the end of the new filename
		if(filename($file) =~ /(\b(?:part|cd|disk)\s?\.?\d+)\b/i) {
			$newfilename .= " $1";
		}
		$newfilename .= $ext;
		# make sure it is filesystem friendly and contains no slashes:
		$newfilename = cleanup_filename(escape_myfilename($newfilename, "-"));
	}
	if($usedots eq "TRUE") {
		$newfilename =~ s/\s/./ig;
	}
	$newpath = $season;
	$newpath .= '/' if($newpath !~ /\/$/);
	$newpath .= $newfilename;
	unless($verbose || ($sortby ne "COPY" && $sortby ne "PLACE-SYMLINK")) {
		$sendxbmcnotifications = "";
	}
	if(sort_file($file, $newpath, "EPISODE") eq "TRUE") {
		# if the episode was moved...
		if ($fetchimages ne "FALSE") {
			fetchepisodeimage(resolve_show_name($pureshowname), $show, $series, $season, $episode, $newfilename);
		}
		if($sendxbmcnotifications) {
			$new = resolve_show_name($pureshowname) . " $ep1";
			$newshows .= "$new\n";
			if($sendxbmcnotifications && $xbmcoldwebserver) {
				my $retval = get "http://$xbmcoldwebserver/xbmcCmds/xbmcHttp?command=ExecBuiltIn(Notification(NEW EPISODE, $new, 7000))";
				if(undef($retval)) {
					out("warn", "WARN: Could not connect to xbmc webserver.\nRECOMMENDATION: If you do not use this feature you should disable it in the configuration file.\n");
					$xbmcoldwebserver = "";
				}
			}
		}
	}
}

# moves, copies or symlinks the file to the destination
sub sort_file {
	my ($file, $newpath, $msg) = @_;
	# returns whether to display a message
	my $retval = 'FALSE';
	if(-e $newpath) {
		if(filename($file) =~ /repack|proper/i) {
			# still overwrites if copying, but doesn't output a message unless verbose
			if($verbose || ($sortby ne "COPY" && $sortby ne "PLACE-SYMLINK")) {
				out("warn", "OVERWRITE: Repack/proper version.\n");
				out("std", "$sortby $msg: sorting $file --to--> ", $newpath, "\n");
			} # elsewhere: else $sendxbmcnotifications = ""
			$retval = 'TRUE';
		} elsif($ifexists eq "OVERWRITE") {
			out("warn", "OVERWRITE: Existing file.\n");
			out("std", "$sortby $msg: sorting $file --to--> ", $newpath, "\n");
			$retval = 'TRUE';
		} elsif($ifexists eq "SKIP") {
			if($verbose || ($sortby ne "COPY" && $sortby ne "PLACE-SYMLINK")) {
				out("warn", "SKIP: File $newpath already exists, skipping.\n");
			}
			return $retval;
		}
	} else {
		out("std", "$dryrun$sortby $msg: sorting $file --to--> ", $newpath, "\n");
		$retval = 'TRUE';
	}
	if($sortby eq "MOVE" || $sortby eq "MOVE-AND-LEAVE-SYMLINK-BEHIND") {
		if(-d $file) {
			$dryrun or dirmove($file, $newpath) or out("warn", "File $file cannot be moved to $newpath. : $!");
		} else {
			$dryrun or move($file, $newpath) or out("warn", "File $file cannot be moved to $newpath. : $!");
		}
	} elsif($sortby eq "COPY") {
		if(-d $file) {
			$dryrun or dircopy($file, $newpath) or out("warn", "File $file cannot be copied to $newpath. : $!");
		} else {
			$dryrun or copy($file, $newpath) or out("warn", "File $file cannot be copied to $newpath. : $!");
		}
	} elsif($sortby eq "PLACE-SYMLINK") {
		$dryrun or symlink($file, $newpath) or out("warn", "File $file cannot be symlinked to $newpath. : $!");
	} elsif($sortby eq "PLACE-HARDLINK") {
		$dryrun or link($file,$newpath) or out("warn", "File $file cannot be hardlinked to $newpath. : $!");
	}
	# have moved now link
	if($sortby eq "MOVE-AND-LEAVE-SYMLINK-BEHIND") {
		$dryrun or symlink($newpath, $file) or out("warn", "File $newpath cannot be symlinked to $file. : $!");
	}
	return $retval;
}

sub move_a_season {
	my($file, $show, $series) = @_;
	my $newpath = $show."/".escape_myfilename("$seasontitle$series", "-");
	if(-e $newpath) {
		out("warn", "SKIP: File $newpath already exists, skipping.\n") unless($sortby eq "COPY" || $sortby eq "PLACE-SYMLINK");
		return;
	}
	out("std", "$dryrun$sortby SEASON: $file sorting $file --to--> $newpath\n");
	out("verbose", "$sortby: sorting directory to: $newpath\n");
	if($sortby eq "MOVE" || $sortby eq "MOVE-AND-LEAVE-SYMLINK-BEHIND") {
		$dryrun or dirmove($file, "$newpath") or out("warn", "$show cannot be moved to $show/$seasontitle$series: $!");
	} elsif($sortby eq "COPY") {
		$dryrun or dircopy($file, "$newpath") or out("warn", "$show cannot be copied to $show/$seasontitle$series: $!");
	} elsif($sortby eq "PLACE-SYMLINK") {
		$dryrun or symlink($file, $newpath) or out("warn", "File $file cannot be symlinked to $newpath. : $!");
	} elsif($sortby eq "PLACE-HARDLINK") {
		$dryrun or link($file,$newpath) or out("warn", "File $file cannot be hardlinked to $newpath. : $!");
	}
	if($sortby eq "MOVE-AND-LEAVE-SYMLINK-BEHIND") {
		$dryrun or symlink($newpath, $file) or out("warn", "File $newpath cannot be symlinked to $file. : $!");
	}
}

# move a new Season x directory
sub move_series {
	my ($pureshowname, $showname, $series, $year, $file) = @_;
	my $show = dir_matching_show_name($tvdir, $pureshowname, $showname, $year);
	if($show) {
		out("verbose", "INFO: found a matching show:\t$show\n");
		my $season = dir_matching_season($show, $series, $pureshowname, "check");
		if($season) {
			out("warn", "SKIP: Cannot move season directory: found a matching season already existing:\n\t$season\n");
			return 0;
		} else {
			# found a show without a matching season, move DIR
			move_a_season($file, $show, $series);
			if($xbmcoldwebserver || $xbmcaddress) {
				$new = "$showname Season $series directory";
				$newshows .= "$new\n";
				if($xbmcoldwebserver) {
					get "http://$xbmcoldwebserver/xbmcCmds/xbmcHttp?command=ExecBuiltIn(Notification(NEW EPISODE, $new, 7000))";
				}
			}
			return 1;
		}
	}
	return 0;
}

# Matches the title and year to known movies
# If a match is found, the file is sorted
# Returns whether it was sorted (TRUE or FALSE)
sub match_and_sort_movie {
	my ($title, $year, $ext, $file) = @_;

	out("verbose",  "INFO: Looking for movie matching $title using the movie db\n");
	
	# all is well and we have at least one match
	my $parsed_json_result;
	eval {
		$parsed_json_result = parse_json ($tmdb->Search::movie({
			'query' => fixpurename($title)
		}));
	};
	if($@) {
		out("warn",  "WARN: Encountered error converting JSON.\n");
		return "FALSE";
	}
	my $total_pages = $parsed_json_result->{total_pages};
	my $total_results = $parsed_json_result->{total_results};
	unless($total_results > 0) {
		out("verbose",  "INFO: No movies matching $title found\n");
		return "FALSE";
	}
	out("verbose",  "INFO: $total_results movies are similar to $title, checking if they are close enough matches...\n");

	my $page_index;
	PAGE: for($page_index = 1; $page_index <= $total_pages; $page_index++) {
		out("verbose",  "INFO: Fetching page $page_index of results\n");
		eval {
			$parsed_json_result = parse_json ($tmdb->Search::movie({
				'query' => fixpurename($title),
				'page' => $page_index
			}));
		};
		if($@) {
			out("warn",  "WARN: Encountered error converting JSON.\n");
		}
		my $result_index = 0;
		my $movie;
		MOVIE: while($movie = $$parsed_json_result{"results"}[$result_index]) {
			$result_index++;
			out("verbose",  "Processing results page $page_index #$result_index: ...\n");
			
			my $baseimgURL = "http://d3gtl9l2a4fn1j.cloudfront.net/t/p/original/";
			my $id = $$movie{"id"} if $$movie{"id"};
			my $moviename = $$movie{"title"} if $$movie{"title"};
			my $altname = $$movie{"alternative_name"} if $$movie{"alternative_name"};
			my $orgname = $$movie{"original_name"} if $$movie{"original_name"};
			my $released = $$movie{"release_date"} if $$movie{"release_date"};
			my $poster = $baseimgURL . $$movie{"poster_path"} if $$movie{"poster_path"};
			my $backdrop = $baseimgURL . $$movie{"backdrop_path"} if $$movie{"backdrop_path"};
			{
				no warnings 'uninitialized';
				out("verbose",  "INFO: Comparing $title to $moviename,$altname,$orgname\n");
			}
			if(fixtitle($moviename) eq fixtitle($title)
			|| (defined $altname && scalar $altname && fixtitle($altname) eq fixtitle($title))
			|| (defined $orgname && scalar $orgname && fixtitle($orgname) eq fixtitle($title))) {
				out("verbose",  "INFO: Title matches\n");
				# choose title to use
				my $movietitle = defined $orgname ? $orgname : defined $altname ? $altname : $moviename;
				# remove any slashes from the title
				$movietitle = cleanup_filename($movietitle);
				my $released_year;
				if($released && $released =~ /(\d{4})-\d{2}-\d{2}/) {
					$released_year = $1;
				} else {
					out("warn", "WARN: could not extract year from online movie informaton ($movietitle)\n");
				}
				if($year && $released_year) {
					if(abs($released_year - $year) <= $yeartoleranceforerror) {
						out("verbose", "INFO: Year also matches\n");
						my $rating = get_rating($id);
						sort_movie($file, $movietitle, $released_year, $ext, $poster, $backdrop, $rating);
						return "TRUE";
					} else {
						out("warn", "WARN: Found matching movie '$movietitle', but does not match year in filename (named $year not $released_year), skipping\n");
						next MOVIE;
					}
				} else {
					# choose year to use
					my $rating = get_rating($id);
					my $yeartouse = $year ? $year : $released_year ? $released_year : "";
					sort_movie($file, $movietitle, $yeartouse, $ext, $poster, $backdrop, $rating);
					return "TRUE";
				}
			} 
		}
	}		

	# at this point, we didn't find a match
	return "FALSE";
}

sub sort_movie {
	my ($file, $title, $year, $ext, $posterimg, $backimg, $mpaa_rating) = @_;
	my ($mdir, $dest);
	my $sendxbmcnotifications = $xbmcoldwebserver;
	$sendxbmcnotifications or $sendxbmcnotifications = $xbmcaddress;

	if($rename eq "TRUE") {
		my $location = $movierenameformat;
		# if we are sorting a directory, ignore directories in the rename format
		if(-d $file) {
			$location =~ s/[\/].*//ig;
		}
		$location =~ s/\[MOVIE_TITLE]/$title/ig;
		$location =~ s/\[RATING]/$mpaa_rating/ig;
		if($year) {
			$location =~ s/\[YEAR1]/($year)/ig;
			$location =~ s/\[YEAR2]/$year/ig;
		} else {
			$location =~ s/[. -]*\[YEAR1]//ig;
			$location =~ s/[. -]*\[YEAR2]//ig;
		}
		if($location =~ /\[QUALITY]/i) {
			my $quality = extract_quality($file);
			$location =~ s/\[QUALITY]/$quality/ig;
		}
		# keep any "part 1" etc on the end of the new filename
		if(filename($file) =~ /(\b(?:part|cd|disk)\s?\.?\d+)\b/i) {
			$location .= " $1";
		}

		$location =~ s/$/$ext/ig;

		$dest = escape_myfilename($location);

	} else {
		$dest = filename($file);
	}
	if($usedots eq "TRUE") {
		$dest =~ s/\s/./ig;
	}
	# set the destination, and create the directory if we need to
	if(-d $file) {
		$mdir = $moviedir.$dest.'/';
	} else {
		$mdir = path($moviedir.$dest);
		out("std", "INFO: Making directory: $mdir\n") unless(-e $mdir);
		$dryrun or make_path($mdir);
	}
	if(sort_file($file, $moviedir.$dest, "MOVIE") eq "TRUE") {
		# if the movie was sorted...
		# download images
		if($dryrun) {
			out("std", "DRYRUN: not downloading movie images.\n");
		} elsif($fetchmovieimages ne "FALSE") {
			my $posterfilename = "${mdir}folder.jpg";
			my $posterfilename_copy = "${mdir}movie.tbn";
			my $fanartfilename = "${mdir}fanart.jpg";
			unless($rename eq "TRUE" && $movierenameformat =~ /\//) {
				$posterfilename = $mdir.filename_without_ext($dest).".jpg";
				$posterfilename_copy = $mdir.filename_without_ext($dest).".tbn";
				$fanartfilename = $mdir.filename_without_ext($dest)."-fanart.jpg";
			}
			out("std", "INFO: Fetching movie images\n");
				my ($status1, $status2);
				eval {
				out("std", "INFO: Downloading poster for $title (from $posterimg to $posterfilename)\n");
				for(my $tries=0;$tries<2&&!LWP::Simple::is_success($status1);$tries++) {
					$status1 = LWP::Simple::getstore( $posterimg, $posterfilename ) || (out("warn", "Failed to download image\n") && next);
				}
				out("std", "INFO: Downloading backdrop for $title (from $backimg to $fanartfilename)\n");
				for(my $tries=0;$tries<2&&!LWP::Simple::is_success($status2);$tries++) {
					$status2 = LWP::Simple::getstore( $backimg, $fanartfilename ) || (out("warn", "Failed to download image\n") && next);
				}
				my $ok = 1;
				if (-e $posterfilename) {
					# if configured to symlink
					if($duplicateimages eq "SYMLINK") {
						$ok = eval{symlink $posterfilename, $posterfilename_copy;};
					}
					# if not symlink, or symlink failed
					if($duplicateimages ne "SYMLINK" || !defined $ok) {
						copy $posterfilename, $posterfilename_copy;
					}
				}
				};
# 			}
		}
		if($sendxbmcnotifications) {
			my $new = "$title $year";
			$newshows .= "$new\n";
			if($sendxbmcnotifications && $xbmcoldwebserver) {
				my $retval = get "http://$xbmcoldwebserver/xbmcCmds/xbmcHttp?command=ExecBuiltIn(Notification(NEW MOVIE, $new, 7000))";
				if(undef($retval)) {
					out("warn", "WARN: Could not connect to xbmc webserver.\nRECOMMENDATION: If you do not use this feature you should disable it in the configuration file.\n");
					$xbmcoldwebserver = "";
				}
			}
		}
	}
}

sub get_rating {
	my ($id) = @_;
	my $parsed_json_result;
	my $result_index;
	my $mpaa;
	
	out("verbose",  "Checking for US MPAA Rating...\n");
	#ID was captured correctly and we have a match
	eval {
		$parsed_json_result = parse_json ($tmdb->Movies::releases({
			'movie_id' => $id
		}));
	};
	if($@) {
		out("warn",  "WARN: Encountered error converting JSON.\n");
		return "FALSE";
	}

	my $total_results = scalar @{$parsed_json_result->{countries}};
	MPAA: for($result_index = 0; $result_index <= $total_results; $result_index++) {
		# Make sure we are getting the US rating
		if($parsed_json_result->{countries}[$result_index]{iso_3166_1} eq "US") {
			$mpaa = $parsed_json_result->{countries}[$result_index]{certification};
			if ($mpaa eq "") {
				$mpaa = "NR";
			}
			out("verbose",  "MPAA rating found! Rated: $mpaa\n");
			# Remove those nasty PG-13 / NC-17 hyphens
			$mpaa =~ s/-//g;
			# Send it back
			return $mpaa;
		} else {
			# Wasn't the US rating, moving on...
			out("verbose",  "Not US rating: $parsed_json_result->{countries}[$result_index]{iso_3166_1}\n");
		}
	}
	return "NR";
}

sub out {
	my ($type, @msg) = @_;
	
	if($type eq "verbose") {
		return if !$verbose;
		print @msg;
		print $log @msg if(defined $log);
	} elsif($type eq "std") {
		print @msg;
		print $log @msg if(defined $log);
	} elsif($type eq "warn") {
		warn @msg;
		print $log @msg if(defined $log);
	}
}
