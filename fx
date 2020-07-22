#!/bin/bash
#
# fx - find and grep 
#

# disable the glob (noglob)
# otherwise search argumnet of '*.sh' will be processed by shell
set -f
#

s_VERSION="1.1"
EXE_NAME="`realpath $0`"
EXE_BASE="`basename ${EXE_NAME}`"
EXE_DIR="`dirname ${EXE_NAME}`"

GREP_EXE="fgrep"
FIND_EXE="find"

b_VERBOSE=0
b_DEBUG=0

FIND_NAME="-name"
#FIND_NAME="-iname"
FIND_NAME_LIST="-name -iname -lname -ilname"
FIND_PATH="."
FIND_TYPE="-type f"
FIND_TYPE_LIST="f l d b c p s D"
# default main option of find, must appeared before the first search path
# default is "-P", other options are : -L -H -Olevel
FIND_MAIN_OPT=""
FIND_MAIN_OPT_LIST="P L H O"
export FIND_OPT="${FIND_OPT} -prune"
XARGS_OPT=""
ARG_SAVED=()

# predefined wildcards for find -name patterns
FIND_PATTERN_BB='*.bb *.bbappend *.inc *.bbclass *.conf' 
FIND_PATTERN_MK='make* Make* *.mk *.mak GNUmake*' 
FIND_PATTERN_CH="*.c *.h *.S"
#FIND_PATTERN_CH="*.c *.h"
FIND_PATTERN_CCH="${FIND_PATTERN_CH} *.cc *.cpp *.cxx *.hpp"
FIND_PATTERN_ALL='*'

