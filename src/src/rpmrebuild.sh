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

function QuestionsToUser
{
	[ "X$batch"     = "Xyes" ] && return 0 ## batch mode, continue
	[ "X$spec_only" = "Xyes" ] && return 0 ## spec only mode, no questions

	AskYesNo "$WantContinue" || return
	RELEASE_ORIG="$(spec_query_qf '%{RELEASE}')"
	AskYesNo "Do you want to change release number" && {
		echo -n "Enter the new release (old: $RELEASE_ORIG): "
		read RELEASE_NEW
	}
	return 0
}

function IsPackageInstalled
{
	# test if package exists
	local output
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
function RpmUnpack
{
	[ "x$BUILDROOT" = "x/" ] && {
		Error "Internal '$BUILDROOT' can not be '/'." 
        	return 1
	}
	local CPIO_TEMP=$RPMREBUILD_TMPDIR/${PAQUET_NAME}.cpio
	rm --force $CPIO_TEMP                               || return
	rpm2cpio ${PAQUET} > $CPIO_TEMP                     || return
	rm    --force --recursive $BUILDROOT                || return
	mkdir --parent            $BUILDROOT                || return
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
	local BUILDCMD=rpm
	[ -x /usr/bin/rpmbuild ] && BUILDCMD=rpmbuild
	eval $BUILDCMD $rpm_defines -bb $rpm_verbose $additional ${FIC_SPEC} || {
   		Error "package '${PAQUET}' build failed"
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
		Error "Testinstall for package '${PAQUET}' failed"
		return 1
	}
	return 0
}

function Processing
{
	local Aborted="no"
	local MsgFail

	source $RPMREBUILD_PROCESSING && return 0

	if [ "X$need_change_spec" = "Xyes" -o "X$need_change_files" = "Xyes" ]; then
		MsgFail="package '$PAQUET' modification failed."
		[ "X$Aborted" = "Xyes" ] || Error "$MsgFail"
	else
		MsgFail="package '$PAQUET' specfile generation failed."
		Error "$MsgFail"
	fi
	return 1
}
##############################################################
# Main Part                                                  #
##############################################################
# shell pour refabriquer un fichier rpm a partir de la base rpm
# a shell to build an rpm file from the rpm database

function Main
{
	WantContinue="Do you want to continue"

	#RPMREBUILD_TMPDIR=${RPMREBUILD_TMPDIR:-~/.tmp/rpmrebuild.$$}
	RPMREBUILD_TMPDIR=${RPMREBUILD_TMPDIR:-~/.tmp/rpmrebuild}
	export RPMREBUILD_TMPDIR

	FIC_SPEC=$RPMREBUILD_TMPDIR/spec
	FILES_IN=$RPMREBUILD_TMPDIR/files.in
	# I need it here just in case user specify 
	# plugins for fs modification  (--change-files)
	BUILDROOT=$RPMREBUILD_TMPDIR/root

	D=`dirname $0` || return
	source $D/rpmrebuild_parser.src || return
	source $D/spec_func.src         || return
	source $D/processing_func.src   || return
	processing_init || return
	MY_LIB_DIR="$D"
	MY_PLUGIN_DIR=${MY_LIB_DIR}/plugins

	# suite a des probleme de dates incorrectes
	# to solve problems of bad date
	export LC_TIME=POSIX

	RPMREBUILD_PROCESSING=$RPMREBUILD_TMPDIR/PROCESSING

	rm -rf   $RPMREBUILD_TMPDIR || return
	mkdir -p $RPMREBUILD_TMPDIR || return
	CommandLineParsing "$@" || return
	[ "x$NEED_EXIT" = "x" ] || return $NEED_EXIT

	if [ "x" = "x$package_flag" ]; then
   		[ "X$need_change_files" = "Xyes" ] || BUILDROOT="/"
   		IsPackageInstalled || return
   		if [ "X$verify" = "Xyes" ]; then
      			out=$(VerifyPackage) || return
      			if [ -n "$out" ]; then
		 		Warning "some files have been modified:\n$out"
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
		InstallationTest || return
	fi
	return 0
}

Main "$@"
st=$?	# save status
#rm -rf $RPMREBUILD_TMPDIR
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
