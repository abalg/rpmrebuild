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
   echo -en "$@ ? (y/N) " 1>&2
   read Ans
   case "x$Ans" in
      x[yY]*) return 0;;
      *)      return 1;;
   esac || return 1 # should not happened
   return 1 # should not happend
}

###############################################################################
function Usage
{
   Usage_Message="
$0 is a tool to rebuild an rpm file from the rpm database
Usage: $0 [options] package
options:
   -a, --additional <flags>    additional flags to be pass to the rpmbuild
   -b, --batch                 batch mode
   -c, --comment-missing <y|n> comment missing files in the specfile.
                               default - no.
                               This flag is only meanful with --verify no
   -d, --directory <dir>       specify the working directory
   -D, --define <define>       defines to be passed to the rpmbuild
   -e, --edit-spec             edit specfile
   -f, --filter <file>         apply an external filter on generated specfile
   -k, --keep-perm,
       --pug-from-fs           keep installed files permission, uid and gid
       --pug-from-db (default) use files permission, uid and gid from rpm db
   -m  --modify <script>       script (or program) to modify unpacked rpm files
                               (to be used with -p (--package) option)
   -p, --package               use package file, not installed rpm
   -P, --autoprovide
   -R, --autorequire
   -s, --spec-only <spec>      generate specfile only
                               (If <spec> '-' stdout will be used)
   -v, --verbose               verbose
   -V, --version               print version
   -w, --warning               print warning if detect filenames with
                               globbing characters
   -y, --verify <yes|no>       need verify package before processing
                               (default - yes)
   -h, --help                  print this help

Copyright (C) 2002 by Eric Gerbier
this program is distributed under GNU General Public License
"
   Echo "$Usage_Message"
}
###############################################################################
function Interrog
{
	QF=$1
	rpm --query --i18ndomains /dev/null $package_flag --queryformat "${QF}" ${PAQUET}
}
###############################################################################
function SpecChange
{
	# rpmlib dependencies are insert during rpm building
	# gpg key can not be provided
	sedscript='s/\(^Requires:[[:space:]]*rpmlib(.*\)/#\1/;s/\(^Provides:[[:space:]]*gpg(.*\)/#\1/'

	if [ -n $autorequire ]
	then
		sedscript="${sedscript};s/^AutoReq/#AutoReq/;s/^%undefine __find_requires/#undefine __find_requires/;s/^Require/#Require/"
	fi

	if [ -n $autoprovide ]
	then
		sedscript="${sedscript};s/^AutoProv/#AutoProv/;s/^%undefine __find_provides/#undefine __find_provides/;s/^Provide/#Provide/"
	fi

	# apply filter
	sed "$sedscript"
}
###############################################################################
# build general tags
function SpecFile
{
	HOME=$MY_LIB_DIR rpm --query --i18ndomains /dev/null $package_flag --spec_spec ${PAQUET} | SpecChange
}
###############################################################################
# build the list of files in package
function FilesSpecFile
{
	echo "%files"
	HOME=$MY_LIB_DIR rpm --query $package_flag --spec_files ${PAQUET} | $MY_LIB_DIR/rpmrebuild_files.sh
}

###############################################################################
function ChangeSpecFile
{
	# first sed is to expand all macros
	# then rollback on tag line
	HOME=$MY_LIB_DIR rpm --query $package_flag --spec_change ${PAQUET} | sed 's/%/%%/g;s/^%%description/%description/;s/^%%post/%post/;s/^%%pre/%pre/;s/^%%postun/%postun/;s/^%%preun/%preun/;s/^%%trigger/%trigger/;s/^%%files/%files/;s/^%%changelog/%changelog/'
}

###############################################################################
function Try_Help
{
	Echo "Try \`$0 --help' for more information."
}

###############################################################################
function UnrecognizedOption
{
	Echo "$0: unrecognized option \`--$LONG_OPTION'"
	Try_Help
	exit 1
}

function AmbiguousOption
{
	Echo "$0: ambiguous option \`--$LONG_OPTION'"
	Try_Help
	exit 1
}

