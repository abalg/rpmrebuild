#!/bin/bash
###############################################################################
#   rpmrebuild.sh 
#
#    Copyright (C) 2002 by Eric Gerbier
#    Bug reports to:  gerbier@users.sourceforge.net
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

# shell pour refabriquer un fichier rpm a partir de la base rpm
# a shell to build an rpm file from the rpm database

#####################################################
usage() {
	echo "syntaxe : $0 package"
	echo "build an rpm package from rpm database"
}
#####################################################
interrogation() {
	rpm -q --queryformat "$1" ${PAQUET}
}

#####################################################
# write_info rpm_tag rpm_query
write_info() {
	rpm_tag=$1
	rpm_query=$2

	output=$(interrogation "$rpm_query")
	if [ -z "$output" ]
	then
		return
	elif [ "$output" != "(none)" ]
	then
		echo -e "$rpm_tag $output" >> ${FIC_SPEC}
	fi
}

#####################################################

# test argument
if [ $# -ne 1 ]
then
	usage
	exit 1 
fi

# test root
#out=$(echo $HOME | grep root)
#if [ -z "$out" ]
#then
#        echo "you have to work under root user"
#        exit
#fi

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
	else
		NAME=$(interrogation '%{NAME}\n')
		VERSION=$(interrogation '%{VERSION}\n')
		RELEASE=$(interrogation '%{RELEASE}\n')

		NOM_COMPLET=${NAME}-${VERSION}-${RELEASE}
		NOM_VERSION=${NAME}-${VERSION}
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
fi

# fabrication fichier spec
# build spec file
FIC_SPEC=${NOM_COMPLET}.spec

if [ -a ${FIC_SPEC} ]
then
	echo "file ${FIC_SPEC} exists : renamed"
	mv -f ${FIC_SPEC} ${FIC_SPEC}.sav
fi

write_info "Summary: " '%{SUMMARY}\n'
write_info "Name: "    '%{NAME}\n'
write_info "Version: " '%{VERSION}\n'
write_info "Release: " '%{RELEASE}\n'

# not used Patch and Source

write_info "URL: " '%{URL}\n'
write_info "Distribution: " '%{DISTRIBUTION}\n'
write_info "Vendor: " '%{VENDOR}\n'
write_info "Packager: " '%{PACKAGER}\n'
write_info "Copyright: " '%{COPYRIGHT}\n'
write_info "Group: "  '%{GROUP}\n'
write_info "BuildArch: " '%{ARCH}\n'
ARCH=$(interrogation '%{ARCH}\n')

# query of require may duplicate line, so disable automatic
echo "AutoReqProv: no" >> ${FIC_SPEC}
write_info "Requires: " '[%{REQUIRENAME} %{REQUIREFLAGS:depflags} %{REQUIREVERSION} ]\n'
write_info "Conflicts: " '[%{CONFLICTNAME} %{CONFLICTFLAGS:depflags} %{CONFLICTVERSION} ]\n'
write_info "Obsoletes: " '[%{OBSOLETES} ]\n'
write_info "Provides: " '[%{PROVIDES} ]\n'

#echo "BuildRoot: %{_builddir}/%{name}" >> ${FIC_SPEC}

# some rare tags
write_info "Serial: " '%{SERIAL}\n'
write_info "Icon: " '%{ICON}\n'
write_info "ExcludeArch: " '[%{EXCLUDEARCH} ]\n'
write_info "ExclusiveArch: " '[%{EXCLUSIVEARCH} ]\n'
write_info "ExcludeOs: " '[%{EXCLUDEOS} ]\n'
write_info "ExclusiveOS: " '[%{EXCLUSIVEOS} ]\n'

write_info "%description\n" '%{DESCRIPTION}\n'

cat << END >>  ${FIC_SPEC}
%prep
%build
%install
%clean

END

write_info "%pre\n" '%{PREINPROG}\n'
write_info "%preun\n" '%{PREUNPROG}\n'
write_info "%post\n" '%{POSTINPROG}\n'
write_info "%postun\n" '%{POSTUNPROG}\n'

# code from Han Holl
S=/tmp/trigger$$
EOL="*#*#*#*#"
rpm -q --qf "[%{TRIGGERTYPE}\n%{TRIGGERSCRIPTPROG}\n%{TRIGGERCONDS}\n%{TRIGGERSCRIPTS}\n$EOL\n]" $PAQUET >$S
if [ -s $S ]
then
	while read ttype
	do
          read tshell
          [ "$tshell" = "/bin/sh" ] && tshell="" || tshell="-p $tshell"
          read tcond
          read tline
          echo "%trigger${ttype} $tshell -- $tcond"
          while [ "$tline" != $EOL ]
          do
            echo $tline
            read tline
          done
	done <$S  >>${FIC_SPEC}
fi
rm -f $S

cat << END2 >>  ${FIC_SPEC}
%files
END2

listeall=$(rpm -ql ${PAQUET})
listedoc=$(rpm -qld ${PAQUET})
listeconfig=$(rpm -qlc ${PAQUET})
for file in $listeall
do
	# petite subtilite : les repertoires ne doivent pas 
	# apparaitre directement, sinon probleme de doublons
	if [ -d $file ]
	then
		echo "%dir $file" >> ${FIC_SPEC}
		echo "%dir $file"
	else
		# test for doc files
		for ficdoc in $listedoc
		do
			if [ "$file" = "$ficdoc" ]
			then
				echo "%doc $file" >> ${FIC_SPEC}
				echo "%doc $file"
				continue 2
			fi
		done
		# test for config files
		for ficconf in $listeconfig
		do
			if [ "$file" = "$ficconf" ]
			then
				echo "%config $file" >> ${FIC_SPEC}
				echo "%config $file"
				continue 2
			fi
		done
		
		# default
		echo "$file" >> ${FIC_SPEC}
		echo "$file"
	fi
done

echo "%changelog" >> ${FIC_SPEC}
rpm -q --changelog ${PAQUET} >> ${FIC_SPEC}

# reconstruction fichier rpm : le src.rpm est inutile
# build rpm file, the src.rpm is not usefull to do

# just an hint to build the rpm file in local dir
fmacro=~/.rpmmacros
# save it
if [ -f $fmacro ]
then
        cp -a $fmacro ${fmacro}.sav
fi

# change rpmdir
echo "%_rpmdir ." >> $fmacro

rpm -bb ${FIC_SPEC}

# restore it
if [ -f ${fmacro}.sav ]
then
        mv ${fmacro}.sav $fmacro
fi


echo "##################################################################"
echo "result :"
ls -l ${ARCH}/${PAQUET}-${VERSION}-${RELEASE}.${ARCH}.rpm

# be carefull, there is others files not cleaned :
echo "you may clean too : ${FIC_SPEC} "
