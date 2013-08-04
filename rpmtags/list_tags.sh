#!/bin/sh

distrib=$( lsb_release -i | awk '{print $3}' )
release=$( lsb_release -r | awk '{print $2}' )

#rpmver=$(rpm -q --queryformat '%{VERSION}' rpm )
rpmver=$(rpm --version | awk '{ print $3 }' )

rpm --querytags > querytags.${distrib}${release}_rpm${rpmver}

ls -altr querytags*
