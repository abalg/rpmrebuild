#!/bin/sh
# reste a faire :
# supprimer le lien vers man2html en fin de page

src=$1
dest=$2
if [ -f $src ] 
then
	# verification du type man
	tst=$( file $src | egrep "ASCII|troff" )
	if [ -n "$tst" ]
	then

		echo '<?xml version="1.0" encoding="utf-8"?' > $dest
		# man en html
		man2html $src | grep -v "Content-type:" | grep -v "Return to Main Contents" | sed -e 's!http://localhost/cgi-bin/man/man2html!!g' -e 's!/man/man2html!!g' -e 's!\?[1-8]+!!g' -e 's!<A HREF="">man2html</A>!man2html!g' -e 's/<DL COMPACT>/<DL>/g'    >> $dest

		# html strict
		html2xhtml $dest

		# menage
	else
		echo "$src not in man format"
	fi
else
	echo "(faire_doc2) $src non trouve"
fi
