#!/bin/bash
#
# fx - find and grep 
#

EXE_NAME="`realpath $0`"
EXE_DIR="`dirname ${EXE_NAME}`"

b_VERBOSE=0
b_DEBUG=0
FIND_PATH="./"
FIND_TYPE="f"

# predefined wildcards 
WC_BB='*.bb *.bbappend *.inc *.bbclass *.conf' 
WC_MK='make* Make* *.mk *.mak GNUmake*' 

function this_usage() {
    ${EXE_DIR}/asc reset green 
    printf '\n find \"file_spec\" with \"text_pattern\", default search begin path is current location'
    printf "\n Usage:\n\t %s\t file_spec pattern\n\n" "$0"
#
    printf "\n Predefind file specs:\n"
    ${EXE_DIR}/asc yellow
    printf " -bb" 
    ${EXE_DIR}/asc cyan
    printf " --> '%s\'\n" "${WC_BB}" 
    ${EXE_DIR}/asc yellow
    printf " -mk" 
    ${EXE_DIR}/asc cyan
    printf " --> \'%s\'\n" "${WC_MK}"  
#
    ${EXE_DIR}/asc green
    printf " Options:\n" 
    ${EXE_DIR}/asc yellow
    printf " --path=XXX" 
    ${EXE_DIR}/asc green
    printf " --> Search starts at XXX directory\n"     
#
#
# Note: cannot print string begin with "--", it's considered as option for printf
# The -- is used to tell the program that whatever follows should not be interpreted as a command line option to printf.
#  
    ${EXE_DIR}/asc yellow
    printf "%sfopt=YYY aa" ' --'
    ${EXE_DIR}/asc green 
    printf "%s pass option \"%s\" to find command\n" ' -->' "YYY aa"    
#
    ${EXE_DIR}/asc yellow
    printf "%sgopt=ZZZ cc" ' --'
    ${EXE_DIR}/asc green 
    printf "%s> pass option \"%s\" to grep command\n" ' -->' "ZZZ cc"    
#
    ${EXE_DIR}/asc yellow
    printf "%sd=n" ' -'
    ${EXE_DIR}/asc green 
    printf "\t%s> short format of \"%s\" for find command\n" ' -->' "-maxdepth n"    
    printf "\t same as long format"
    ${EXE_DIR}/asc cyan
    printf " \"--fopt=maxdepth n\"\n" 
#
    ${EXE_DIR}/asc green
    printf "\n Example1:\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s\t \'%s\' \"%s\" \n\n" "$0" "*.c *.h" "Hello"
#
    ${EXE_DIR}/asc green
    printf "\n Example2: only list files, if no search text specified\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s\t \'%s\' \n" "$0" "*.c *.h" 
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green
    printf "\n Example3: search multiple patterns, starting at directory XXX:\n" 
    ${EXE_DIR}/asc yellow
    printf "\t %s\t %s \'%s\' \"%s\"\n\n" "$0" "--path=XXX" "*.c *.h" "Hello|World"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green
    printf "\n Example4: use grep option -w, search \"word\" only:\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s\t \"%s\" \'%s\' \"%s\"\n\n" "$0" "--gopt=-w" "-bb" "DEVICETREE"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green
    printf "\n Example5: use find option: \"-maxepth 2\":\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s\t \"%s\" \'%s\' \"%s\"\n\n" "$0" "--fopt=-maxdepth 2" "-bb" "DEVICETREE"
    ${EXE_DIR}/asc green
    printf "\t OR, use '-d=2', a short form of '-maxdepth 2'\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s\t \"%s\" \'%s\' \"%s\"\n\n" "$0" "-d=2" "-bb" "DEVICETREE"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc reset 
}

OPT_CNT=1
while [ ! -z "$1" ] 
do 
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\nDEBUG1: input option #%d = \"%s\"\n" ${OPT_CNT} "$1"
    fi 
#    echo "$1" | grep '^\-\-' >/dev/null
    echo "$1" | grep '^\-' >/dev/null
    if [ $? -eq 0 ] ; then  
        OPT_STR_1=`echo "$1" | sed 's/=/ /1' | awk '{print $1}' | sed -e 's/[[:space:]]*$//'`
