#!/usr/bin/perl
###############################################################################
#
#    Copyright (C) 2006 by Eric Gerbier
#    Bug reports to: gerbier@users.sourceforge.net
#    $Id: rpmrestore.pl 28 2006-11-13 14:39:50Z gerbier $
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
# automatic test of rpmrerebuild software

use strict;
use warnings;
use Test::More qw(no_plan);
use Data::Dumper;

# arguments test
my $cmd = './rpmrebuild';

# 1 :  no arguments
my $out = `$cmd 2>&1`;
like( $out, qr/il manque le nom du package/, 'no parameter' ) or diag("out=$out\n");

# 2 version
$out = `$cmd --version 2>&1`;
like( $out, qr/\d+\./, 'version' ) or diag("out=$out\n");

# 3 help
$out = `$cmd --help 2>&1`;
like( $out, qr/options:/, 'help' ) or diag("out=$out\n");

# 4 bad package
$out = `$cmd tototo 2>&1`;
like( $out, qr/n'est pas installé/, 'no package' ) or diag("out=$out\n");

# 5 multiple package
$out = `$cmd gpg-pubkey 2>&1`;
like( $out, qr/plusieurs packages correspondent/, 'multiple package' ) or diag("out=$out\n");

# 6 bad file name
$out = `$cmd -p tototo 2>&1`;
like( $out, qr/Fichier non trouvé/, 'no file' ) or diag("out=$out\n");

# 7 file not from package
$out = `$cmd -p Todo 2>&1`;
like( $out, qr/n'est pas un fichier rpm/, 'not an rpm file' ) or diag("out=$out\n");

# capabilities
# rpmrebuild iputils

# suggests (mandriva)
# rpmrebuild task-pulseaudio

