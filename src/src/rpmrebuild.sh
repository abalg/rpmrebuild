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
###############################################################################
function Error
{
    Echo "$0: ERROR: $@"
}
###############################################################################

function Warning
{
   Echo "$0: WARNING: $@"
}
###############################################################################

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
   -s spec: only generate specfile ( If spec '-' stdout will be used)
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

###############################################################################
function CommandLineParsing
{
# Default flags' values. To be sure they don't came from environment
batch=""
filter=""
rpmdir=""
editspec=""
speconly=""
specfile=""
rpm_verbose="--quiet"
export keep_perm=""
PAQUET=""

while getopts "bd:ef:hks:vV" opt
do
	case "$opt" in
		b) 
			batch=y
		;;

		d) 
			rpmdir="$OPTARG"
			mkdir -p -- "$rpmdir"
			rpmdir="$(cd $rpmdir && echo $PWD)" || {
				Error "Can't changedir to '$rpmdir'"
				exit 1
			}
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

		k) 
			keep_perm=1
		;;

		s)
			spec_only=y
			specfile="$OPTARG"
		;;

		h) 
			Usage
			exit 0
		;;

		v) 
			rpm_verbose="--verbose"
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

# If no rpmdir was specified set variable to the native rpmdir value
if [ -z "$rpmdir" ]
then
   rpmdir="$(rpm --eval %_rpmdir)" || exit
fi

shift $((OPTIND - 1))
if [ $# -ne 1 ]
then
	Error "package argument missing"
	Usage
	exit 1
fi
PAQUET="$1"
}

###############################################################################
function IsPackageInstalled
{
   # test if package exists
   output="$(rpm --query ${PAQUET} 2>&1 | grep -v 'is not installed')" # Don't return here - use output
   set -- $output
   case $# in
      0)
	   # No package found
	   Error "no package '${PAQUET}' in rpm database"
	   return 1
      ;;

      1)
	: # Ok, do nothing
      ;;

      *)
	Error "too much packages match '${PAQUET}':\n$output"
	return 1
      ;;
   esac || return
   return 0
}

###############################################################################
function VerifyPackage
{
	# verification des changements
	# check for package change
	rpm --verify --nodeps ${PAQUET} # Don't return here, st=1 - verify fail 
	return 0
}

###############################################################################
function QuestionsToUser
{
	[ -n "$batch"     ] && return 0 ## batch mode, continue
	[ -n "$spec_only" ] && return 0 ## spec only mode, no questions

	echo -n "want to continue (y/n) ? "
	read rep 
	case "$rep" in
		y* | Y*)   ;; # Yes, do nothing
		*) return 1;; # Otherwise no
	esac

	echo -n "want to change release number (y/n) ? "
	read rep
	case "$rep" in
		y* | Y*)
			old_release=$(Interrog '%{RELEASE}')
			echo -n "enter the new release (old: $old_release): "
			read new_release
		;;
	esac
	return 0
}
###############################################################################
function SpecGenerationOnly
{
	if [ "$specfile" = "-" ]
	then
		{ 
		SpecFile && FilesSpecFile 
		} || return
	else
		{ SpecFile && FilesSpecFile; } > $specfile || return
	fi
	return 0
}

###############################################################################
function SpecGeneration
{
	# fabrication fichier spec
	# build spec file
	FIC_SPEC=${TMPDIR:-/tmp}/rpmrebuild_$$_${PAQUET}.spec
	rm -rf ${FIC_SPEC} || return

	{
		if [ -n "$new_release" ]; then
                   echo "%define new_release $new_release";
                else
                   :
                fi       &&
   		SpecFile &&
   		FilesSpecFile
	} > ${FIC_SPEC} || return
	return 0
}

###############################################################################
function SpecEdit
{
	# -e option : edit the spec file
	if [ -n "$editspec" ]
	then
		${VISUAL:-${EDITOR:-vi}} ${FIC_SPEC}
	fi
	return 0
}

###############################################################################
function RpmBuild
{
	# reconstruction fichier rpm : le src.rpm est inutile
	# build rpm file, the src.rpm is not usefull to do
	# for rpm 4.1 : use rpmbuild
	BUILDCMD=rpm
	[ -x /usr/bin/rpmbuild ] && BUILDCMD=rpmbuild
	$BUILDCMD -bb $rpm_verbose --define "_rpmdir $rpmdir" ${FIC_SPEC} || {
   		Error "package '${PAQUET}' build failed"
   		return 1
	}
	return 0
}

###############################################################################
function RpmFileName
{
	QF_RPMFILENAME=$(rpm --eval %_rpmfilename) || return
	RPMFILENAME=$(rpm --specfile --query --queryformat "${QF_RPMFILENAME}" ${FIC_SPEC}) || return
	[ -n "$RPMFILENAME" ] || return
	RPMFILENAME="${rpmdir}/${RPMFILENAME}"
	return 0
}

###############################################################################
function InstallationTest
{
	# installation test
	# force is necessary to avoid the message : already installed
	rpm -U --test --force ${RPMFILENAME} || {
		Error "Testinstall for package '${PAQUET}' failed"
		return 1
	}
	return 0
}
###############################################################################

function my_exit
{
	st=$?	# save status
	rm -f ${FIC_SPEC} # remove spec file
	exit $st
}
##############################################################
# Main Part                                                  #
##############################################################
# shell pour refabriquer un fichier rpm a partir de la base rpm
# a shell to build an rpm file from the rpm database

MY_LIB_DIR=/usr/lib/rpmrebuild

CommandLineParsing "$@" || exit
IsPackageInstalled      || exit
out=$(VerifyPackage)    || exit
if [ -n "$out" ]
then
	Warning "some files have been modified:\n$out"
	QuestionsToUser || exit
fi

# suite a des probleme de dates incorrectes
# to solve problems of bad date
export LC_TIME=POSIX

if [ -n "$spec_only" ]
then
   SpecGenerationOnly || exit
   exit 0
fi
SpecGeneration   || my_exit
SpecEdit         || my_exit
RpmBuild         || my_exit
RpmFileName      || my_exit
echo "result: ${RPMFILENAME}"
InstallationTest || my_exit

my_exit 0