function this_usage() {
    ${EXE_DIR}/asc reset green 
    printf '\n find \"files\" with \"name patterns\", default search begin path is current location. Version:%s\n' "${s_VERSION}"
    printf " Usage:\n\t %s\t filename_patterns file_content_patterns\n" "${EXE_BASE}"
#
    printf "\n Predefind \"%s\" file test \"%s\" patterns:\n" "${FIND_EXE}" "${FIND_NAME}"
#
    ${EXE_DIR}/asc yellow
    printf " -bb " 
    ${EXE_DIR}/asc cyan
    printf " --> '%s\'\n" "${FIND_PATTERN_BB}" 
#
    ${EXE_DIR}/asc yellow
    printf " -mk " 
    ${EXE_DIR}/asc cyan
    printf " --> \'%s\'\n" "${FIND_PATTERN_MK}"  
#
    ${EXE_DIR}/asc yellow
    printf " -ch " 
    ${EXE_DIR}/asc cyan
    printf " --> \'%s\'\n" "${FIND_PATTERN_CH}"  
#
    ${EXE_DIR}/asc yellow
    printf " -cch" 
    ${EXE_DIR}/asc cyan
    printf " --> \'%s\'\n" "${FIND_PATTERN_CCH}"  
#
    ${EXE_DIR}/asc yellow
    printf " -all" 
    ${EXE_DIR}/asc cyan
    printf " --> \'%s\'\n" "${FIND_PATTERN_ALL}"  
# options: begin ==========================================================
#
    ${EXE_DIR}/asc green
    printf " Options:\n" 
#
# Note: cannot print string begin with "--", it's considered as option for printf
# The -- is used to tell the program that whatever follows should not be interpreted as a command line option to printf.
#  
    ${EXE_DIR}/asc yellow
    printf ' \"%sFOPT=%s' '--' '-P'
    ${EXE_DIR}/asc green 
    printf "%s set find main option to %s, as first option placed after find command\n" ' -->' "-P"
    printf "\t\t Valid find main optioins are: "
    ${EXE_DIR}/asc yellow
    printf "%s\n" "${FIND_MAIN_OPT_LIST}"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc yellow
    printf " \"%sfopt=YYY aa\"" '--'
    ${EXE_DIR}/asc green 
    printf "%s append option \"%s\" to env %s, used when calling find command\n" ' -->' "YYY aa" "FIND_OPT"   
#
    ${EXE_DIR}/asc yellow
    printf " \"--fpath=XXX|-p=XXX\"" 
    ${EXE_DIR}/asc green
    printf " --> Search starts at XXX directory\n"     
#
    ${EXE_DIR}/asc yellow
    printf " \"--ftype=l|-t=l\"" 
    ${EXE_DIR}/asc green
    printf " --> set find file type from default of \"%s\" to \"-type l\"\n" "${FIND_TYPE}"    
    printf "\t\t --ftype without input deletes the option, \"find\" default searches all file types\n"
    printf "\t\t Valid find types are: "
    ${EXE_DIR}/asc yellow
#
#              b      block (buffered) special
#              c      character (unbuffered) special
#              d      directory
#              p      named pipe (FIFO)
#              f      regular file
#              l      symbolic link; this is never true if the -L option or
#                     the -follow option is in effect, unless the symbolic
#                     link is broken.  If you want to search for symbolic
#                     links when -L is in effect, use -xtype.
#              s      socket
#              D      door (Solaris)
#
    printf "%s\n" "${FIND_TYPE_LIST}"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc yellow
    printf " \"--fname=-iname\"" "-iname"
    ${EXE_DIR}/asc green
    printf " --> change find test case from default \"%s\" to \"%s\"\n" "${FIND_NAME}"  "-iname"  
    printf "\t\t Valid find test are: "
    ${EXE_DIR}/asc yellow
#
    printf "%s\n" "${FIND_NAME_LIST}"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc yellow
    printf " \"%sgopt=-w\"" '--'
    ${EXE_DIR}/asc green 
    printf "%s> append option \"%s\" to env %s, used when calling grep command\n" ' -->' "-w" "GREP_OPT"   
#
    ${EXE_DIR}/asc yellow
    printf " \"%sgopt %sgopt=-Hw --color=auto\"" '--' '--'
    ${EXE_DIR}/asc green 
    printf "%s> first delete old grep options, then set new grep options to \"%s\"\n" ' -->' "-Hw --color=auto"    
#
    ${EXE_DIR}/asc yellow
    printf " \"%soptend\"" '--'
    ${EXE_DIR}/asc green 
    printf "%s> end of options parsing, treat arguments after here as non-options arguments\n" ' -->' 
#
    ${EXE_DIR}/asc yellow
    printf " \"%sd=n|%sdn\"" ' -' '-'
    ${EXE_DIR}/asc green 
    printf "\t%s> short format of \"%s\" option for find command\n" ' -->' "-maxdepth n"    
    printf "\t\t same as long format"
    ${EXE_DIR}/asc cyan
    printf " \"--fopt=maxdepth n\"\n" 
#
    ${EXE_DIR}/asc green 
    printf " Example 1:\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s \'%s\' \"%s\" \n" "${EXE_BASE}" "*.c *.h" "Hello"
#
    ${EXE_DIR}/asc green 
    printf " Example 2: only list files, if no search text specified\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s \'%s\' \n" "${EXE_BASE}" "*.c *.h" 
    printf "\t %s \'%s\' \n" "${EXE_BASE}" "-bb" 
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green
    printf " Example 3: search multiple patterns, starting at directory XXX:\n" 
    ${EXE_DIR}/asc yellow
    printf "\t %s %s \'%s\' \"%s\"\n" "${EXE_BASE}" "--fpath=XXX" "*.c *.h" "Hello|World"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green 
    printf " Example 4: append grep option -w, search \"word\" only:\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s \"%s\" \'%s\' \"%s\"\n" "${EXE_BASE}" "--gopt=-w" "-bb" "DEVICETREE"
    ${EXE_DIR}/asc green 
    printf " Example 4a: set grep env GREP_OPT=\"\", which is empty\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s \"%s\" \'%s\' \"%s\"\n" "${EXE_BASE}" "--gopt" "-bb" "DEVICETREE"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green 
    printf " Example 5: use find option: \"-maxepth 2\":\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s \"%s\" \'%s\' \"%s\"\n" "${EXE_BASE}" "--fopt=-maxdepth 2" "-bb" "DEVICETREE"
    ${EXE_DIR}/asc green
    printf "\t OR, use '-d2', a short form of '-maxdepth 2'\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s \"%s\" \'%s\' \"%s\"\n\n" "${EXE_BASE}" "-d2" "-bb" "DEVICETREE"
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
        # removed trailing spaces of OPT_STR_2
        OPT_STR_1=`echo "$1" | sed 's/=/ /1' | awk '{print $1}' | sed -e 's/[[:space:]]*$//'`
        OPT_STR_2=""
        echo "$1" | grep '=' >/dev/null
        if [ $? -eq 0 ] ; then 
            OPT_STR_2=`echo "$1" | sed 's/=/ /1' | awk '{print $2 " " $3}' | sed -e 's/[[:space:]]*$//'`
        else 
            echo "$1" | grep "[[:digit:]]" >/dev/null
            if [ $? -eq 0 ] ; then 
                OPT_STR_1=`echo "$1" | sed 's/[[:digit:]]/ /1' | awk '{print $1}' | sed -e 's/[[:space:]]*$//'`
                OPT_STR_2=`echo "$1" | sed 's/[^0-9]*//g'`
            fi 
        fi  
        if [ ${b_DEBUG} -ne 0 ] ; then 
            printf "\nDEBUG1: the #%d options parsed: #1=\"%s\", #2=\"%s\"\n" ${OPT_CNT} "${OPT_STR_1}" "${OPT_STR_2}"
        fi 
        if [ "${OPT_STR_1}" = "--verbose" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
        	b_VERBOSE=1
            else
                b_VERBOSE=${OPT_STR_2}
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-1: set --verbose=%d, --debug=%d\n" ${b_VERBOSE} ${b_DEBUG}
            fi
        elif [ "${OPT_STR_1}" = "--debug" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
        	b_DEBUG=1
            else
                b_DEBUG=${OPT_STR_2}
            fi
            b_VERBOSE=1
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-2: set --debug=%d, verbose=%d\n" ${b_DEBUG} ${b_VERBOSE}
            fi
        elif [ "${OPT_STR_1}" = "--ftype" -o  "${OPT_STR_1}" = "-t" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nWARN-1: --ftype=\"\", find file type changed from \"%s\" to empty\n" "${FIND_TYPE}"
                fi
                FIND_TYPE=""
            else
                FIND_TYPE="-type ${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-3: find type changed to: \"%s\"\n" "${FIND_TYPE}"
            fi 
        elif [ "${OPT_STR_1}" = "--FOPT" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nWARN-2: --FOPT=\"\", find (main) OPTIONS changed from \"%s\" to empty\n" "${FIND_MAIN_OPT}"
                fi
                FIND_MAIN_OPT=""
            else
                FIND_MAIN_OPT="${FIND_MAIN_OPT} ${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-4: set find (main) OPTIONS changed to: \"%s\"\n" "${FIND_MAIN_OPT}"
            fi 
        elif [ "${OPT_STR_1}" = "--fname" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nERROR-OPT: --fname cannot be empty\n" 
                fi
            else
                FIND_NAME="${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-4: set find TEST name to: \"%s\"\n" "${FIND_NAME}"
            fi 
        elif [ "${OPT_STR_1}" = "--fopt" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nWARN-2: --fopt=\"\", find options changed from \"%s\" to empty\n" "${FIND_OPT}"
                fi
                FIND_OPT=""
            else
                FIND_OPT="${FIND_OPT} ${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-4: set find options changed to: \"%s\"\n" "${FIND_OPT}"
            fi 
        elif [ "${OPT_STR_1}" = "--gopt" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nWARN-3: --gopt=\"\", grep options changed from \"%s\" to empty\n" "${GREP_OPT}"
                fi
                GREP_OPT=""
            else
                GREP_OPT="${GREP_OPT} ${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-5: set grep options changed to: \"%s\"\n" "${GREP_OPT}"
            fi 
        elif [ "${OPT_STR_1}" = "--fpath" -o "${OPT_STR_1}" = "-p" ] ; then 
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-6: find starting path=%s\n" "${OPT_STR_1}"
            fi 
            if [ -d "${OPT_STR_2}" ] ; then 
                FIND_PATH="${OPT_STR_2}"
            else
                printf "\nERROR1: option --fpath=%s directory \"%s\" does not exist!\n\n" "${OPT_STR_2}" "${OPT_STR_2}"
                exit 1
            fi 
        elif [ "${OPT_STR_1}" = "--help"  -o  "${OPT_STR_1}" = "-h" ] ; then 
            this_usage
            exit 1
        elif [ "${OPT_STR_1}" = "-d" ] ; then 
            FIND_OPT="-maxdepth ${OPT_STR_2}"       
        elif [ "${OPT_STR_1}" = "--optend" ] ; then 
#
# no more options and skip this option 
#
            shift 1
            break 
        else
#
# anything don't know treat it as real argument
#
            ARG_SAVED+=("$1")
        fi
    else
        ARG_SAVED+=("$1")
    fi
    OPT_CNT=$((OPT_CNT+1))
    shift 1
done

if [ ${b_DEBUG} -ne 0 ] ; then 
    echo -e "\n DEBUG: ARG_SAVED=\"${ARG_SAVED[@]}\"\n"
fi 

if [ -z "${ARG_SAVED[0]}" ] ; then 
    this_usage
    exit 1
fi

#
FIND_FILES="${ARG_SAVED[0]}"
if [ "${FIND_FILES}" = "-bb" ] ; then 
    FIND_FILES="${FIND_FILES} ${FIND_PATTERN_BB}"
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\nINFO-10: -bb option, change search list to: \'%s\'\n" "${FIND_PATTERN_BB}" 
    fi 
elif [ "${FIND_FILES}" = "-mk" ] ; then 
    FIND_FILES="${FIND_FILES} ${FIND_PATTERN_MK}"
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\nINFO-11: -mk option, change search list to: \'%s\'\n" "${FIND_FILES}"
    fi 
elif [ "${FIND_FILES}" = "-ch" ] ; then 
    FIND_FILES="${FIND_FILES} ${FIND_PATTERN_CH}"
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\nINFO-12: -ch option, change search list to: \'%s\'\n" "${FIND_FILES}"
    fi 
elif [ "${FIND_FILES}" = "-cch" ] ; then 
    FIND_FILES="${FIND_FILES} ${FIND_PATTERN_CCH}"
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\nINFO-13 -cch option, change search list to: \'%s\'\n" "${FIND_FILES}"
    fi 
elif [ "${FIND_FILES}" = "-all" ] ; then 
    FIND_FILES="${FIND_FILES} ${FIND_PATTERN_ALL}"
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\nINFO-14: -all option, change search list to: \'%s\'\n" "${FIND_FILES}"
    fi 
fi 

if [ ${b_DEBUG} -ne 0 ] ; then 
    printf "\nDEBUG2: FIND_FILES=\"%s\"\n" "${FIND_FILES}"
fi 

#
name_patterns=()
LOOP=1
if [ "${FIND_FILES}" = "*" ] ; then 
    name_patterns+=(-o ${FIND_NAME} '*')
    name_patterns=("${name_patterns[@]:1}")
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\nINFO-20: search all files %s\n" "${FIND_FILES}" 
    fi 
else 
    for pattern in ${FIND_FILES}
    do
        if [ ${b_DEBUG} -ne 0 ] ; then 
            printf "### INFO-21: search files #%s: \"%s\"\n" "${LOOP}" "$pattern"
        fi 
        name_patterns+=(-o ${FIND_NAME} "${pattern}")
        LOOP=$((LOOP+1))
    done
    name_patterns=("${name_patterns[@]:1}")
# enable the glob (noglob)
#   set +f
fi 

# ========================================================================================================================
LOOP=1
if [ -z "${ARG_SAVED[${LOOP}]}" ] ; then 
#
# no grep texts
#
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\n### DEBUG-no-grep: find, FIND_OPT=\"%s\", GREP_OPT=\"%s\"\n\n" "${FIND_OPT}" "${GREP_OPT}" 
        ${EXE_DIR}/asc reset yellow
        echo -e "\t ${FIND_EXE} ${FIND_MAIN_OPT} ${FIND_PATH} ${FIND_TYPE} \( ${name_patterns[@]} \) ${FIND_OPT}\n" 
        ${EXE_DIR}/asc reset 
    else
#
# need "\(" so that type is working for all ${FIND_NAME}("-name") not just the first one
#
        ${FIND_EXE} ${FIND_MAIN_OPT} ${FIND_PATH} ${FIND_TYPE} \( "${name_patterns[@]}" \) ${FIND_OPT} 
    fi
else 
#
# with grep texts
#
    while [ ! -z "${ARG_SAVED[${LOOP}]}" ] ;
    do
    	GREP_TEXT="${ARG_SAVED[${LOOP}]}"
    	if [ ${b_DEBUG} -ne 0 ] ; then 
    		printf "\n### DEBUG4: LOOP:%s: find FIND_OPT=\"%s\", GREP_OPT=\"%s\"\n\n" "${LOOP}" "${FIND_OPT}" "${GREP_OPT}" 
                ${EXE_DIR}/asc reset yellow
    		echo -e "\t ${FIND_EXE} ${FIND_MAIN_OPT} ${FIND_PATH} ${FIND_TYPE} \( ${name_patterns[@]} \) ${FIND_OPT} | xargs ${XARGS_OPT} ${GREP_EXE} ${GREP_OPT} \"${GREP_TEXT}\"\n\n"  
                ${EXE_DIR}/asc reset 
    	else 
#
# Note: use -print0 (null chacatcer), grep found less than when not using -print0
#    		find ${FIND_PATH} ${FIND_TYPE} "${name_patterns[@]}" ${FIND_OPT} -print0 | xargs -0 fgrep ${GREP_OPT} "${GREP_TEXT}"
#
# note: it is possible tell grep to search multiple patterns, use -e "p1" -e "p2", etc..., but result could be a little bit different
#
#
# TIPS Note: 
# -  need "\(" so that "type -f" is working for all ${FIND_NAME}("-name") not just the first one
# -  also makes -print0 working on all found files...
# - using -print0 so filenames with "spaces" can be passed to grep correctly
#
            ${FIND_EXE} ${FIND_MAIN_OPT} ${FIND_PATH} ${FIND_TYPE} \( "${name_patterns[@]}" \) ${FIND_OPT} -print0 | xargs --null ${XARGS_OPT} ${GREP_EXE} ${GREP_OPT} "${GREP_TEXT}"
    	fi 
    	LOOP=$((LOOP+1))
    done
fi

