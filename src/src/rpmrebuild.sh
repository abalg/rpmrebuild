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
	echo "it does not need to be run under root user"
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
   QF="\
[Name:          %{NAME}\n]\
[Version:       %{VERSION}\n]\
[Release:       %{RELEASE}\n]\
[URL:           %{URL}\n]\
[Distribution:  %{DISTRIBUTION}\n]\
[Vendor:        %{VENDOR}\n]\
[Packager:      %{PACKAGER}\n]\
[License:       %{LICENSE}\n]\
[Group:         %{GROUP}\n]\
[Summary:       %{SUMMARY}\n]\
[BuildArch:     %{ARCH}\n]\
[Epoch:         %{EPOCH}\n]\
[Icon:          %{ICON}\n]\
[XPM:           %{XPM}\n]\
[GIF:           %{GIF}\n]\
[Requires:      %{REQUIRENAME} %{REQUIREFLAGS:depflags} % {REQUIREVERSION}\n]\
[Conflicts:     %{CONFLICTNAME} %{CONFLICTFLAGS:depflags} % {CONFLICTVERSION}\n]\
[Obsoletes:     %{OBSOLETES}\n]\
[Provides:      %{PROVIDES}\n]\
[ExcludeArch:   %{EXCLUDEARCH}\n]\
[ExclusiveArch: %{EXCLUSIVEARCH}\n]\
[ExcludeOs:     %{EXCLUDEOS}\n]\
[ExclusiveOs:   %{EXCLUSIVEOS}\n]\
[Prefix:        %{PREFIXES}\n]\
[\n%%description\n %{DESCRIPTION}\n\n]\
[%%trigger%{TRIGGERTYPE} -p %{TRIGGERSCRIPTPROG} -- %{TRIGGERCONDS} \n%{TRIGGERSCRIPTS}\n]\
[%%pre -p %{PREINPROG}\n%{PREIN}\n\n]\
[%%post -p %{POSTINPROG}\n%{POSTIN}\n\n]\
[%%preun -p %{PREUNPROG}\n%{PREUN}\n\n]\
[%%postun -p %{POSTUNPROG}\n%{POSTUN}\n\n]\
[%%verify -p %{VERIFYSCRIPTPROG}\n%{VERIFYSCRIPT}\n\n]\
%|CHANGELOGTIME?{%%changelog\n[* %{CHANGELOGTIME:day} %{CHANGELOGNAME} \n\n%{CHANGELOGTEXT}\n\n]\n}:{}|\
"
# query of require may duplicate line, so disable automatic
echo "AutoReq: no"
echo "AutoProv: no"
rpm --query --queryformat "${QF}" ${PAQUET}

cat << END
%prep
%build
%install
%clean

END
}
###############################################################################
# build the list of files in package
function FilesSpecFile
{
echo "%files"

QF="[%{FILENAMES} %{FILEFLAGS:fileflags}\n]"
rpm --query --queryformat "${QF}" ${PAQUET} | while read file type
do

	if [ ! -e $file ]
	then
		# skip missing files
		echo "# $file"
	elif [ -d $file ]
	then
		# special case for directories
		echo "%dir $file"
	elif [ "$type" = "d" ]
	then
		# test for documentation files
		echo "%doc $file"
	elif [ "$type" = "c" ]
	then
		# configuration file
		echo "%config $file"
	elif [ "$type" = "g" ]
	then
		# configuration file
		echo "%ghost $file"
	else
		# default
		echo "$file"
	fi
done
}

##############################################################
# Main Part                                                  #
##############################################################
# shell pour refabriquer un fichier rpm a partir de la base rpm
# a shell to build an rpm file from the rpm database

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
	#echo $out concate all lines in one : not clear
	# so recall the same command
	rpm -V ${PAQUET}
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
