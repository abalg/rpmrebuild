#!/bin/sh
###############################################################################
#   rebuild_rpm.sh 
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

#####################################################

interrogation() {
	rpm -q --queryformat "$1" ${PAQUET}
}

#####################################################

ecrire_info() {
	comment=$1
	query=$2

	output=$(interrogation "$query")
	if [ "$output" != "(none)" ]
	then
		echo -e "$comment $output" >> ${FIC_SPEC}
	fi
}

#####################################################

# test argument
if [ $# -ne 1 ]
then
	echo "syntaxe $0 package"
	exit 1 
fi

# test root
#out=$(echo $HOME | grep root)
#if [ -z "$out" ]
#then
#        echo "you have to work under root user"
#        exit
#fi


# test existence package
export PAQUET=$1
output=$(rpm -q ${PAQUET})
if [ -z "$output" ]
then
	echo "no package ${PAQUET} in database"
	exit 1
else
	nb=$(echo $output | wc -w | awk '{print $1}')
	if [ $nb -ne 1 ]
	then
		echo "too much packages match ${PAQUET} : $output"
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
out=$(rpm -V ${PAQUET})
if [ -n "$out" ]
then
	echo "some files have been modified :"
	rpm -V ${PAQUET}
	echo "want to continue (y/n) ?"
	read rep
	if [ "$rep" = 'n' ]
	then
		exit
	fi
fi

# fabrication fichier tar contenant les fichiers du paquet
REPER=/tmp/${NOM_VERSION}
if [ -a $REPER ]
then
	echo "$REPER existe"
	exit 1
fi
mkdir $REPER
rpm -ql  ${PAQUET} | cpio -pd  $REPER > /dev/null 2>&1
cd /tmp/
tar cvzf /usr/src/redhat/SOURCES/${NOM_COMPLET}.tgz  ${NOM_VERSION} >/dev/null
cd -
rm -rf  ${REPER} > /dev/null 2>&1

# fabrication fichier spec
FIC_SPEC=/usr/src/redhat/SPECS/${NOM_COMPLET}.spec

if [ -a ${FIC_SPEC} ]
then
	echo "fichier ${FIC_SPEC} existe"
	rm -f ${FIC_SPEC}
fi

ecrire_info "Summary: " '%{SUMMARY}\n'
echo "Name: ${NAME}"  >> ${FIC_SPEC}
echo "Version: ${VERSION}" >> ${FIC_SPEC}
echo "Release: ${RELEASE}" >> ${FIC_SPEC}

echo "Source: ${NOM_COMPLET}.tgz " >> ${FIC_SPEC}
ecrire_info "URL: " '%{URL}\n'
ecrire_info "Patch: " '%{PATCH}\n'

ecrire_info "Copyright: " '%{COPYRIGHT}\n'
ecrire_info "Group: "  '%{GROUP}\n'
ecrire_info "Packager: " '%{PACKAGER}\n'

ecrire_info "Distribution: " '%{DISTRIBUTION}\n'
ecrire_info "Vendor: " '%{VENDOR}\n'

ecrire_info "%description\n" '%{DESCRIPTION}\n'

cat << END >>  ${FIC_SPEC}
%prep
%setup
%build
%install
%clean
rm -rf \$RPM_BUILD_ROOT

END

ecrire_info "%pre\n" '%{PREINPROG}\n'
ecrire_info "%preun\n" '%{PREUNPROG}\n'
ecrire_info "%post\n" '%{POSTINPROG}\n'
ecrire_info "%postun\n" '%{POSTUNPROG}\n'

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
	# aparaitre directement, sinon probleme de doublons
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


# reconstruction fichier rpm
rpm -bb -vv  ${FIC_SPEC}

ls -ltr /usr/src/redhat/RPMS/i386
