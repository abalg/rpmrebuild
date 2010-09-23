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

# debug 
#set -x 
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
	# screen
	Echo "$0: WARNING: $@"
	# for optionnal bug report
	echo -e "$0: WARNING: $@" >> $BUGREPORT

}
###############################################################################

function AskYesNo
{
	local Ans
	echo -en "$@ ? (y/N) " 1>&2
	read Ans
	case "x$Ans" in
		x[yY]*) return 0;;
		*)      return 1;;
	esac || return 1 # should not happened
	return 1 # should not happend
}

###############################################################################
function RmDir
{
	[ $# -ne 1 -o "x$1" = "x" ] && {
		Echo "Usage: RmDir <dir>"
		return 1
	}
	# to ensure tmpdir is really emptied by rm -rf
	local Dir
	Dir="$1"
	if [ -d $Dir ]
	then
		rm -rf "$Dir" 2>/dev/null && return
		chmod -R 700 "$Dir" 2>/dev/null  # no return here !!!
		rm -rf "$Dir" || return
	fi
	return 0
}
###############################################################################
function SpecEdit
{
	[ $# -ne 1 -o "x$1" = "x" ] && {
		Echo "Usage: $0 SpecEdit <file>"
		return 1
	}
	# -e option : edit the spec file
	local File=$1
	${VISUAL:-${EDITOR:-vi}} $File
	AskYesNo "$WantContinue" || {
		Aborted="yes"
		Echo "Aborted."
	        return 1
	}
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
	[ "X$batch"     = "Xyes" ] && return 0 ## batch mode, continue
	[ "X$spec_only" = "Xyes" ] && return 0 ## spec only mode, no questions

	AskYesNo "$WantContinue" || return
	RELEASE_ORIG="$(spec_query qf_spec_release )"
	[ -z "$RELEASE_NEW" ] && \
	AskYesNo "$WantChangeRelease" && {
		echo -n "$EnterRelease $RELEASE_ORIG): "
		read RELEASE_NEW
	}
	return 0
}

###############################################################################
function IsPackageInstalled
{
	# test if package exists
	local output
	output="$( rpm --query ${PAQUET} 2>&1 )" # Don't return here - use output
	iret=$?
	if [ $iret -eq 1 ]
	then
		# no such package in rpm database
		Error "${PAQUET} $PackageNotInstalled"
		return 1
	else
		# find it : one or more ?
		set -- $output
		case $# in
			1)
			: # Ok, do nothing
			;;

			*)
			Error "$PackageTooMuch '${PAQUET}':\n$output"
			return 1
			;;
		esac 
	fi
	return 0
}

###############################################################################
function RpmUnpack
{
	[ "x$BUILDROOT" = "x/" ] && {
		Error "$BuildRootError" 
        	return 1
	}
	local CPIO_TEMP=$TMPDIR_WORK/${PAQUET_NAME}.cpio
	rm --force $CPIO_TEMP                               || return
	rpm2cpio ${PAQUET} > $CPIO_TEMP                     || return
	rm    --force --recursive $BUILDROOT                || return
	mkdir -p                  $BUILDROOT                || return
	(cd $BUILDROOT && cpio --quiet -idmu ) < $CPIO_TEMP || return
	rm --force $CPIO_TEMP                               || return
	# Process ghost files
	/bin/bash $MY_LIB_DIR/rpmrebuild_ghost.sh $BUILDROOT < $FILES_IN || return
	return 0
}
###############################################################################
function CreateBuildRoot
{
        if [ "x$package_flag" = "x" ]; then
		if [ "X$need_change_files" = "Xyes" ]; then
			/bin/bash $MY_LIB_DIR/rpmrebuild_buildroot.sh $BUILDROOT < $FILES_IN || return
		else
			: # Do nothing
		fi
	else
        	RpmUnpack || return
	fi 
	return 0
}
###############################################################################

