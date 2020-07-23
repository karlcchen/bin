#!/bin/bash
#
# fx - find and grep 
#

# disable the glob (noglob)
# otherwise search argumnet of '*.sh' will be processed by shell
set -f
#

b_GLOB_restore=1
s_VERSION="1.1"
EXE_NAME="`realpath $0`"
EXE_BASE="`basename ${EXE_NAME}`"
EXE_DIR="`dirname ${EXE_NAME}`"

#GREP_EXE="fgrep"
# Note: fgrep doesn't not take "-E" for pattern "XXX|YYY"
GREP_EXE="grep"
# -E use Extended regular expression 
#GREP_OPT="${GREP_OPT} -E"
FIND_EXE="find"
#FIND_OPT="${FIND_OPT}"

XARGS_EXE="xargs"

b_VERBOSE=0
b_DEBUG=0

FIND_NAME="-name"
#FIND_NAME="-iname"
FIND_NAME_LIST="-name -iname -lname -ilname"

# NOTES: 
# - if starting path is '.', maxdepth 1, search only current directory, maxdepth 0 found NOTHING   
# - if starting path is '*', maxdepth 0, search only current directory 
# FIND_PATH='.'
# NOTE: maxdepth is one depth deeper if starting path is '.'
FIND_PATH='*'

FIND_TYPE="-type f"
FIND_TYPE_LIST="f l d b c p s D"
# default main option of find, must appeared before the first search path
# default is "-P", other options are : -L -H -Olevel
FIND_HEAD_OPT=""
FIND_HEAD_OPT_LIST="P L H O"
FIND_TAIL_OPT="-prune"

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
    printf '\n find \"filename patterns\" with \"content text patterns\", default search path beginning is current directory. Version:%s\n' "${s_VERSION}"
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
    printf " \"%sfopt|-f=-maxdepth 2\"" '--'
    ${EXE_DIR}/asc green 
    printf "%s append option \"%s\" to env %s, used when calling find command\n" ' -->' "-maxdepth 2" "FIND_OPT"   
#
    ${EXE_DIR}/asc yellow
    printf " \"--fpath|-fp=XXX\"" 
    ${EXE_DIR}/asc green
    printf " --> Search starts at XXX directory\n"     
#
    ${EXE_DIR}/asc yellow
    printf " \"--ftype|-ft=l[,d]\"" 
    ${EXE_DIR}/asc green
    printf " --> set find file type from default of \"%s\" to \"-type l\", and optionally \"-type d\" as well\n" "${FIND_TYPE}"
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
    printf "%s" "${FIND_TYPE_LIST}"
    ${EXE_DIR}/asc green
    printf ", Note: use " 
    ${EXE_DIR}/asc yellow
    printf "\"%s\" comma" ","
    ${EXE_DIR}/asc green
    printf " to separate multiple options\n" "${FIND_TYPE_LIST}"
#
    ${EXE_DIR}/asc yellow
    printf " \"--fname|-fn=-iname\"" "-iname"
    ${EXE_DIR}/asc green
    printf " --> change find test case from default \"%s\" to \"%s\"\n" "${FIND_NAME}"  "-iname"  
    printf "\t\t Valid find test are: "
    ${EXE_DIR}/asc yellow
#
    printf "%s\n" "${FIND_NAME_LIST}"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc yellow
    printf ' \"%sfhead|-fh=%s\"' '--' '-P' 
    ${EXE_DIR}/asc green 
    printf " %s set \"%s\" (head) option to %s, the first option of the command\n" ' -->' "${FIND_EXE}" "-P"
    printf "\t\t Valid (head) optioins are: "
    ${EXE_DIR}/asc yellow
    printf "%s\n" "${FIND_HEAD_OPT_LIST}"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc yellow
    printf ' \"%sftail|-ft=%s\"' '--' '-prune' 
    ${EXE_DIR}/asc green 
    printf " %s set \"%s\" (tail) option to %s, the last option of the command\n" ' -->' "${FIND_EXE}" "-prune"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc yellow
    printf " \"%sgopt|-g=-w\"" '--'
    ${EXE_DIR}/asc green 
    printf "%s> append option \"%s\" to env %s, used when calling grep command\n" ' -->' "-w" "GREP_OPT"   