# removed trailing spaces of OPT_STR_2
        OPT_STR_2=`echo "$1" | sed 's/=/ /1' | awk '{print $2 " " $3}' | sed -e 's/[[:space:]]*$//'`

        if [ ${b_DEBUG} -ne 0 ] ; then 
            printf "\nDEBUG1: option parsed #%d: \"%s\" \"%s\"\n" ${OPT_CNT} "${OPT_STR_1}" "${OPT_STR_2}"
        fi 
        if [ "${OPT_STR_1}" = "--verbose" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
        	b_VERBOSE=1
            else
                b_VERBOSE=${OPT_STR_2}
            fi
            printf "\nINFO: --verbose=%d, --debug=%d\n" ${b_VERBOSE} ${b_DEBUG}
        elif [ "${OPT_STR_1}" = "--debug" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
        	b_DEBUG=1
            else
                b_DEBUG=${OPT_STR_2}
            fi
            b_VERBOSE=1
            printf "\nINFO: --debug=%d, verbose=%d\n" ${b_DEBUG} ${b_VERBOSE}
        elif [ "${OPT_STR_1}" = "--path" ] ; then 
            if [ ${b_VERBOSE} -ne 0 ] ; then 
                printf "\nINFO1: find starting path=%s\n" "${OPT_STR_1}"
            fi 
            if [ -d "${OPT_STR_2}" ] ; then 
                FIND_PATH="${OPT_STR_2}"
            else
                printf "\nERROR1: option --path=%s directory \"%s\" does not exist!\n\n" "${OPT_STR_2}" "${OPT_STR_2}"
                exit 1
            fi 
        elif [ "${OPT_STR_1}" = "--optend" ] ; then 
#
# no more options and skip this option 
#
            shift 1
            break 
        elif [ "${OPT_STR_1}" = "--fopt" ] ; then 
            FIND_OPT="${FIND_OPT} ${OPT_STR_2}"       
        elif [ "${OPT_STR_1}" = "--gopt" ] ; then 
            GREP_OPT="${GREP_OPT} ${OPT_STR_2}"       
        elif [ "${OPT_STR_1}" = "--help"  -o  "${OPT_STR_1}" = "-h" ] ; then 
            this_usage
            exit 1
        elif [ "${OPT_STR_1}" = "-d" ] ; then 
            FIND_OPT="-maxdepth ${OPT_STR_2}"       
        else
#
# anything don't know treat it as real argument
#
            break
        fi
    else
        break 
    fi
    OPT_CNT=$((OPT_CNT+1))
    shift 1
done

if [ -z "$1" ] ; then 
    this_usage
    exit 1
fi

FIND_FILES="$1"
shift 1
if [ ${b_DEBUG} -ne 0 ] ; then 
    printf "\nDEBUG2: FIND_FILES=\"%s\"\n" "${FIND_FILES}"
fi 

if [ "${FIND_FILES}" = "-bb" ] ; then 
    FIND_FILES="${WC_BB}"
    if [ ${b_VERBOSE} -ne 0 ] ; then 
        printf "\nINFO: -bb option, search list: %s\n" "${WC_BB}" 
    fi 
elif [ "${FIND_FILES}" = "-mk" ] ; then 
    FIND_FILES="${WC_MK}"
    if [ ${b_VERBOSE} -ne 0 ] ; then 
        printf "\nINFO: -mk option, search list: %s\n" "${FIND_FILES}"
    fi 
elif [ "${FIND_FILES}" = "-all" ] ; then 
    FIND_FILES="*"
    if [ ${b_VERBOSE} -ne 0 ] ; then 
        printf "\nINFO: -all option, search list: %s\n" "${FIND_FILES}"
    fi 
fi 

name_patterns=()
LOOP=1
if [ "${FIND_FILES}" = "*" ] ; then 
    name_patterns+=(-o -name '*')
    name_patterns=("${name_patterns[@]:1}")
    if [ ${b_VERBOSE} -ne 0 ] ; then 
        printf "\nINFO: search all files %s\n" "${FIND_FILES}" 
    fi 
else 
    for pattern in ${FIND_FILES}
    do
        if [ ${b_DEBUG} -ne 0 ] ; then 
            printf "### DEBUG2: search files #%s: \"%s\"\n" "${LOOP}" "$pattern"
        fi 
        name_patterns+=(-o -name "${pattern}")
        LOOP=$((LOOP+1))
    done
    name_patterns=("${name_patterns[@]:1}")
fi 

LOOP=1
if [ -z "$1" ] ; then 
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\n### DEBUG3: find, FIND_OPT=\"%s\", GREP_OPT=\"%s\"\n\n" "${FIND_OPT}" "${GREP_OPT}" 
        ${EXE_DIR}/asc reset yellow
        echo -e "\t find ${FIND_PATH} ${FIND_OPT} -type ${FIND_TYPE} ${name_patterns[@]}" 
        ${EXE_DIR}/asc reset 
    else
        find ${FIND_PATH} ${FIND_OPT} -type ${FIND_TYPE} ${name_patterns[@]} 
    fi
else 
    while [ ! -z "$1" ] ;
    do
    	GREP_TEXT="$1"
    	shift 1
    	if [ ${b_DEBUG} -ne 0 ] ; then 
    		printf "\n### DEBUG4: LOOP:%s: find FIND_OPT=\"%s\", GREP_OPT=\"%s\"\n\n" "${LOOP}" "${FIND_OPT}" "${GREP_OPT}" 
                ${EXE_DIR}/asc reset yellow
    		echo -e "\t find ${FIND_PATH} ${FIND_OPT} -type ${FIND_TYPE} \( ${name_patterns[@]} \)" 
    		printf "\t grep \"%s\"\n\n" "${GREP_TEXT}\n" 
                ${EXE_DIR}/asc reset 
    	else 
#
# Note: use -print0 (null chacatcer), grep found less than when not using -print0
#    		find ${FIND_PATH} -type ${FIND_TYPE} "${name_patterns[@]}" ${FIND_OPT} -print0 | xargs -0 fgrep ${GREP_OPT} "${GREP_TEXT}"
#
# note: it is possible tell grep to search multiple patterns, use -e "p1" -e "p2", etc..., but result could be a little bit different
#
            ${EXE_DIR}/asc reset yellow
    	    find ${FIND_PATH} ${FIND_OPT} -type ${FIND_TYPE} "${name_patterns[@]}" | xargs fgrep ${GREP_OPT} "${GREP_TEXT}"
            ${EXE_DIR}/asc reset 
    	fi 
    	LOOP=$((LOOP+1))
    done 
fi 