function RpmBuild
{
	# reconstruction fichier rpm : le src.rpm est inutile
	# build rpm file, the src.rpm is not usefull to do
	# for rpm 4.1 : use rpmbuild
	local BUILDCMD=rpmbuild

	# rpm 4.6 ignore BuildRoot in the spec file, 
	# so I have to provide define on the command line
	# Worse, it disallow buildroot "/", so I have to trick it.
	if [ "x$BUILDROOT" = "x/" ]; then
		BUILDROOT="$RPMREBUILD_TMPDIR/my_root"
		# Just in case previous link is here
		rm -f $BUILDROOT || return
		# Trick rpm (I hope :)
		ln -s / $BUILDROOT || return
	fi
	eval $BUILDCMD --define "'buildroot $BUILDROOT'" $rpm_defines -bb $rpm_verbose $additional ${FIC_SPEC} || {
   		Error "package '${PAQUET}' $BuildFailed"
   		return 1
	}
	
	return 0
}

###############################################################################
function RpmFileName
{
	QF_RPMFILENAME=$(eval rpm $rpm_defines --eval %_rpmfilename) || return
	RPMFILENAME=$(eval rpm $rpm_defines --specfile --query --queryformat "${QF_RPMFILENAME}" ${FIC_SPEC}) || return
	# workarount for redhat 6.x
	arch=$(eval rpm $rpm_defines --specfile --query --queryformat "%{ARCH}"  ${FIC_SPEC})
	if [ $arch = "(none)" ]
	then
		arch=$(eval rpm $rpm_defines --query $package_flag --queryformat "%{ARCH}" ${PAQUET})
		RPMFILENAME=$(echo $RPMFILENAME | sed "s/(none)/$arch/g")
	fi

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
		Error "package '${PAQUET}' $TestFailed"
		return 1
	}
	return 0
}

###############################################################################
function Processing
{
	local Aborted="no"
	local MsgFail

	source $RPMREBUILD_PROCESSING && return 0

	if [ "X$need_change_spec" = "Xyes" -o "X$need_change_files" = "Xyes" ]; then
		[ "X$Aborted" = "Xyes" ] || Error "package '$PAQUET' $ModificationFailed."
	else
		Error "package '$PAQUET' $SpecFailed."
	fi
	return 1
}
###############################################################################
# recover system informations on rpmrebuild context
function GetInformations
{
	Echo "from: $1"
	Echo "-----------"
	lsb_release -a
	cat /etc/issue
	Echo "-----------"
	rpm -q rpmrebuild
	rpm -q rpm
	Echo "-----------"
	rpm --querytags
	Echo " --------------- $WriteComments -----------------------"
}
###############################################################################
# send informations to developper to allow fix problems
function SendBugReport
{
	[ "X$batch"     = "Xyes" ] && return 0 ## batch mode, skip report
	AskYesNo "$WantSendBugReport" || return
	# build default mail address 
	from="${USER}@${HOSTNAME}"
	AskYesNo "$WantChangeEmail ($from)" && {
		echo -n "$EnterEmail"
		read from
	}
	GetInformations $from >> $BUGREPORT 2>&1
	AskYesNo "$WantEditReport" && {
		${VISUAL:-${EDITOR:-vi}} $BUGREPORT
	}
	AskYesNo "$WantStillSend" && {
		mail -s "[rpmrebuild] bug report" rpmrebuild-bugreport@lists.sourceforge.net < $BUGREPORT
	}
	return
}
###############################################################################
# rpm tags change along the time : some are added, some are renamed, some are
# deprecated, then removed
# the idea is to check if the tag we use for rpmrebuild still exists
function CheckTags
{
	# get rpm tags
	rpm_tags=$( rpm --querytags )

	# rem : rpmrebuild.usedtags is builf by extract_tags.pl during package build (cf Makefile)
	rpmrebuild_tags=$( cat $MY_LIB_DIR/rpmrebuild.usedtags )

	# check for all rpmrebuild tags
	errors=0
	for tag in $rpmrebuild_tags
	do
		ok=''
		# if it exists in rpm tags
		for rpm_tag in $rpm_tags
		do
			if [ "$tag" = "$rpm_tag" ]
			then
				# ok : we find it
				ok='y'
				break
			fi	
		done
		if [ -z "$ok" ]
		then
			Warning "(CheckTags) $MissingTag $tag"
			let errors="$errors + 1"
		fi
	done
	if [ $errors -ge 1 ] 
	then
		Warning "$CannotWork"
		SendBugReport
		return 1
	fi
}
##############################################################
# Main Part                                                  #
##############################################################
# shell pour refabriquer un fichier rpm a partir de la base rpm
# a shell to build an rpm file from the rpm database