###############################################################################
function RequeredArgument
{
	[ "x$SHORT_OPTION" = "x-" ] || return 0  # we use short option,
                                                 # do nothing
	if [ "$OPTARG_EXIST" ]; then
		let OPTIND=$OPTIND+$OPTIND_INCR
	else
		Echo "$0: option \`$LONG_OPTION' requires an argument"
		Try_Help
		exit 1
	fi
}
###############################################################################
function ExtractProgName
{
	progname="$1"
}
###############################################################################
function CommandLineParsing
{
# Default flags' values. To be sure they don't came from environment
additional=""
autoprovide=""
autorequire=""
batch=""
filter=""
rpm_defines=""
rpmdir=""
editspec=""
package_flag=""
modify=""
speconly=""
specfile=""
verify="1"
rpm_verbose="--quiet"
export keep_perm=""
export comment_missing="0"
export warning=""
PAQUET=""
PAQUET_NAME=""

while getopts "a:bc:d:D:ef:hkm:pPRs:vVwy:-:" opt
do
	OPTIND_INCR=0
	case "$opt" in
		a) LONG_OPTION=additional;;
		b) LONG_OPTION=batch;;
		c) LONG_OPTION=comment-missing;;
		d) LONG_OPTION=dir;;
		D) LONG_OPTION=define;;
		e) LONG_OPTION=edit-spec;;
		f) LONG_OPTION=filter;;
		k) LONG_OPTION=keep-perm;;
		m) LONG_OPTION=modify;;    
		p) LONG_OPTION=package;;
		P) LONG_OPTION=autoprovide;;
		R) LONG_OPTION=autorequire;;
		s) LONG_OPTION=spec-only;;
		h) LONG_OPTION=help;;
		v) LONG_OPTION=verbose;;
		V) LONG_OPTION=version;;
		w) LONG_OPTION=warning;;
		y) LONG_OPTION=verify;;

                -)
	        	case "x$OPTARG" in
				x*=*)
					LONG_OPTION=${OPTARG%%=*}
					OPTARG=${OPTARG#*=}
					OPTARG_EXIST=1
				;;

				*)
                   			LONG_OPTION="$OPTARG"
                   			if [ $OPTIND -le $# ]; then
                      				eval OPTARG=\$$OPTIND
                      				OPTARG_EXIST=1
						OPTIND_INCR=1
                   			else
                      				OPTARG=""
                      				OPTARG_EXIST=""
                   			fi
				;;
			esac
               	;;

		*)
			Try_Help
			exit 1
		;;
	esac

	SHORT_OPTION="$opt"
	case "$LONG_OPTION" in
		a | \
		au | \
		aut | \
		auto )
			AmbiguousOption
		;;

		ad | \
		add | \
		addi | \
		addit | \
		additi | \
		additio | \
		addition | \
		additiona | \
		additional)
			RequeredArgument
			additional="$OPTARG"
		;;

		autop | \
		autopr | \
		autopro | \
		autoprov | \
		autoprovi | \
		autoprovid | \
		autoprovide)
			autoprovide=y
		;;

		autor | \
		autore | \
		autoreq | \
		autorequ | \
		autorequi | \
		autorequir | \
		autorequire)
			autorequire=y
		;;

		b | \
		ba | \
		bat | \
		batc | \
		batch)
			batch=y
		;;

		c | \
		co | \
		com | \
		comm | \
		comme | \
		commen | \
		comment | \
		comment- | \
		comment-m | \
		comment-mi | \
		comment-mis | \
		comment-miss | \
		comment-missi | \
		comment-missin | \
		comment-missing | \
		comment-missing)
			RequeredArgument
			case "x$OPTARG" in
			   x[yY]*) comment_missing="1";;
                           *)      comment_missing="0";;
			esac
		;;

		d)
			AmbiguousOption
		;;

		de | \
		def | \
		defi | \
		defin | \
		define)
			RequeredArgument
			rpm_defines="$rpm_defines --define '$OPTARG'"
		;;

		di | \
		dir | \
		dire | \
		direc | \
		direct | \
		directo | \
		director | \
		directory)
			RequeredArgument
			rpmdir="$OPTARG"
			rpm_defines="$rpm_defines --define '_rpmdir $rpmdir'" 
			mkdir -p -- "$rpmdir"
			rpmdir="$(cd $rpmdir && echo $PWD)" || {
				Error "Can't changedir to '$rpmdir'"
				exit 1
			}
		;;

		e | \
		ed | \
		edi | \
		edit | \
		edit- | \
		edit-s | \
		edit-sp | \
		edit-spe | \
		edit-spec)
			editspec=y
		;;

		f | \
		fi | \
		fil | \
		filt | \
		filte | \
		filter)
			RequeredArgument
			ExtractProgName $OPTARG  # set progname

			# check if executable ?
			if type -all -path "$progname" 1>/dev/null 2>&1
			then
				filter="$filter | $OPTARG"
			else
				Error "Can't find '$progname' in '$PATH'"
				exit 1
			fi
		;;
			
		h | \
		he | \
		hel | \
		help)
			Usage
			exit 0
		;;

		k | \
		ke | \
		kee | \
		keep | \
		keep- | \
		keep-p | \
		keep-pe | \
		keep-per | \
		keep-perm)
			keep_perm=1
		;;

		m | \
		mo | \
		mod | \
		modi | \
		modif | \
		modify)
			RequeredArgument
			modify="$OPTARG"
		;;

		p)
			AmbiguousOption
		;;

		pa | \
		pac | \
		pack | \
		packa | \
		packag | \
		package)
                   package_flag="-p"
                   comment_missing=0
                ;;

		pu | \
		pug | \
		pug- | \
		pug-f | \
		pug-fr | \
		pug-fro | \
		pug-from | \
		pug-from-)
			AmbiguousOption
		;;

		pug-from-d | \
		pug-from-db)
			keep_perm=""
		;;

		pug-from-f | \
		pug-from-fs) Alias to keep-perm
			keep_perm=1
		;;

		s | \
		sp | \
		spe | \
		spec | \
		spec- | \
		spec-o | \
		spec-on | \
		spec-onl | \
		spec-only)
			RequeredArgument
			spec_only=y
			specfile="$OPTARG"
		;;

		v | \
		ve | \
		ver )
			AmbiguousOption
		;;

		verb | \
		verbo | \
		verbos | \
		verbose)
			rpm_verbose="--verbose"
		;;

		veri | \
		verif | \
		verify)
			RequeredArgument
			case "x$OPTARG" in
			   x[yY]*) verify="1";;
                           *)      verify="0";;
			esac
		;;

		vers | \
		versi | \
		versio | \
		version)
			echo "$VERSION"
			exit 0
		;;

		w | \
		wa | \
		war | \
		warn | \
		warni | \
		warnin | \
		warning)
			warning=y
		;;

		*)
			UnrecognizedOption
		;;
	esac
