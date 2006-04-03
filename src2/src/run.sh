#!/bin/sh
# This script should be run only by the rpm via popt file"
# In the rpm-3.0.4 first param is /rpm/bin, second - ";"
# freshen.sh comment (in rpm-3.0.4) say that ';' may be 
# firest param too.
# In rpm-4.0.3 (may be early ?) popt does not pass additional parameters.

param_to_find=";"
case "x$param_to_find" in
   "x$1") shift 1;;
   "x$2") shift 2;;
esac
exec rpmrebuild "$@"
exit 1

