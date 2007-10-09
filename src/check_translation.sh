#!/bin/bash
# a tool to check is translation files are ok
# can be sourced ?
# same tag on all translations

cd  locale
for trans in *
do
	# check syntaxe for include
	source $trans/rpmrebuild.lang

	# build tags
	cut -f1 -d= $trans/rpmrebuild.lang > check.$trans

done

# reference is the english translation
ref='check.en'
for f in check.*
do
	if [ $f != $ref ]
	then
		diff $f $ref
	fi

done
rm -f check.*
