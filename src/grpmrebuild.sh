#!/bin/bash
###############################################################################
#   grpmrebuild
#
#    Copyright (C) 2002 by Eric Gerbier
#    Bug reports to: gerbier@users.sourceforge.net
#    $Id: rpmrebuild 270 2004-07-12 11:48:02Z valery_reznic $
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
: ${DIALOG=dialog}

: ${DIALOG_OK=0}
: ${DIALOG_CANCEL=1}
: ${DIALOG_ESC=255}

title='GRPMREBUILD'
##################################################################
function choose_type() {
	choice=$( $DIALOG --stdout --clear --title $title \
	--menu " Choose the type of package you want ot work on :" 20 51 4 \
	"file"  "rpm file" \
	"database" "installed package (rpm database)"  )
	retval=$?

	case $retval in
	$DIALOG_OK)
		echo "'$choice' chosen."
	;;
	$DIALOG_CANCEL)
		echo "Cancel pressed.";
		exit
	;;
	$DIALOG_ESC)
		echo "ESC pressed.";
		exit
	;;
	esac
}
##################################################################
function select_file() {

	option="-p"

	local=`pwd`

	target=$( $DIALOG --stdout --clear --title $title --fselect $local 25 60  )

	case $? in
	$DIALOG_OK)
		echo "file \"$target\" chosen"
	;;
	$DIALOG_CANCEL)
		echo "Cancel pressed.";
		main_menu
	;;
	$DIALOG_ESC)
		echo "Box closed."
	;;
	esac
}
##################################################################
function select_installed() {

	echo "wait for rpm list"

	# we have to supress quotes to keep only 2 words by line
	liste_rpm=$( rpm -qa --queryformat '%{NAME}-%{VERSION}-%{RELEASE} ___%{SUMMARY}___ \\\n' | sort | sed -e "s/'/ /g" -e 's/`/ /g' -e 's/"/ /g' -e 's/___/"/g' )


	target=$(
		echo "$DIALOG --stdout --clear --title \"MENU BOX\" --menu \" Choose the installed package you want to work on :\" 20 70 15 $liste_rpm" | /bin/sh -
	)
	retval=$?


	case $retval in
	$DIALOG_OK)
		echo "rpm '$target' chosen."
	;;
	$DIALOG_CANCEL)
		echo "Cancel pressed.";
		main_menu
	;;
	$DIALOG_ESC)
		echo "ESC pressed.";
		exit
	;;
	esac
}
##################################################################
function select_options() {

	choice=$(
		$DIALOG --stdout --title $title \
		--checklist " Choose the rpmrebuild options :" 20 51 10 \
		"autoprovide"  "autoprovide" off \
		"autorequire"  "autorequire" off \
		"comment-missing"  "comment-missing" off \
		"edit-spec"  "edit-spec" off \
		"pug-from-fs" "pug-from-fs" off \
		"verbose"  "verbose" off \
		"verify"  "verify" off \
	)

	retval=$?

	for c in $choice
	do
		# remove quotes
		cc=$( echo $c | sed 's/"//g' )
		option="$option --$cc"

	done

	case $retval in
	$DIALOG_OK)
		echo "'$choice' chosen. : $option"
	;;
	$DIALOG_CANCEL)
		echo "Cancel pressed.";
		main_menu
	;;
	$DIALOG_ESC)
		echo "ESC pressed.";
		exit
	;;
	esac
}
##################################################################

function main_menu() {

	option=""

	choose_type

	case $choice in
	file)
		select_file
	;;
	database)
		select_installed
	;;
	*)
	;;
	esac

	select_options
}
##################################################################
main_menu

rpmrebuild $option $target