done

if [ "x$package_flag" = "x" ]; then
   if [ \! "x$modify" = "x" ]; then
      Error "-m (--modify) option can be used only with -p (--package) option."
      exit 1
   fi
fi

# If no rpmdir was specified set variable to the native rpmdir value
# (with respect to possible define)
if [ -z "$rpmdir" ]
then
   rpmdir="$(eval rpm $rpm_defines --eval %_rpmdir)" || exit
fi

shift $((OPTIND - 1))
case $# in
   0)
	Error "package argument missing"
	Try_Help
	exit 1
   ;;

   1) # One argument, it's ok
      PAQUET="$1"
      PAQUET_NAME="$PAQUET"
   ;;

   *)
	Error "multiple package arguments is illegal"
	Try_Help
	exit 1
   ;;
esac
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

	AskYesNo "$WantContinue" || return
	AskYesNo "Do you want to change release number" || return
	old_release=$(Interrog '%{RELEASE}')
	echo -n "Enter the new release (old: $old_release): "
	read new_release
	return 0
}
###############################################################################
function SpecGen
{
	if [ -n "$new_release" ]; then
		echo "%define new_release $new_release";
	else
		:
	fi       &&
	if [ "x$BUILDROOT" = "x/" ]; then
		:
	else
		echo "BuildRoot: $BUILDROOT"
	fi       &&
	SpecFile &&
	FilesSpecFile &&
	ChangeSpecFile
}
###############################################################################
function SpecGenerationOnly
{
	if [ "$specfile" = "-" ]
	then
		eval SpecGen $filter || return
	else
		eval SpecGen $filter > $specfile || return
	fi
	return 0
}