#
    ${EXE_DIR}/asc yellow
    printf " \"-g -g=-Hw --color=auto\"" 
    ${EXE_DIR}/asc green 
    printf "%s> first delete old grep options, then set new grep options to \"%s\"\n" ' -->' "-Hw --color=auto"    
#
    ${EXE_DIR}/asc yellow
    printf " \"%sgexe|-ge=egrep\"" "--"
    ${EXE_DIR}/asc green 
    printf "%s>  change default \"%s\" command to \"%s\"\n" ' -->' "${GREP_EXE}" "egrep"
#
    ${EXE_DIR}/asc yellow
    printf " \"%soptend\"" '--'
    ${EXE_DIR}/asc green 
    printf "%s> indicate end of all options parsing, treat arguments followed as non-options arguments\n" ' -->' 
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
    printf " Example 3: search multiple patterns, starting from directory : ../\n" 
    ${EXE_DIR}/asc yellow
    printf "\t %s %s \'%s\' \"%s\" \"%s\"\n" "${EXE_BASE}" "-fp=../" "*.c *.h" "Hello" "World"
    ${EXE_DIR}/asc green
    printf "\t OR, same as last example, but run \"find\" onlY once for both patterns, using regular expression, grep option -E\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s %s \'%s\' \"%s\" \"%s\"\n" "${EXE_BASE}" "-fp=../" "--gopt=-E" "*.c *.h" "Hello|World"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green 
    printf " Example 4: append grep option -w, search \"word\" only:\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s \"%s\" \'%s\' \"%s\"\n" "${EXE_BASE}" "-g=-w" "-bb" "DEVICETREE"
    ${EXE_DIR}/asc green 
    printf " Example 4a: set grep env GREP_OPT=\"\", which is empty\n"
    ${EXE_DIR}/asc yellow
    printf "\t %s \"%s\" \'%s\' \"%s\"\n" "${EXE_BASE}" "-g" "-bb" "DEVICETREE"
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

