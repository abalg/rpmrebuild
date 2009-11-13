#!/bin/sh
# conversion des fichier man d'iso-latin en utf8

fic=$1

src="fr_FR/$fic"

if [ -f $src ]
then
	dest="fr_FR.UTF-8/$fic"
	iconv -t UTF-8 -o $dest $src
	diff $src $dest
fi
