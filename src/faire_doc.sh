#!/bin/sh
# main doc
make man
for m in man/en/*.1
do
	dest=$( basename $m ).html
	./faire_doc2.sh $m $dest
done

# plugin doc
cd plugins
make man
cd ..
for m in plugins/man/en/*.1rrp
do
	dest=$( basename $m | sed -e 's/rrp$//').html
	./faire_doc2.sh $m $dest

done
