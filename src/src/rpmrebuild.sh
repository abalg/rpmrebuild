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

interrogation() {
	rpm -q --queryformat "$1" ${PAQUET}
}

#####################################################
# write_info rpm_tag rpm_query
write_info() {
	rpm_tag=$1
	rpm_query=$2

	output=$(interrogation "$rpm_query")
	if [ "$output" != "(none)" ]
	then
		echo -e "$rpm_tag $output" >> ${FIC_SPEC}
	fi
}

#####################################################

# test argument
if [ $# -ne 1 ]
then
	echo "syntax :  $0 package"
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

# check for rpm-build package
out=$(rpm -q rpm-build)
if [ -z "$out" ]
then
	echo "WARNING : package rpm-build need to be installed"
	exit 1
fi

# try to guess where to build the package
# should be done with a "rpm --showrc" to take care of .rpmrc and so
# but too difficult : this code should work on almost all hosts
BASE=$(rpm -ql rpm-build | grep "SOURCES$" | sed 's/SOURCES$//')
if [ -z "${BASE}" ]
then
	echo "WARNING : can not find where to build rpm"
	exit 1
fi

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

# fabrication fichier tar contenant les fichiers du paquet
# build tar file
REPER=/tmp/${NOM_VERSION}
if [ -a $REPER ]
then
	echo "WARNING : directory $REPER already exists"
	exit 1
fi
mkdir $REPER
rpm -ql  ${PAQUET} | cpio -pd  $REPER > /dev/null 2>&1
cd /tmp/
tar cvzf ${BASE}/SOURCES/${NOM_COMPLET}.tgz  ${NOM_VERSION} >/dev/null
cd -
rm -rf  ${REPER} > /dev/null 2>&1

# fabrication fichier spec
# build spec file
FIC_SPEC=${BASE}/SPECS/${NOM_COMPLET}.spec

if [ -a ${FIC_SPEC} ]
then
	echo "file ${FIC_SPEC} exists : renamed"
	mv -f ${FIC_SPEC} ${FIC_SPEC}.sav
fi

write_info "Summary: " '%{SUMMARY}\n'
echo "Name: ${NAME}"  >> ${FIC_SPEC}
echo "Version: ${VERSION}" >> ${FIC_SPEC}
echo "Release: ${RELEASE}" >> ${FIC_SPEC}

echo "Source: ${NOM_COMPLET}.tgz " >> ${FIC_SPEC}
write_info "URL: " '%{URL}\n'
write_info "Patch: " '%{PATCH}\n'

write_info "Copyright: " '%{COPYRIGHT}\n'
write_info "Group: "  '%{GROUP}\n'
write_info "Packager: " '%{PACKAGER}\n'
write_info "BuildArch: " '%{ARCH}\n'
ARCH=$(interrogation '%{ARCH}\n')

write_info "Requires: " '%{REQUIRENAME}\n'
write_info "OBSOLETES: " '%{OBSOLETES}\n'


write_info "Distribution: " '%{DISTRIBUTION}\n'
write_info "Vendor: " '%{VENDOR}\n'
#echo "BuildRoot: %{_builddir}/%{name}" >> ${FIC_SPEC}

write_info "%description\n" '%{DESCRIPTION}\n'

cat << END >>  ${FIC_SPEC}
%prep
%setup
%build
%install
%clean
rm -rf \$RPM_BUILD_ROOT

END

write_info "%pre\n" '%{PREINPROG}\n'
write_info "%preun\n" '%{PREUNPROG}\n'
write_info "%post\n" '%{POSTINPROG}\n'
write_info "%postun\n" '%{POSTUNPROG}\n'

cat << END2 >>  ${FIC_SPEC}
%files
%defattr(-, root, root)
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
rpm -bb ${FIC_SPEC}

echo "##################################################################"
echo "result :"
ls -l ${BASE}/RPMS/${ARCH}/${PAQUET}-${VERSION}-${RELEASE}.${ARCH}.rpm

# be carefull, there is others files not cleaned :
echo "you may clean too : "
ls -l ${BASE}/SOURCES/${NOM_COMPLET}.tgz ${BASE}/SPECS/${NOM_COMPLET}.spec 
ls -ld ${BASE}/BUILD/${NOM_VERSION}
