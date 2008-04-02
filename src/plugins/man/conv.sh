#!/bin/sh

fic=$1

src="fr_FR/$fic"

if [ -f $src ]
then
	dest="fr_FR.UTF-8/$fic"
	iconv -t UTF-8 -o $dest $src
	diff $src $dest
fi
