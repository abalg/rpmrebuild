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
VERSION="$Id$"
###############################################################################
function Usage
{
	echo -e "\nrpmrebuild.sh is a tool to rebuild an rpm file from the rpm database"
	echo "syntaxe : $0 [options] package"
	echo "options :"
	echo "-b : batch mode"
	echo "-d dir : specify the working directory"
	echo "-f filter : apply an external filter"
	echo "-h : print this help"
	echo "-k : keep installed files perm"
	echo "-v : verbose"
	echo "-V : print version"
	echo "the spec and rpm result are built on local directory"
	echo "Copyright (C) 2002 by Eric Gerbier"
	echo -e "this program is distributed under GNU General Public License\n"
}
###############################################################################
function Interrog
{
	QF=$1
	rpm --query --queryformat "${QF}" ${PAQUET}
}
###############################################################################
# build general tags
function SpecFile
{
	HOME=$MY_CONFIG_DIR rpm --query --spec_spec ${PAQUET}
}
###############################################################################
# build the list of files in package
function FilesSpecFile
{
	echo "%files"
	HOME=$MY_CONFIG_DIR rpm --query --spec_files ${PAQUET} | rpmrebuild_files.sh
}

##############################################################
# Main Part                                                  #
##############################################################
# shell pour refabriquer un fichier rpm a partir de la base rpm
# a shell to build an rpm file from the rpm database

MY_CONFIG_DIR=/etc/rpmrebuild
# to be sure
export PATH=$PATH:/usr/local/bin

filter=
verbose="--quiet"
while getopts "bd:f:hkvV" opt
do
	case "$opt" in
	b) batch=y;;
	d) workdir=$OPTARG
	if [ -d $workdir ]
	then
		cd $workdir
	elif [  -e $workdir ]
	then
		echo "$workdir is not a directory"
		Usage
		exit 1
	else
		mkdir -p $workdir
		cd $workdir
	fi
	;;
	f) lookfor=$(type -p $OPTARG)
	[ "$lookfor" ] && OPTARG=$lookfor
	[ -f $OPTARG -a -x $OPTARG ] && filter="$filter | $OPTARG";;
	h) Usage; exit 1;;
	k) export keep_perm=1;;
	v) verbose="-v";;
	V) echo "$VERSION"; exit 0;;
	*) Usage; exit 1;;
	esac
done

echo "working dir : $PWD"
#echo "filter= $filter"
#exit

shift $((OPTIND - 1))
if [ $# -ne 1 ]
then
	echo "package argument missing"
	Usage
	exit 1
fi

# suite a des probleme de dates incorrectes
# to solve problems of bad date
export LC_TIME=POSIX

# test if package exists
PAQUET="$1"
output="$(rpm --query ${PAQUET})"
set -- $output
case $# in
   0)
	# No package found
	echo "WARNING : no package '${PAQUET}' in rpm database"
	exit 1
   ;;

   1)
	: # Ok, do nothing
   ;;

   *)
	echo -e "WARNING : too much packages match '${PAQUET}':\n$output"
	exit 1
   ;;
esac

# verification des changements
# check for package change
out="$(rpm --verify --nodeps ${PAQUET})"
if [ -n "$out" ]
then
	echo "WARNING : some files have been modified :"
	echo "$out"
	if [ -z "$batch" ]
	then
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
			old_release=$(Interrog '%{RELEASE}')
			echo -n "enter the new release (old : $old_release) : "
			read new_release
		fi
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

{
   SpecFile &&
   FilesSpecFile
} > ${FIC_SPEC}

if [ -n "$new_release" ]
then
	sed "s/Release:.*/Release: $new_release/" ${FIC_SPEC} > ${FIC_SPEC}.new
	mv -f ${FIC_SPEC}.new ${FIC_SPEC}
fi

# reconstruction fichier rpm : le src.rpm est inutile
# build rpm file, the src.rpm is not usefull to do
# for rpm 4.1 : use rpmbuild
BUILDCMD=rpm
[ -x /usr/bin/rpmbuild ] && BUILDCMD=rpmbuild
$BUILDCMD -bb $verbose --define "_rpmdir $PWD/" ${FIC_SPEC}

QF_RPMFILENAME=$(rpm --eval %_rpmfilename)
RPMFILENAME=$(rpm --query --queryformat "${QF_RPMFILENAME}" ${PAQUET})
echo "result: ${PWD}/${RPMFILENAME}"
exit 0
