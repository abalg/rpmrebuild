#!/bin/sh
# a script test rpmrebuild on all installed packages
# internal use for developpers

list=$(rpm -qa | sort)

total=0
bad=0

for pac in $list
do
	let total="$total + 1"
	rpmrebuild -b -d . $pac > output  2>&1
	irep=$?
	if [ $irep -eq 0 ]
	then
		echo "$pac : ok"
	else
		echo "$pac : KO"
		cat output
		let bad="$bad + 1"
	fi
	rm -f ${pac}.spec
	rm -rf i386 i586 i686 noarch 2> /dev/null
done

echo "-------------------------------------------------------"
echo "$bad bad build on $total packages"
echo "-------------------------------------------------------"
