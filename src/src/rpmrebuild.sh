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
function Echo
{
   echo -e "$@" 1>&2
}
function Error
{
    Echo "$0: ERROR: $@"
}

function Warning
{
   Echo "$0: WARNING: $@"
}

function Usage
{
   Usage_Message="
$0 is a tool to rebuild an rpm file from the rpm database
syntaxe: $0 [options] package
options:
   -b     : batch mode
   -d dir : specify the working directory
   -e     : edit specfile
   -k     : keep installed files perm
   -v     : verbose
   -V     : print version
   -h     : print this help
the spec and rpm result are built on local directory
Copyright (C) 2002 by Eric Gerbier
this program is distributed under GNU General Public License
"
   Echo "$Usage_Message"
#echo "-f filter : apply an external filter"
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
	HOME=$MY_LIB_DIR rpm --query --spec_spec ${PAQUET}
}
###############################################################################
# build the list of files in package
function FilesSpecFile
{
	echo "%files"
	HOME=$MY_LIB_DIR rpm --query --spec_files ${PAQUET} | $MY_LIB_DIR/rpmrebuild_files.sh
}

##############################################################
# Main Part                                                  #
##############################################################
# shell pour refabriquer un fichier rpm a partir de la base rpm
# a shell to build an rpm file from the rpm database

MY_LIB_DIR=/usr/lib/rpmrebuild

# Default flags' values. To be sure they don't came from environment
batch=""
filter=""
workdir=""
editspec=""
rpm_verbose="--quiet"
export keep_perm=""

while getopts "bd:ef:hkvV" opt
do
	case "$opt" in
		b) 
			batch=y\
		;;

		d) workdir=$OPTARG
			if [ -d $workdir ]
			then
				cd $workdir
			elif [  -e $workdir ]
			then
				Error "$workdir is not a directory"
				exit 1
			else
				mkdir -p $workdir
				cd $workdir
			fi
		;;

		e) 
			editspec=y
		;;
		#f) 
		#	lookfor=$(type -p $OPTARG)
		#
		#	[ "$lookfor" ] && OPTARG=$lookfor
		#
		#	[ -f $OPTARG -a -x $OPTARG ] && filter="$filter | $OPTARG"
		#;;

		h) 
			Usage
			exit 0
		;;

		k) 
			keep_perm=1
		;;

		v) 
			rpm_verbose="-v"
		;;

		V)
			echo "$VERSION"
			exit 0
		;;

		*)
			Usage
			exit 1
		;;
	esac
done

#echo "working dir : $PWD"
#echo "filter= $filter"
#exit

shift $((OPTIND - 1))
if [ $# -ne 1 ]
then
	Error "package argument missing"
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
	Error "no package '${PAQUET}' in rpm database"
	exit 1
   ;;

   1)
	: # Ok, do nothing
   ;;

   *)
	Error "too much packages match '${PAQUET}':\n$output"
	exit 1
   ;;
esac

# verification des changements
# check for package change
out="$(rpm --verify --nodeps ${PAQUET})"
if [ -n "$out" ]
then
	Warning "some files have been modified:\n$out"
	if [ -z "$batch" ]
	then
		echo -n "want to continue (y/n) ? "
		read rep 
		case "$rep" in
			y* | Y*) ;; # Yes, do nothing
			*) exit 1;; # Otherwise no
		esac
		echo -n "want to change release number (y/n) ? "
		read rep
		case "$rep" in
			y* | Y*)
				old_release=$(Interrog '%{RELEASE}')
				echo -n "enter the new release (old: $old_release): "
				read new_release
		esac
	fi
fi

# fabrication fichier spec
# build spec file
FIC_SPEC=./${PAQUET}.spec

if [ -a ${FIC_SPEC} ]
then
	Warning "file ${FIC_SPEC} exists : renamed"
	mv -f ${FIC_SPEC} ${FIC_SPEC}.sav
fi

{
   SpecFile &&
   FilesSpecFile
} > ${FIC_SPEC}

# change release
if [ -n "$new_release" ]
then
	sed "s/Release:.*/Release: $new_release/" ${FIC_SPEC} > ${FIC_SPEC}.new
	mv -f ${FIC_SPEC}.new ${FIC_SPEC}
fi
# -e option : edit the spec file
if [ -n "$editspec" ]
then
	${VISUAL:-${EDITOR:-vi}} ${FIC_SPEC}
fi

# reconstruction fichier rpm : le src.rpm est inutile
# build rpm file, the src.rpm is not usefull to do
# for rpm 4.1 : use rpmbuild
BUILDCMD=rpm
[ -x /usr/bin/rpmbuild ] && BUILDCMD=rpmbuild
$BUILDCMD -bb $rpm_verbose --define "_rpmdir $PWD/" ${FIC_SPEC} || { 
   Error "package '${PAQUET}' build failed"
   exit 1
}

QF_RPMFILENAME=$(rpm --eval %_rpmfilename)
RPMFILENAME=$(rpm --query --queryformat "${QF_RPMFILENAME}" ${PAQUET})
echo "result: ${PWD}/${RPMFILENAME}"

# installation test
# force is necessary to avoid the message : already installed
rpm -U --test --force ${PWD}/${RPMFILENAME} || {
	Error "Testinstall for package '${PAQUET}' failed"
	exit 1
}
exit 0
