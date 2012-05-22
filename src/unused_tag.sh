#!/bin/sh
# search for unused rpm tags rpmrebuild
# the idea is to check if we miss some important tag

# where tags are used in rpmrebuild
# but see also rpmrebuild.sh as we modify this file
fic=rpmrebuild_rpmqf.src

# list of rpm tags
liste=$(rpm --querytags)

for tag in $liste
do
	rep=$( grep $tag $fic )
	if [ -z "$rep" ]
	then
		echo "#$tag"
		rpm -q --queryformat "[%{$tag}\n]" rpm
	fi

done
