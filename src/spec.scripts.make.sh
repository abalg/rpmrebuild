#!/bin/sh
###############################################################################
#
#    Copyright (C) 2002 by Eric Gerbier
#    Bug reports to: gerbier@users.sourceforge.net
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
(
   while :; do
      if ! read line; then
         [ "x$line" = "x" ] && break
      fi
      set -- $line
      case "X$1" in
         Xinclude)
            case "X$2" in
               X | X#*)
                  echo "$0: line '$line'" 1>2
                  echo "contains 'include' without filename." 1>&2
                  exit 1
               ;;

               *)
                  case "X$3" in
                     X | X#*) # ok, found include
                        cat -- "$2" || exit
                      ;;

                      *)
                         echo "$0: line '$line'" 1>&2
                         echo "contains 'include' with more than one filename." 1>&2
                         exit 1;
                      ;;
                  esac
               ;; 
            esac  
         ;;

         *)
            echo "$line" || exit
         ;;
      esac
   done
) || exit
exit 0
