#!/bin/bash
###############################################################################
#   rpmrebuild_dep.sh 
#      it's a part of the rpmrebuild project
#
#    Copyright (C) 2002 by Eric Gerbier
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

#rpm --query --qf '[Requires:      %{REQUIRENAME} %{REQUIREFLAGS:depflags} % {REQUIREVERSION}\n]' rpmrebuild |sort -u| 
function File_to_pac
{

while read tag name remain
do
	if [ -z "$remain" ]
	then
		# is this a file or a package ?
		# a file should have a path
		path=$(dirname $name)
		if [ "$path" != "." ]
		then
			package=$(rpm -qf --qf '%{NAME}' $name)
			echo "$tag $package"
		else
			echo "$tag $name"
		fi
	else
		echo "$tag $name $remain"
	fi
done
}

#rpm --query --qf '[Requires:      %{REQUIRENAME} %{REQUIREFLAGS:depflags} % {REQUIREVERSION}\n]' rpmrebuild | File_to_pac | sort -u
File_to_pac | sort -u

