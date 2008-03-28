#!/bin/bash
###############################################################################
#   set_tag.sh
#      it's a part of the rpmrebuild project
#
#    Copyright (C) 2004 by Eric Gerbier
#    Bug reports to: gerbier@users.sourceforge.net
#      or	   : valery_reznic@users.sourceforge.net
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

version=1.0
###############################################################################
function msg () {
	echo >&2 $*
}
###############################################################################
function syntaxe () {
	msg "this plugin allow to replace a tag value in spec file"
	msg "it must be called with change-spec-preamble option"
	msg "-t|--tag yourtag value: set value to tag yourtag"
	msg "-h|--help : this help"
	msg "-v|--version : print plugin version"
	exit 1

}
###############################################################################

# test for arguments
if [ $# -ne 0 ]
then
	case $1 in
	-t | --tag )
		opt_tag=$2
		opt_val=$3
	;;

	-h | --help )
		syntaxe
	;;

        -v | --version )
                msg "$0 version $version";
                exit 1;
        ;;

	*)
		msg "bad option : $1";
		syntaxe
	;;
	esac
else
	syntaxe
fi

# test the way to be called
case $LONG_OPTION in
	change-spec-preamble*)
		;;
	*)	msg "should be called from LONG_OPTION=change-spec-preamble";
		syntaxe
	;;
esac

# replace the tag value of key "opt_tag" by opt_val
sed "s/^$opt_tag: .*/$opt_tag: $opt_val/"
