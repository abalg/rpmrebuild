#!/bin/bash
###############################################################################
#   rpmrebuild_files.sh 
#      it's a part of the rpmrebuild project
#
#    Copyright (C) 2002 by Valery Reznic
#    Bug reports to: valery_reznic@users.sourceforge.net
#      or          : gerbier@users.sourceforge.net
#    $Id$
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

################################################################
# This script get from stanard input data in the following format:
# <file_type>   - type of the file (as first letter frpm 'ls -l' output)
# <file_flags>  - rpm file's flag (as %{FILEFLAGS:fflag}) - may be empty string
# <file_perm>   - file's permission (as %{FILEMODES:octal})
# <file_user>   - file's user id
# <file_group>  - file's group id
# <file>        - file name
################################################################

FFLAGS="d c s m n g"
d_val="%doc "      # doc flag
c_val="%config"    # config flag
s_val=""           # spec. DO I need do something with it ?
m_val="missingok " # missignok
n_val="noreplace " # noreplace
g_val="%ghost "    # ghost
while :; do
   read file_type
   [ "x$file_type" = "x" ] && break
   read file_flags
   read file_perm
   read file_user
   read file_group
   read file

   if [ -e "$file" ]; then
      miss_str=""
   else 
      miss_str='# MISSING: '
   fi

   
   dir_str=""
   [ "X$file_type" = "Xd" ] && dir_str="%dir "

   if [ "X$file_flags" = "X" ]; then
      fflags_str=""
   else
      for flag in $FFLAGS; do
         if [ "X${file_flags##*${flag}*}" = "X" ]; then
            eval ${flag}_str="\$${flag}_val"
         else
            eval ${flag}_str=""
         fi
      done

      config_par=""; config_full=""
      config_par="${m_str}${n_str}"
      config_full="${c_str}${config_par:+(${config_par%?})}" 
      config_full="${config_full:+${config_full} }"
      fflags_str="${d_str}${config_full}${g_str}"
   fi

   if [ -z "$keep_perm" ]
   then
   	file_perm="${file_perm#??}"
   	attr_str="%attr($file_perm $file_user $file_group) "
   else
   	attr_str=""
   fi
   echo "${miss_str}${dir_str}${fflags_str}${attr_str}${file}"
done
