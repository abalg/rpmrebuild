#!/bin/sh
# conversion des fichier man francais entre iso-latin et utf8
# $Id$

fic=$1

dest=$2

case $dest in
	fr_FR)
		src=fr_FR.UTF-8;
		type=ISO_8859-15;
		;;
	fr_FR.UTF-8)
		src=fr_FR;
		type=UTF-8;
		;;
	*)
		echo "syntaxe $0 fichier cible";
		exit;
		;;
esac

fsrc="$src/$fic"
if [ -f $fsrc ]
then
	fdest="$dest/$fic"
	iconv -t $type -o $fdest $fsrc
	diff $fsrc $fdest
fi
