#!/bin/sh
# a script test rpmrebuild on all installed packages
# internal use for developpers
# $Id$

function bench {
	list=$( rpm -qa | sort )
	max=$( echo "$list" | wc -l )

	seen=0
	notok=0
	bad=0
	pbmagic=0
	pbdep=0
	list_bad=''

	for pac in $list
	do
		let seen="$seen + 1"
		echo -n "$seen/$max $pac "
		output=$( nice rpmrebuild -b -k  -y no -c yes -d $tmpdir $pac  2>&1 )
		irep=$?
		if [ $irep -eq 0 ]
		then
			echo "ok"
		else

			# parse output to remove false problems
			# dependencies problem ...
			# and only keep real rpmrebuild errors
			# todo : pubkey ?

			depend=$( echo "$output" | grep "Failed dependencies" )
			changelog=$( echo "$output" | grep "changelog not in descending chronological order" )
			cpio=$( echo "$output" | grep "cpio: Bad magic" )
			if [ -n "$depend" ]
			then
				echo "NOTOK (Failed dependencies)"
				echo "  $output"
				let notok="$notok + 1"
				let pbdep="$pbdep + 1"
			elif [ -n "$changelog" ]
			then
				echo "NOTOK (changelog not in descending chronological order)"
				echo "  $output"
				let notok="$notok + 1"
			elif [ -n "$cpio" ]
			then
				echo "NOTOK (cpio: Bad magic)"
				echo "  $output"
				let notok="$notok + 1"
				let pbmagic="$pbmagic + 1"
			else
				echo "KO"
				echo "  $output"
				let bad="$bad + 1"
				list_bad="$list_bad $pac"
			fi
		fi
		#rm -f ${pac}.spec
		# remove new rpm files to avoid file system full
		rm -f $tmpdir/i386/* $tmpdir/i586/* $tmpdir/i686/* $tmpdir/noarch/* $tmpdir/x86_64/* 2> /dev/null
	done

	# clean temporary directories
	rm -rf $tmpdir 2> /dev/null

	echo "-------------------------------------------------------"
	echo "$bad bad build on $seen packages"
	echo "list of failed : $list_bad"
	echo "$notok failed build"
	echo "  pb cpio : $pbmagic"
	echo "  pb dep : $pbdep"
	echo "full log on $LOG"
	echo "-------------------------------------------------------"

}

############################################################
# main
############################################################

tmpdir=/tmp/rpmrebuild

if [ -d $tmpdir ]
then
	echo "remove old repository $tmpdir"
	mkdir -p $tmpdir
fi

LOG=rpmrebuild_bench.log
if [ -f $LOG ]
then
	mv $LOG $LOG.old
fi

# to have standardize error messages
export LC_ALL=POSIX

bench 2>&1 | tee $LOG
