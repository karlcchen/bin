#!/bin/bash
#

VERBOSE=0
DEBUG=0
FIND_PATH="./"
FIND_TYPE="f"

if [ "$1" = "--verbose" ] ; then 
	printf "\nINFO: --verbose on\n\n"
	VERBOSE=1
	shift 1
fi 
if [ "$1" = "--debug" ] ; then 
	printf "\nDEBUG: --debug --verbose on\n\n"
	DEBUG=1
	VERBOSE=1
	shift 1
fi 

if [ -z "$1" ] ; then 
    printf ' find \"file_sepc\" for \"text_pattern\", Search path from current location'
    printf "\n Usage: %s\t file_spec pattern\n\n" "$0"
    printf "\n Example1:\n\t %s\t \'%s\' \"%s\" \n\n" "$0" "*.c *.h" "Hello"
    printf "\n Example2: only list files\n\t %s\t \'%s\' \n\n" "$0" "*.c *.h" 
    printf "\n Example3: search multiple patterns\n\t %s\t \'%s\' \"%s\"\n\n" "$0" "*.c *.h" "Hello|World"
    exit 1
fi

FIND_FILES="$1"
shift 1

name_patterns=()
LOOP=1
for pattern in ${FIND_FILES}
do
	if [ ${DEBUG} -ne 0 ] ; then 
		printf "### DEBUG: Parse loop:%s, file_spec=%s\n" "${LOOP}" "$pattern"
	fi 
	name_patterns+=(-o -name "${pattern}")
	LOOP=$((LOOP+1))
done

name_patterns=("${name_patterns[@]:1}")

LOOP=1
if [ -z "$1" ] ; then 
	find ${FIND_PATH} -type ${FIND_TYPE} "${name_patterns[@]}" ${FIND_OPT} 
else 
    while [ ! -z "$1" ] ;
    do
    	GREP_TEXT="$1"
    	shift 1
    	if [ ${VERBOSE} -ne 0 ] ; then 
    		printf "\n### INFO: LOOP:%s: find FIND_OPT=\"%s\", GREP_OPT=\"%s\"\n" "${LOOP}" "${FIND_OPT}" "${GREP_OPT}" 
    		echo -e "\t find ${FIND_PATH} -type ${FIND_TYPE} \( ${name_patterns[@]} \)" 
    		printf "\t grep \"%s\"\n\n" "${GREP_TEXT}" 
    	else 
#
# Note: use -print0 (null chacatcer), grep found less than when not using -print0
#    		find ${FIND_PATH} -type ${FIND_TYPE} "${name_patterns[@]}" ${FIND_OPT} -print0 | xargs -0 fgrep ${GREP_OPT} "${GREP_TEXT}"
#
# note: it is possible tell grep to search multiple patterns, use -e "p1" -e "p2", etc..., but result could be a little bit different
#
    		find ${FIND_PATH} -type ${FIND_TYPE} "${name_patterns[@]}" ${FIND_OPT} | xargs fgrep ${GREP_OPT} "${GREP_TEXT}"
    	fi 
    	LOOP=$((LOOP+1))
    done 

fi 


