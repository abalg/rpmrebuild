#!/bin/bash
###############################################################################
#   rpmrebuild.sh 
#
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
###############################################################################
function Usage
{
	echo -e "\nrpmrebuild.sh is a tool to rebuild an rpm file from the rpm database"
	echo "syntaxe : $0 package"
	echo "the spec and rpm result are built on local directory"
	echo "Copyright (C) 2002 by Eric Gerbier"
	echo -e "this program is distributed under GNU General Public License\n"
}
###############################################################################
function interrog
{
	QF=$1
	rpm --query --queryformat "${QF}" ${PAQUET}
}
###############################################################################
# build general tags
function SpecFile
{
	HOME=$MY_DIR rpm --query --spec_spec ${PAQUET}
}
###############################################################################
# build the list of files in package
function FilesSpecFile
{
	echo "%files"
	HOME=$MY_DIR rpm --query --spec_files ${PAQUET} | $MY_DIR/rpmrebuild_files.sh
}

##############################################################
# Main Part                                                  #
##############################################################
# shell pour refabriquer un fichier rpm a partir de la base rpm
# a shell to build an rpm file from the rpm database

MY_DIR=$(dirname $0)
# test argument
if [ $# -ne 1 ]
then
	Usage
	exit 1 
fi

# suite a des probleme de dates incorrectes
# to solve problems of bad date
export LC_TIME=POSIX

# test if package exists
export PAQUET=$1
output=$(rpm -q ${PAQUET})
if [ -z "$output" ]
then
	echo "WARNING : no package ${PAQUET} in rpm database"
	exit 1
else
	nb=$(echo $output | wc -w | awk '{print $1}')
	if [ $nb -ne 1 ]
	then
		echo "WARNING : too much packages match ${PAQUET} : $output"
		exit 1
	fi
fi

# verification des changements
# check for package change
out=$(rpm -V ${PAQUET})
if [ -n "$out" ]
then
	echo "WARNING : some files have been modified :"
	echo "$out"
	echo -n "want to continue (y/n) ?"
	read rep
	if [ "$rep" = 'n' ]
	then
		exit
	fi
	echo -n "want to change release number (y/n) ? "
	read rep
	if [ "$rep" = 'y' ]
	then
		ch_release=y
	fi
fi

# fabrication fichier spec
# build spec file
FIC_SPEC=./${PAQUET}.spec

if [ -a ${FIC_SPEC} ]
then
	echo "file ${FIC_SPEC} exists : renamed"
	mv -f ${FIC_SPEC} ${FIC_SPEC}.sav
fi

QF=""
{
   SpecFile &&
   FilesSpecFile
} > ${FIC_SPEC}

if [ -n "$ch_release" ]
then
	vi ${FIC_SPEC}
fi

# reconstruction fichier rpm : le src.rpm est inutile
# build rpm file, the src.rpm is not usefull to do
rpm -bb --quiet --define "_rpmdir $PWD/" ${FIC_SPEC}

QF_RPMFILENAME=$(rpm --eval %_rpmfilename)
RPMFILENAME=$(rpm --query --queryformat "${QF_RPMFILENAME}" ${PAQUET})
echo "result: ${RPMFILENAME}"
exit 0
