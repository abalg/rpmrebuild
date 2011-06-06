#!/bin/sh
# a script test rpmrebuild on all installed packages
# internal use for developpers
# $Id$

function bench {
	list=$(rpm -qa | sort)

	total=0
	notok=0
	bad=0

	for pac in $list
	do
		echo -n "$pac : "
		let total="$total + 1"
		output=$( nice rpmrebuild -b -k  -y no -c yes -d $tmpdir $pac  2>&1 )
		irep=$?
		if [ $irep -eq 0 ]
		then
			echo "ok"
		else

			# todo : parse output to remove false problems
			# dependencies problem ...
			# and only keep real rpmrebuild errors

			depend=$( echo "$output" | grep "Failed dependencies" )
			changelog=$( echo "$output" | grep "changelog not in descending chronological order" )
			if [ -n "$depend" ]
			then
				echo "notok (Failed dependencies)"
				echo "$output"
				let notok="$notok + 1"

			elif [ -n "$changelog" ]
			then
				echo "notok (changelog not in descending chronological order)"
				echo "$output"
				let notok="$notok + 1"
			else
				echo "KO"
				echo "$output"
				let bad="$bad + 1"
			fi
		fi
		rm -f $pac.spec
		# remove new rpm files to avoid file system full
		rm -f $tmpdir/i386/* $tmpdir/i586/* $tmpdir/i686/* $tmpdir/noarch/* 2> /dev/null
	done

	# clean temporary directories
	rmdir $tmpdir/i386 $tmpdir/i586 $tmpdir/i686 $tmpdir/noarch 2> /dev/null

	echo "-------------------------------------------------------"
	echo "$bad bad build on $total packages"
	echo "$notok failed build"
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
