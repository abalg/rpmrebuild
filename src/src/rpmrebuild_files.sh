#!/bin/bash
###############################################################################
#   rpmrebuild_files.sh 
#      it's a part of the rpmrebuild project
#
#    Copyright (C) 2002, 2003 by Valery Reznic
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
# <file_verify> - file's verify flags (as %{FILEVERIFYFLAGS:octal})
# <file_lang>   - file's language     (as %{FILELANGS})
# <file>        - file name
#
# Environment:
#   RPMREBUILD_PUG_FROM_FS - if value is 'yes', use permission, owner and group
#                            from filesystem, otherwise - from package query
#   RPMREBUILD_COMMENT_MISSING  - 'yes' - comment missing files,
#                                  otherwise - nothing
################################################################

FFLAGS="d c s m n g"
d_val="%doc "      # doc flag
c_val="%config"    # config flag
s_val=""           # spec. DO I need do something with it ?
m_val="missingok " # missignok
n_val="noreplace " # noreplace
g_val="%ghost "    # ghost

# Should be in the same order as in rpm.
VERIFY_FLAGS="md5 size link user group mtime mode rdev"

while :; do
   read file_type
   [ "x$file_type" = "x" ] && break
   read file_flags
   read file_perm
   read file_user
   read file_group
   read file_verify
   read file_lang
   read file

   # bash 2 syntaxe
   #[[ $file = *\** ]] && file=$(echo "$file"|sed 's/\*/\\*/')
   # bash 1 but with a fork (grep)
   #wild=$(echo $file | grep "\*")
   #[ -n "$wild" ] && file=$(echo "$file"|sed 's/\*/\\*/')
   # quick and portable
   case "x$file" in
      x*\**) file=$(echo "$file"|sed 's/\*/\\*/');;
      x*) ;;
   esac
   miss_str=""
   if [ "X$RPMREBUILD_COMMENT_MISSING" = "Xyes" ]; then
      if [ -e "$file" ]; then
         miss_str=""
      else 
         miss_str='# MISSING: '
      fi
   fi

   # language handling
   [ "X$file_lang" = "X(none)" ] && file_lang=""
   lang_str=""
   [ "X$file_lang" = "X" ] || lang_str="%lang($file_lang) "
   
   # %dir handling
   dir_str=""
   [ "X$file_type" = "Xd" ] && dir_str="%dir "

   # %fflags handling
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

      # Reset strings' values
      config_par=""; config_full=""

      config_par="${m_str}${n_str}"
      # Handle a rpm's bug described by Han Holl:
      # There are missignok or/and noreplace flag but no config flag
      # In this case I simple force using '%config' string
      [ "X$config_par" = "X" ] || c_str=$c_val

      # Conacatenate c_str with config_param. 
      # If config param non-empty strip it's last character
      config_full="${c_str}${config_par:+(${config_par%?})}" 

      # If config_full string non-empty add space
      config_full="${config_full:+${config_full} }"

      fflags_str="${d_str}${config_full}${g_str}"
   fi

   # %attr handling
   if [ "X$RPMREBUILD_PUG_FROM_FS" = "Xyes" ]; then
   	attr_str=""
   else
   	file_perm="${file_perm#??}"
   	attr_str="%attr($file_perm $file_user $file_group) "
   fi

   # Verify handling
   verify_str=""
   verify_par=""
   non_verify_par=""
   Bit=1
   file_verify="0$file_verify" # make it octal for shell
   for verify_flag in $VERIFY_FLAGS; do
      if [ $[$file_verify & $Bit] -eq 0 ]; then
         non_verify_par="$non_verify_par$verify_flag "
      else
         verify_par="$verify_par$verify_flag "
      fi
      Bit=$[ $Bit << 1 ]
   done

   # if bit after last verify bit is off I assume that %verify( ...) was used
   # otherwise I assume %verify(not ...) was used. 
   if [ $[$file_verify & $Bit] -eq 0 ]; then ## Use "verify_par"
      # If verify_par not empty, set verify_str to %verify($verify_par)
      # Strip last character from verify_par
      verify_str="${verify_par:+%verify(${verify_par%?}) }" 
   else # Use "non_verify_par
      # If non_verify_par not empty, set verify_str to %verify(not $verify_par)
      # Strip last character from non_verify_par
      verify_str="${non_verify_par:+%verify(not ${non_verify_par%?}) }" 
   fi

   # test for jokers in file : globing seems not to work
   # for performance reason, just if warning flag
   if [ "X$RPMREBUILD_WARNING" = "Xyes" ]; then
	case "$file" in
      		*[*?]*)
			cat <<-WARN_TXT 1>&2 || exit
			
			-------------------------------- WARNING ------------------------------------------
			file named $file contains globbing characters
			rpm building may not work
			-----------------------------------------------------------------------------------
			WARN_TXT
		;;
	esac
   fi

   echo "${miss_str}${lang_str}${dir_str}${fflags_str}${attr_str}${verify_str}\"${file}\""
done || exit
exit 0