function Main
{
	
	#WantContinue="Do you want to continue"

	RPMREBUILD_TMPDIR=${RPMREBUILD_TMPDIR:-~/.tmp/rpmrebuild.$$}
	#RPMREBUILD_TMPDIR=${RPMREBUILD_TMPDIR:-~/.tmp/rpmrebuild}
	BUGREPORT=$RPMREBUILD_TMPDIR/bugreport
	export BUGREPORT
	export RPMREBUILD_TMPDIR
	TMPDIR_WORK=$RPMREBUILD_TMPDIR/work

	# create tempory directories before any work/test
	RmDir "$RPMREBUILD_TMPDIR" || return
	mkdir -p $TMPDIR_WORK       || return

	FIC_SPEC=$TMPDIR_WORK/spec
	FILES_IN=$TMPDIR_WORK/files.in
	# I need it here just in case user specify 
	# plugins for fs modification  (--change-files)
	BUILDROOT=$TMPDIR_WORK/root

	MY_LIB_DIR=`dirname $0` || return
	source $MY_LIB_DIR/rpmrebuild_parser.src || return
	source $MY_LIB_DIR/spec_func.src         || return
	source $MY_LIB_DIR/processing_func.src   || return
	source $MY_LIB_DIR/rpmrebuild_rpmqf.src   || return

	# check language
	case "$LANG" in
		en*) real_lang=en;;
		fr_FR) real_lang=$LANG;;
		fr_FR.UTF-8) real_lang=$LANG;;
		*)  real_lang=en;;
	esac
	# load translation file
	source $MY_LIB_DIR/locale/$real_lang/rpmrebuild.lang
	
	processing_init || return
	CheckTags || return

	export RPMREBUILD_PLUGINS_DIR=${MY_LIB_DIR}/plugins

	# suite a des probleme de dates incorrectes
	# to solve problems of bad date
	export LC_TIME=POSIX

	RPMREBUILD_PROCESSING=$TMPDIR_WORK/PROCESSING

	CommandLineParsing "$@" || return
	[ "x$NEED_EXIT" = "x" ] || return $NEED_EXIT

	if [ "x" = "x$package_flag" ]; then
   		[ "X$need_change_files" = "Xyes" ] || BUILDROOT="/"
   		IsPackageInstalled || return
   		if [ "X$verify" = "Xyes" ]; then
      			out=$(VerifyPackage) || return
      			if [ -n "$out" ]; then
		 		Warning "$FilesModified\n$out"
		 		QuestionsToUser || return
      			fi
   		else # NoVerify
			:
   		fi
	else
		:
		# When rebuilding package from .rpm file it's just native
		# to use perm/owner/group from the package.
		# But because it anyway default and if one has a reason
		# to change it, one can. I am not force it here anymore.
		#RPMREBUILD_PUG_FROM_FS="no"  # Be sure use perm, owner, group from the pkg query.
	fi

	if [ "X$spec_only" = "Xyes" ]; then
		BUILDROOT="/"
		SpecGeneration   || return
		Processing       || return
	else
		SpecGeneration   || return
		CreateBuildRoot  || return
		Processing       || return
		RpmBuild         || return
		RpmFileName      || return
		echo "result: ${RPMFILENAME}"
		if [ -z "$NOTESTINSTALL" ]; then
			InstallationTest || return
		fi
	fi
	return 0
}
###############################################################################

Main "$@"
st=$?	# save status

# in debug mode , we do not clean temp files
if [ -z "$debug" ]
then
	RmDir "$RPMREBUILD_TMPDIR"
fi
exit $st

#####################################
# BUILDROOT note.
# My original idea was for recreating package from another rpm file
# (not installed) use 'rpm -bb --define "buildroot foo"', but
# It does not work:
#  when i not specify buildroot in the spec file default value is "/"
#  I can build this package, but can't override buildroot from the
#  command line.
#
# when i specify buildroot: / in the spec file i got parser error.
#
# So, for recreating installed packages I need specfile WITHOUT
# buildroot
# For recreating package from another rpm I have to put buildroot in the
# specfile
#########################################