FIND_PATTERN=""
N_ARG_SAVED=0
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
            printf "\nDEBUG-1: the #%d options parsed: #1=\"%s\", #2=\"%s\"\n" ${OPT_CNT} "${OPT_STR_1}" "${OPT_STR_2}"
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
        elif [ "${OPT_STR_1}" = "--glob" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
            # default always restore glob before running find 
        	b_GLOB_restore=1
            else
                b_GLOB_restore=${OPT_STR_2}
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-3: restore --glob=%d\n" ${b_GLOB_restore}
            fi
        elif [ "${OPT_STR_1}" = "--ftype" -o  "${OPT_STR_1}" = "-ft" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nWARN-1: --ftype=\"\", find file type changed from \"%s\" to empty\n" "${FIND_TYPE}"
                fi
                FIND_TYPE=""
            else
                FIND_TYPE="-type ${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-4: find type changed to: \"%s\"\n" "${FIND_TYPE}"
            fi 
        elif [ "${OPT_STR_1}" = "--fhead" -o "${OPT_STR_1}" = "-fh" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nWARN-2: --fhead=\"\", \"%s\" (head) OPTIONS changed from \"%s\" to empty\n" "${FIND_EXE}" "${FIND_HEAD_OPT}"
                fi
                FIND_HEAD_OPT=""
            else
                FIND_HEAD_OPT="${FIND_HEAD_OPT} ${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-5: set \"%s\" (head) OPTIONS changed to: \"%s\"\n" "${FIND_EXE}" "${FIND_HEAD_OPT}"
            fi 
        elif [ "${OPT_STR_1}" = "--ftail" -o "${OPT_STR_1}" = "-ft" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nWARN-2: --ftail=\"\", \"%s\" (head) OPTIONS changed from \"%s\" to empty\n" "${FIND_EXE}" "${FIND_TAIL_OPT}"
                fi
                FIND_TAIL_OPT=""
            else
                FIND_TAIL_OPT="${FIND_TAIL_OPT} ${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-6: set \"%s\" (tail) OPTIONS changed to: \"%s\"\n" "${FIND_EXE}" "${FIND_TAIL_OPT}"
            fi 
        elif [ "${OPT_STR_1}" = "--fname" -o "${OPT_STR_1}" = "-fn" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nERROR-OPT: --fname cannot be empty\n" 
                fi
            else
                FIND_NAME="${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-7: set find TEST name to: \"%s\"\n" "${FIND_NAME}"
            fi 
        elif [ "${OPT_STR_1}" = "--fopt" -o "${OPT_STR_1}" = "-f" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nWARN-2: --fopt=\"\", find options changed from \"%s\" to empty\n" "${FIND_OPT}"
                fi
                FIND_OPT=""
            else
                FIND_OPT="${FIND_OPT} ${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-8: set find options changed to: \"%s\"\n" "${FIND_OPT}"
            fi 
        elif [ "${OPT_STR_1}" = "--gopt" -o "${OPT_STR_1}" = "-g" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nWARN-3: --gopt=\"\", grep options changed from \"%s\" to empty\n" "${GREP_OPT}"
                fi
                GREP_OPT=""
            else
                GREP_OPT="${GREP_OPT} ${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-9: set grep options changed to: \"%s\"\n" "${GREP_OPT}"
            fi 
        elif [ "${OPT_STR_1}" = "--gexe" -o "${OPT_STR_1}" = "-ge" ] ; then 
            if [ -z "${OPT_STR_2}" ] ; then 
                if [ ${b_DEBUG} -ne 0 ] ; then 
                    printf "\nERROR-3: --gexe options cannot be empty!\n"
                fi
            else
                GREP_EXE="${OPT_STR_2}" 
            fi
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-10: set grep command to: \"%s\"\n" "${GREP_EXE}"
            fi 
        elif [ "${OPT_STR_1}" = "--fpath" -o "${OPT_STR_1}" = "-fp" ] ; then 
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-11: find starting path=%s\n" "${OPT_STR_1}"
            fi 
            if [ -d "${OPT_STR_2}" ] ; then 
                FIND_PATH="${OPT_STR_2}"
            else
#                printf "\nERROR-1: option --fpath=%s directory \"%s\" does not exist!\n\n" "${OPT_STR_2}" "${OPT_STR_2}"
#                exit 1
                FIND_PATH="${OPT_STR_2}"
            fi 
        elif [ "${OPT_STR_1}" = "--help"  -o  "${OPT_STR_1}" = "-h" ] ; then 
            this_usage
            exit 1
        elif [ "${OPT_STR_1}" = "-d" ] ; then 
            FIND_OPT="-maxdepth ${OPT_STR_2} ${FIND_OPT}"       
#========================================================================================
        elif [ "${OPT_STR_1}" = "-bb" ] ; then 
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_BB}"
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-20: -bb option, change search list to: \'%s\'\n" "${FIND_PATTERN_BB}" 
            fi 
        elif [ "${OPT_STR_1}" = "-mk" ] ; then 
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_MK}"
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-21: -mk option, change search list to: \'%s\'\n" "${FIND_PATTERN}"
            fi 
        elif [ "${OPT_STR_1}" = "-ch" ] ; then 
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_CH}"
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-22: -ch option, change search list to: \'%s\'\n" "${FIND_PATTERN}"
            fi 
        elif [ "${OPT_STR_1}" = "-cch" ] ; then 
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_CCH}"
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-23 -cch option, change search list to: \'%s\'\n" "${FIND_PATTERN}"
            fi 
        elif [ "${OPT_STR_1}" = "-all" ] ; then 
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_ALL}"
            if [ ${b_DEBUG} -ne 0 ] ; then 
                printf "\nINFO-24: -all option, change search list to: \'%s\'\n" "${FIND_PATTERN}"
            fi 
#==============================================================================
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
            N_ARG_SAVED=$((N_ARG_SAVED+1))
        fi
    else
        ARG_SAVED+=("$1")
        N_ARG_SAVED=$((N_ARG_SAVED+1))
    fi
    OPT_CNT=$((OPT_CNT+1))
    shift 1
done

if [ "${ARG_SAVED[0]}" = "" -a  "${FIND_PATTERN}" = "" ] ; then 
    this_usage
    exit 1
fi

#
NEXT_ARG_IDX=0
if [ "${FIND_PATTERN}" = "" ] ; then 
    if [ "${ARG_SAVED[${NEXT_ARG_IDX}]}" = "" ] ; then 
        printf "\nERROR-30: ARG_SAVED[%d] should not be empty here !\n" ${NEXT_ARG_IDX}
        exit 1
    fi 
    FIND_PATTERN="${ARG_SAVED[${NEXT_ARG_IDX}]}" 
    NEXT_ARG_IDX=$((NEXT_ARG_IDX+1))
fi  

if [ ${b_DEBUG} -ne 0 ] ; then 
    LOOP=0
    printf "\n=================== dump saved argument ===========================\n"
    echo -e "DEBUG-1: N_ARGV_SAVED=${N_ARG_SAVED}, entire ARG_SAVED=\"${ARG_SAVED[@]}\"\n"
    while [ ${LOOP} -lt  ${N_ARG_SAVED} ] ; 
    do  
        printf "DEBUG-2: ARG_SAVED[%d]=\"%s\"\n" ${LOOP} "${ARG_SAVED[${LOOP}]}"      
        LOOP=$((LOOP+1))
    done
    printf "====================================================================\n"
    printf "DEBUG-3: FIND_PATTERN=\"%s\"\n\n" "${FIND_PATTERN}"
fi 

#
name_patterns=()
N_NAME_PATTERN=0
if [ "${FIND_PATTERN}" = "*" ] ; then 
    name_patterns+=(-o ${FIND_NAME} '*')
    name_patterns=("${name_patterns[@]:1}")
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\nINFO-30: search all files %s\n" "${FIND_PATTERN}" 
    fi 
    N_NAME_PATTERN=$((N_NAME_PATTERN+1))
else 
    for pattern in ${FIND_PATTERN}
    do
        if [ ${b_DEBUG} -ne 0 ] ; then 
            printf "### INFO-31: search files #%s: \"%s\"\n" "${LOOP}" "$pattern"
        fi 
        name_patterns+=(-o ${FIND_NAME} "${pattern}")
        N_NAME_PATTERN=$((N_NAME_PATTERN+1))
    done
    name_patterns=("${name_patterns[@]:1}")
fi 

# ========================================================================================================================
if [ -z "${ARG_SAVED[${NEXT_ARG_IDX}]}" ] ; then 
#
# no grep texts
#
    if [ ${b_DEBUG} -ne 0 ] ; then 
        printf "\n### DEBUG-no-grep: find, FIND_OPT=\"%s\", GREP_OPT=\"%s\"\n\n" "${FIND_OPT}" "${GREP_OPT}" 
        ${EXE_DIR}/asc reset yellow
        echo -e "\t ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} \( ${name_patterns[@]} \) ${FIND_TAIL_OPT}\n" 
        ${EXE_DIR}/asc reset 
    else
#
# need "\(" so that type is working for all ${FIND_NAME}("-name") not just the first one
#
        if [ ${b_GLOB_restore} -ne 0 ] ; then  
            set +f
        fi 
        ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} \( "${name_patterns[@]}" \) ${FIND_TAIL_OPT}
# if nothing found/matched, return is non-zero 
    fi
else 
#
# with grep texts
#
    while [ ! -z "${ARG_SAVED[${NEXT_ARG_IDX}]}" ] ;
    do
    	GREP_TEXT="${ARG_SAVED[${NEXT_ARG_IDX}]}"
    	if [ ${b_DEBUG} -ne 0 ] ; then 
    		printf "\n### DEBUG4: LOOP:%s: find FIND_OPT=\"%s\", GREP_OPT=\"%s\"\n\n" "${LOOP}" "${FIND_OPT}" "${GREP_OPT}" 
                ${EXE_DIR}/asc reset yellow
    		echo -e "\t ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} \( ${name_patterns[@]} \) ${FIND_TAIL_OPT} -print 0 | ${XARGS_EXE} --null ${XARGS_OPT} ${GREP_EXE} ${GREP_OPT} \"${GREP_TEXT}\"\n\n"  
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
            if [ ${b_GLOB_restore} -ne 0 ] ; then  
                set +f
            fi 
            ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} \( "${name_patterns[@]}" \) ${FIND_TAIL_OPT} -print0 | ${XARGS_EXE} --null ${XARGS_OPT} ${GREP_EXE} ${GREP_OPT} "${GREP_TEXT}"
# if nothing found/matched, return is non-zero 
# continue to next loop even if nothing matched 
    	fi 
       	NEXT_ARG_IDX=$((NEXT_ARG_IDX+1))
    done
fi

