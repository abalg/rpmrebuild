#!/usr/bin/perl
###############################################################################
#    Copyright (C) 2002 by Eric Gerbier
#    Bug reports to: gerbier@users.sourceforge.net
#    $Id$
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
###############################################################################
# this script is used to extract all rpm tags used in rpmrebuild_rpmqf.src 
# and to display a sorted list
###############################################################################
use strict;
use warnings;

my %tags;

my $fh;
if (open $fh, '<', 'rpmrebuild_rpmqf.src') {
	while (<$fh>) {
		chomp;
		while ( m/\%\{([\w:]+)\}/g ) {
			my ($tag, undef) = split /:/, $1;
			$tags{$tag} = 1;
		}
	}

	close $fh;

} else {
	die "can not open rpmrebuild_rpmqf.src : $!\n";
}

foreach my $k (sort keys %tags ) {
	print "$k\n";
}