###############################################################################
function SpecGeneration
{
	# fabrication fichier spec
	# build spec file
	FIC_SPEC=${TMPDIR:-/tmp}/rpmrebuild_$$_${PAQUET_NAME}.spec
	rm -f ${FIC_SPEC} || return

	eval SpecGen $filter > ${FIC_SPEC} || return
	return 0
}

###############################################################################
function SpecEdit
{
	# -e option : edit the spec file
	if [ -n "$editspec" ]
	then
		${VISUAL:-${EDITOR:-vi}} ${FIC_SPEC}
		AskYesNo "$WantContinue" && return
		Echo "Aborted."
	        return 1
	fi
	return 0
}
###############################################################################

function RpmUnpack
{
	[ "x$BUILDROOT" = "x/" ] && {
	   Error "Internal '$BUILDROOT' can not be '/'." 
           return 1
	}
	CPIO_TEMP=${TMPDIR:-/tmp}/rpmrebuild_$$_${PAQUET_NAME}.cpio
	rm -f $CPIO_TEMP                                    || return
	rpm2cpio ${PAQUET} > $CPIO_TEMP                     || return
	rm    --force --recursive $BUILDROOT                || return
	mkdir --parent            $BUILDROOT                || return
	(cd $BUILDROOT && cpio --quiet -idmu ) < $CPIO_TEMP || return
	rm -f $CPIO_TEMP                                    || return
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
        [ "x$package_flag" = "x" ] || {
           RpmUnpack || return
           [ "x$modify" = "x" ] || {
	      export RPM_BUILD_ROOT="$BUILDROOT"
              eval $modify || {
	         Error "package '${PAQUET}' build failed due to modify script problems."
	         return 1
	      }
           }
        }
	eval $BUILDCMD $rpm_defines -bb $rpm_verbose $additional ${FIC_SPEC} || {
   		Error "package '${PAQUET}' build failed"
   		return 1
	}
	
        [ "x$package_flag" = "x" ] || {
	   # When we use package BUILDROOT should not be /,
	   # but to be sure test it one more time.
	   [ "x$BUILDROOT" = "x/" ] && {
	      Error "Internal '$BUILDROOT' can not be '/'." 
              return 1
	   }
	   rm -rf $BUILDROOT || return
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
###############################################################################

function my_exit
{
	st=$?	# save status
	rm -f ${FIC_SPEC}  # remove spec file
	rm -f ${CPIO_TEMP} # remove package's cpio file
	[ "x$BUILDROOT" = "x/" ] || rm -rf $BUILDROOT
	exit $st
}
##############################################################
# Main Part                                                  #
##############################################################
# shell pour refabriquer un fichier rpm a partir de la base rpm
# a shell to build an rpm file from the rpm database

WantContinue="Do you want to continue"

MY_LIB_DIR=/usr/lib/rpmrebuild
MY_PLUGIN_DIR=${MY_LIB_DIR}/plugins

PATH=$PATH:$MY_PLUGIN_DIR

# suite a des probleme de dates incorrectes
# to solve problems of bad date
export LC_TIME=POSIX

CommandLineParsing "$@" || exit
if [ "x" = "x$package_flag" ]
then
   BUILDROOT="/"
   IsPackageInstalled      || exit
   if [ "$verify" -eq "1" ]; then
      comment_missing=0
      out=$(VerifyPackage)    || exit
      if [ -n "$out" ]; then
	 Warning "some files have been modified:\n$out"
	 QuestionsToUser || exit
         comment_missing=1
      fi
   else # NoVerify
      :
   fi
else
   PAQUET_NAME="${PAQUET##*/}"
   [ "x$PAQUET_NAME" = "x" ] && {
      Error "Package file '$PAQUET' should not be a directory"
      exit 1
   }
   keep_perm=""  # Be sure use perm, owner, group from the pkg query.
   BUILDROOT=/tmp/${PAQUET_NAME}-root
fi

if [ -n "$spec_only" ]
then
   BUILDROOT="/"
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
