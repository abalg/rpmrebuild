#!/bin/sh
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
