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

function File_to_pac
{
while read tag name remain
do
	if [ -z "$remain" ]
	then
		liste="$liste $name"
	else
		echo "$tag $name $remain"
	fi
done
if [ -n "$liste" ]
then
	liste_pac=$(rpm --query --qf '%{NAME} ' --whatprovides $liste)
	for pac in $liste_pac
	do
		echo "Requires: $pac"
	done
fi
}

# just for test
#HOME=/usr/lib/rpmrebuild rpm --query --qf '[Requires:      %{REQUIRENAME} %{REQUIREFLAGS:depflags} % {REQUIREVERSION}\n]' rpm | File_to_pac | sort -u

File_to_pac | sort -u

