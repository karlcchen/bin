#!/bin/bash
#
if [ -z "$1" ] ; then 
    echo
    echo ' search (shell script) *.sh files for multiple text pattern, always start from current path'
    echo 
    echo "Usage: fsh  pattern1 [pattern2]..."
    echo         
    exit 1
fi
while [ ! -z "$1" ] ;
do
#    echo 
#    echo " Searching: \"$1\"", Path: `pwd`  
#    echo 
    find . -type f \( -name "*.sh" \) ${FIND_OPT} -print0 | xargs -0 fgrep ${GREP_OPT} "$1"
    shift 1
done
