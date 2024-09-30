#!/bin/bash
#
# fx - find and grep
#
#
# 4/11/2022: add option: "-t=x"
#            change "--gexe|-ge=xxxx" to "--egrep[=xxxx]"
#
# 4/11/2022: fix problem of command: fx '.'
#            it should behave the same as fx '*'
# 4/12/2022: make it easier to remeber, more consistent to find/grep
#            change --ftype     to --type
#            change --fpath/-pf to --path/p
#            change --fhead     to --fopt0/-f0
#            change --ftail/-ft to --fopt2/-f2
#
# for debug, following output debug to file fx_debug_output.txt
#exec 5> fx_debug_output.txt
#BASH_XTRACEFD="5"
#PS4='$LINENO: '
#set -x
#

s_VERSION="1.7.1"
EXE_NAME="`realpath $0`"
EXE_BASE="`basename ${EXE_NAME}`"
EXE_DIR="`dirname ${EXE_NAME}`"

#EGREP_EXE="egrep"
#FGREP_EXE="fgrep"
EGREP_EXE="grep -E"
FGREP_EXE="grep -F"
# Note: fgrep doesn't not take "-E" for pattern "XXX|YYY"
GREP_EXE="grep"
# -E use Extended regular expression
#GREP_OPT="${GREP_OPT} -E"
FIND_EXE="find"
#FIND_OPT="${FIND_OPT}"

XARGS_EXE="xargs"

# disable the glob (noglob)
# otherwise search argumnet of '*.sh' will be processed by shell
b_GLOB_ON=1
b_GLOB_restore=1
#
b_VERBOSE=0
b_DEBUG=0
b_find_exclude_git=1
FIND_EXCLUDE_DIRS="-not -path '*/.git*'"
#FIND_EXCLUDE_DIRS=""

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
FIND_TYPE_LIST="f l d b c p s D x"
# default main option of find, must appeared before the first search path
# default is "-P", other options are : -L -H -Olevel
FIND_HEAD_OPT=""
FIND_HEAD_OPT_LIST="-H -L -P"
FIND_TEST_NOT=""

#FIND_TAIL_OPT="-prune"
FIND_TAIL_OPT=""

XARGS_OPT=""

# predefined wildcards for find -name patterns
FIND_PATTERN_BB='*.bb *.bbappend *.inc *.bbclass *.conf'
FIND_PATTERN_MK='make* *Make* *.mk *.mak GNUmake*'
FIND_PATTERN_CH="*.c *.h *.S"
#FIND_PATTERN_CH="*.c *.h"
FIND_PATTERN_CCH="${FIND_PATTERN_CH} *.cc *.cpp *.cxx *.hpp"
FIND_PATTERN_ALL='*'

function this_usage() {
    ${EXE_DIR}/asc reset green
    printf '\n find \"filename patterns\" with \"content text patterns\", default search path beginning is current directory. Version:%s\n' "${s_VERSION}"
    printf " Usage: %s filename_patterns [file_content_patterns]\n" "${EXE_BASE}"
#
# options: begin ==========================================================
#
    ${EXE_DIR}/asc green
    printf " Options:\n"
    printf " Predefind \"%s\" \"%s\" search patterns:\n" "${FIND_EXE}" "${FIND_NAME}"
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
#
# Note: cannot print string begin with "--", it's considered as option for printf
# The -- is used to tell the program that whatever follows should not be interpreted as a command line option to printf.
#  --fopt, -f, 
    ${EXE_DIR}/asc yellow
    printf ' --fopt|-f=[-maxdepth 2] ' 
    ${EXE_DIR}/asc green
    printf 'append option \"%s\" to %s, used when calling find, default --fopt=' "-maxdepth 2" "${FIND_EXE}"
    ${EXE_DIR}/asc yellow
    printf '\"%s\"\n' "${FIND_OPT}"
# --fopt0, -f0 
    ${EXE_DIR}/asc yellow
    printf ' --fopt0|-f0=%s' '-L'
    ${EXE_DIR}/asc green
    printf ' set \"%s\" (first/head) option to %s, the first option of the command\n' "${FIND_EXE}" "-L"
    printf '\t\t Valid optioins are: '
    ${EXE_DIR}/asc yellow
    printf '%s,' "${FIND_HEAD_OPT_LIST}"
    ${EXE_DIR}/asc green
    printf ' default --fopt0=' 
    ${EXE_DIR}/asc yellow
    printf '\"%s\"\n' "${FIND_HEAD_OPT}"
    ${EXE_DIR}/asc green
# --fopt2, -f2
    ${EXE_DIR}/asc yellow
    printf ' --fopt2|-f2=[%s]' '-prune'
    ${EXE_DIR}/asc green
    printf ' set \"%s\" (tail/last) option to %s, deafult -f2=' "${FIND_EXE}" '-prune'
    ${EXE_DIR}/asc yellow
    printf '\"%s\"\n' "${FIND_TAIL_OPT}"
    ${EXE_DIR}/asc green
# --type, -t
    ${EXE_DIR}/asc yellow
    printf ' --type|-t=l[,d] '
    ${EXE_DIR}/asc green
    printf ' set NEW find file type to \"-type l\", and optionally \"-type d\" as well\n'
    printf '\t\t default searches type is \"%s\"\n' "${FIND_TYPE}"
    printf '\t\t Valid find types are: '
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
#              x      is the same as "-type-f -executable"
#
    printf '%s' "${FIND_TYPE_LIST}"
    ${EXE_DIR}/asc green
    printf ', Note: use '
    ${EXE_DIR}/asc yellow
    printf '\"%s\"' ","
    ${EXE_DIR}/asc green
    printf ' to separate multiple options\n' "${FIND_TYPE_LIST}"
# --path, -p
    ${EXE_DIR}/asc yellow
    printf ' --path|-p=XXX'
    ${EXE_DIR}/asc green
    printf ' find path starting at directory XXX\n'
# --fname
    ${EXE_DIR}/asc yellow
    printf ' --fname=-iname '
    ${EXE_DIR}/asc green
    printf ' change find test case from default \"%s\" to \"%s\"\n' "${FIND_NAME}"  "-iname"
    printf '\t\t Valid find (test) name are: '
    ${EXE_DIR}/asc yellow
    printf '%s\n' "${FIND_NAME_LIST}"
    ${EXE_DIR}/asc green
# --findall, -a
    ${EXE_DIR}/asc yellow
    printf ' --findall|-a'
    ${EXE_DIR}/asc green
    printf ' do not exclude path ".git* directories", find (all) without restriction\n' 
    printf '\t\t default is: '
    ${EXE_DIR}/asc yellow
    printf '%s\n' "${FIND_EXCLUDE_DIRS}"
    ${EXE_DIR}/asc green
# --gopt, -g
    ${EXE_DIR}/asc yellow
    printf ' --gopt|-g=-w ' 
    ${EXE_DIR}/asc green
    printf 'append option \"-w", default --gopt=' 
    ${EXE_DIR}/asc yellow
    printf '\"%s\"\n' "${GREP_OPT}"
    ${EXE_DIR}/asc green
# --newgopt, -ng, quick way to set complete new GREP_OPT
    ${EXE_DIR}/asc yellow
    printf ' --newgopt|-ng=%s' "-Hw --color=auto"
    ${EXE_DIR}/asc green
    printf '%s set --newgopt=\"%s"\n' ' -->' "-Hw --color=auto"
# --not, -n, invert find name matching
    ${EXE_DIR}/asc yellow
    printf ' --not|-n=' 
    ${EXE_DIR}/asc green
    printf 'invert find name searching, Noted: not for grep\n'
# --egrep
    ${EXE_DIR}/asc yellow
    printf ' --egrep[=xxx] ' 
    ${EXE_DIR}/asc green
    printf 'change default \"%s\" command to default %s OR to \"%s\"\n' "${GREP_EXE}" "${EGREP_EXE}" "xxx"
# --optend
    ${EXE_DIR}/asc yellow
    printf " --optend " 
    ${EXE_DIR}/asc green
    printf 'indicate end of all options parsing, treat arguments followed as non-options arguments\n' 
# --depth,-d
    ${EXE_DIR}/asc yellow
    printf ' --depth|-d=n|-dn '
    ${EXE_DIR}/asc green
    printf 'find -maxdepth n, default n=1, Same as long option: ' 
    ${EXE_DIR}/asc cyan
    printf ' \"-f=-maxdepth n\"\n'
# -s
    ${EXE_DIR}/asc yellow
    printf ' -s=n|-sn '
    ${EXE_DIR}/asc green
    printf 'print n number of line(s) surrounding grep context, default n=1, Same as long option: '
    ${EXE_DIR}/asc cyan
    printf ' \"-g=-An -Bn\"\n'
#
    ${EXE_DIR}/asc green
    printf ' Example 1: '
    ${EXE_DIR}/asc yellow
    printf ' %s \"%s\" \"%s\" \n' "${EXE_BASE}" '*.c *.h' "Hello"
#
    ${EXE_DIR}/asc green
    printf ' Example 2: only list files, if no search text specified\n'
    ${EXE_DIR}/asc yellow
    printf '\t %s \"%s\" \n' "${EXE_BASE}" '*.c *.h'
    printf '\t %s %s \n'     "${EXE_BASE}" '-bb'
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green
    printf ' Example 3: search multiple patterns, starting from directory : ../\n'
    ${EXE_DIR}/asc yellow
    printf '\t %s %s \"%s\" \"%s\" \"%s\"\n' "${EXE_BASE}" '-fp=../' '*.c *.h' "Hello" "World"
    ${EXE_DIR}/asc green
    printf '\t OR, same as last example, but run \"find\" only once for both patterns, using regular expression, grep option -E\n'
    ${EXE_DIR}/asc yellow
    printf '\t %s %s \"%s\" \"%s\" \"%s\"\n' "${EXE_BASE}" '-fp=../' '--gopt=-E' '*.c *.h' "Hello|World"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green
    printf ' Example 4: append grep option -w, search \"word\" only:\n'
    ${EXE_DIR}/asc yellow
    printf '\t %s %s %s \"%s\"\n' "${EXE_BASE}" '-bb' '-g=-w' "DEVICETREE"
    ${EXE_DIR}/asc green
    printf ' Example 4a: set grep option=\"\", which is empty\n'
    ${EXE_DIR}/asc yellow
    printf '\t %s %s %s \"%s\"\n' "${EXE_BASE}" '-g' '-bb' "DEVICETREE"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc green
    printf ' Example 5: use find option: \"-maxepth 2\":\n'
    ${EXE_DIR}/asc yellow
    printf '\t %s %s %s \"%s\"\n' "${EXE_BASE}" "--fopt=-maxdepth 2" "-bb" "DEVICETREE"
    ${EXE_DIR}/asc green
    printf '\t OR, use '-d2', a short form of "-maxdepth 2"\n'
    ${EXE_DIR}/asc yellow
    printf '\t %s %s %s \"%s\"\n\n' "${EXE_BASE}" "-d2" "-bb" "DEVICETREE"
    ${EXE_DIR}/asc green
#
    ${EXE_DIR}/asc reset
}

if [[ ${b_GLOB_ON} -ne 0 ]] ; then
#
# disable "*","?", wildcard expansion in shell
#
    set -f
    if [[ $? -ne 0 ]] ; then
        printf '\nERROR-01A: \"set -f\" failed!\n'
        exit 1
    fi
fi

ARG_SAVED=()
N_ARG_SAVED=0
FIND_PATTERN=""
OPT_CNT=1
while [[ ! -z "$1" ]]
do
    if [[ ${b_DEBUG} -ne 0 ]] ; then
        printf "\nDEBUG1: input option #%d = \"%s\"\n" ${OPT_CNT} "$1"
    fi
# use "echo" failed if "$1" equals echo's options such as: "-n", etc...
#    echo "$1" | grep '^--' >/dev/null
    printf '%s\n' "$1" | grep '^-' >/dev/null
    if [[ $? -eq 0 ]] ; then
        # removed trailing spaces of OPT_STR_2
        OPT_STR_1=`printf '%s\n' "$1" | sed 's/=/ /1' | awk '{print $1}' | sed -e 's/[[:space:]]*$//'`
        OPT_STR_2=""
        printf '%s\n' "$1" | grep '=' >/dev/null
        if [[ $? -eq 0 ]] ; then
            OPT_STR_2=`printf '%s\n' "$1" | sed 's/=/ /1' | awk '{print $2 " " $3}' | sed -e 's/[[:space:]]*$//'`
        else
            printf '%s\n' "$1" | grep "[[:digit:]]" >/dev/null
            if [[ $? -eq 0 ]] ; then
                OPT_STR_1=`printf '%s\n' "$1" | sed 's/[[:digit:]]/ /1' | awk '{print $1}' | sed -e 's/[[:space:]]*$//'`
                OPT_STR_2=`printf '%s\n' "$1" | sed 's/[^0-9]*//g'`
            fi
        fi
        if [[ ${b_DEBUG} -ne 0 ]] ; then
            printf "\nDEBUG-1: the #%d options parsed: #1=\"%s\", #2=\"%s\"\n" ${OPT_CNT} "${OPT_STR_1}" "${OPT_STR_2}"
        fi
        if [[ "${OPT_STR_1}" == "--verbose" ]] ; then
# --verbose
            if [[ -z "${OPT_STR_2}" ]] ; then
        	b_VERBOSE=1
            else
                b_VERBOSE=${OPT_STR_2}
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-1: set --verbose=%d, --debug=%d\n" ${b_VERBOSE} ${b_DEBUG}
            fi
        elif [[ "${OPT_STR_1}" == "--debug" ]] ; then
# --debug
            if [[ -z "${OPT_STR_2}" ]] ; then
        	b_DEBUG=1
            else
                b_DEBUG=${OPT_STR_2}
            fi
            b_VERBOSE=1
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-2: set --debug=%d, verbose=%d\n" ${b_DEBUG} ${b_VERBOSE}
            fi
# --help, -h
        elif [[ "${OPT_STR_1}" == "--help"  ||  "${OPT_STR_1}" == "-h" ]] ; then
            this_usage
            exit 1
        elif [[ "${OPT_STR_1}" == "--findall" || "${OPT_STR_1}" == "-a" ]] ; then
#
# --findsall, -a
# do not exclude some directories,  ignore the ${FIND_EXCLUDE_DIRS}
#
            b_find_exclude_git=0
        elif [[ "${OPT_STR_1}" == "--glob" ]] ; then
#
# --glob[=yes,no, test]: control globbing behavior
# to work with checking of "first arugment" (the filename patterns) that may has wildcards,
# we need to do follwoing steps:
#   1. disable globbing in the beginning, for checking and comparing with wildcards(*,?) functions to wrork properly
#   2  restore globbing finally, just before exec "find" command
#
            if [[ -z "${OPT_STR_2}" ]] ; then
            #
            # --glob with no assignment, the same as --glob=no
            # DON'T disable Globbing in the begining, thus also no need to restore
            #
                b_GLOB_ON=0
        	b_GLOB_restore=0
            elif [[ "${OPT_STR_2}" =~ "[Yy]$" ]] ; then
            #
            # --glob=yes
            # this is the default behavior
            #
                b_GLOB_ON=1
              	b_GLOB_restore=1
            elif [[ "${OPT_STR_2}" =~ "[Nn]$" ]] ; then
            #
            # --glob=no
            # DON'T disable Globbing, thus also no need to restore
            #
                b_GLOB_ON=0
              	b_GLOB_restore=0
            elif [[ "${OPT_STR_2}" =~ "[Tt]$" ]] ; then
            #
            # --glob=test
            # for Test only: Disable globbing in the beginning as usually, but DON'T restore globbing, before exec "find"
            #
                b_GLOB_ON=1
              	b_GLOB_restore=0
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-3: --glob=%s\n" "${b_GLOB_restore}"
            fi
# --fopt, -f
        elif [[ "${OPT_STR_1}" == "--fopt" || "${OPT_STR_1}" == "-f" ]] ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
                if [[ ${b_DEBUG} -ne 0 ]] ; then
                    printf "\nWARN-2: --fopt=\"\", find options changed from \"%s\" to empty\n" "${FIND_OPT}"
                fi
                FIND_OPT=""
            else
                FIND_OPT="${FIND_OPT} ${OPT_STR_2}"
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-8: set find options changed to: \"%s\"\n" "${FIND_OPT}"
            fi
# --type, -t
        elif [[ "${OPT_STR_1}" == "--type" ||  "${OPT_STR_1}" == "-t" ]] ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
                if [[ ${b_DEBUG} -ne 0 ]] ; then
                    printf "\nWARN-1: --type=\"\", find file type changed from \"%s\" to empty\n" "${FIND_TYPE}"
                fi
                FIND_TYPE=""
            else
                if [[ "${OPT_STR_2}" == "x" ]]; then
                    FIND_TYPE="${FIND_TYPE} -executable"
                else
                    FIND_TYPE="-type ${OPT_STR_2}"
                fi
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-4: find type changed to: \"%s\"\n" "${FIND_TYPE}"
            fi
# --fopt0, -f0
        elif [[ "${OPT_STR_1}" == "--fopt0" || "${OPT_STR_1}" == "-f0" ]] ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
                if [[ ${b_DEBUG} -ne 0 ]] ; then
                    printf "\nWARN-2: --fopt0=\"\", \"%s\" (head) OPTIONS changed from \"%s\" to empty\n" "${FIND_EXE}" "${FIND_HEAD_OPT}"
                fi
                FIND_HEAD_OPT=""
            else
                FIND_HEAD_OPT="${FIND_HEAD_OPT} ${OPT_STR_2}"
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-5: set \"%s\" (head) OPTIONS changed to: \"%s\"\n" "${FIND_EXE}" "${FIND_HEAD_OPT}"
            fi
# --fopt2, -f2
        elif [[ "${OPT_STR_1}" == "--fopt2" || "${OPT_STR_1}" == "-f2" ]] ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
                if [[ ${b_DEBUG} -ne 0 ]] ; then
                    printf "\nWARN-2: --fopt2=\"\", \"%s\" (head) OPTIONS changed from \"%s\" to empty\n" "${FIND_EXE}" "${FIND_TAIL_OPT}"
                fi
                FIND_TAIL_OPT=""
            else
                FIND_TAIL_OPT="${FIND_TAIL_OPT} ${OPT_STR_2}"
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-6: set \"%s\" (tail) OPTIONS changed to: \"%s\"\n" "${FIND_EXE}" "${FIND_TAIL_OPT}"
            fi
# --fname=-iname,-lname,-ilname
        elif [[ "${OPT_STR_1}" == "--fname" ]] ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
                printf '\nERROR-1: option %s cannot be empty!\n' "${OPT_STR_1}"
                exit 1
            fi
            FIND_NAME="${OPT_STR_2}"
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-7a: option %s: set find TEST name to: \"%s\"\n" "${OPT_STR_1}" "${FIND_NAME}"
            fi
# --ignorecase, -i
        elif [[ "${OPT_STR_1}" == "--ignorecase" || "${OPT_STR_1}" == "-i" ]] ; then
            if [[ ! -z "${OPT_STR_2}" ]] ; then
                printf '\nWARN-3: option %s does not take any value!\n' "${OPT_STR_1}"
            fi
            FIND_NAME="-iname"
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-7b: option %s: set find TEST name to: \"%s\"\n" "${OPT_STR_1}" "${FIND_NAME}"
            fi
# --not, -n:
        elif [[ "${OPT_STR_1}" == "--not" || "${OPT_STR_1}" == "-n" ]] ; then
            if [[ ! -z "${OPT_STR_2}" ]] ; then
                printf '\nERROR-OPT: "--not" takes no argument!\n'
            else
                FIND_TEST_NOT="-not"
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf '\nINFO-7c: option %s, invert match\n' "${FIND_TEST_NOT}"
            fi
# --path, -p
        elif [[ "${OPT_STR_1}" == "--path" || "${OPT_STR_1}" == "-p" ]] ; then
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-11: find starting path=%s\n" "${OPT_STR_1}"
            fi
            if [[ -d "${OPT_STR_2}" ]] ; then
                FIND_PATH="${OPT_STR_2}"
            else
#                printf "\nERROR-1: option --path=%s directory \"%s\" does not exist!\n\n" "${OPT_STR_2}" "${OPT_STR_2}"
#                exit 1
                FIND_PATH="${OPT_STR_2}"
            fi
# --gopt, -g
        elif [[ "${OPT_STR_1}" == "--gopt" || "${OPT_STR_1}" == "-g" ]] ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
                if [[ ${b_DEBUG} -ne 0 ]] ; then
                    printf "\nWARN-3: --gopt=\"\", grep options changed from \"%s\" to empty\n" "${GREP_OPT}"
                fi
                GREP_OPT=""
            else
                GREP_OPT="${GREP_OPT} ${OPT_STR_2}"
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-9: grep options changed to: \"%s\"\n" "${GREP_OPT}"
            fi
# --newgopt, -ng
        elif [[ "${OPT_STR_1}" == "--newgopt" || "${OPT_STR_1}" == "-ng" ]] ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
                if [[ ${b_DEBUG} -ne 0 ]] ; then
                    printf "\nWARN-3: --newgopt=\"\", grep NEW options changed from \"%s\" to empty\n" "${GREP_OPT}"
                fi
                GREP_OPT=""
            else
                GREP_OPT="${OPT_STR_2}"
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-9: grep options changed to: \"%s\"\n" "${GREP_OPT}"
            fi
# --egrep
        elif [[ "${OPT_STR_1}" == "--egrep" ]] ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
            # default to using "${EGREP_EXE}" command
                GREP_EXE="${EGREP_EXE}"
            else
            # user assigned grep command
                GREP_EXE="${OPT_STR_2}"
            fi
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-10: --egrep=\"%s\"\n" "${GREP_EXE}"
            fi
# --depth -d[=n] -dn
# set search depth

        elif [[ "${OPT_STR_1}" == "-d" || "${OPT_STR_1}" == "--depth" ]]  ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
# default to 1 if number not specified
                OPT_STR_2="1"
            fi
            FIND_OPT="-maxdepth ${OPT_STR_2} ${FIND_OPT}"
# -s[=n]
# print adjcent lines of grep, which is grep option "-A" and "-B"
#
        elif [[ "${OPT_STR_1}" == "-s" ]] ; then
            if [[ -z "${OPT_STR_2}" ]] ; then
# default to -A=1,-B=1 if number not specified
                OPT_STR_2="1"
            fi
            GREP_OPT="-A${OPT_STR_2} -B${OPT_STR_2} ${GREP_OPT}"
#========================================================================================
        elif [[ "${OPT_STR_1}" == "-bb" ]] ; then
# -bb
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_BB}"
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-20: -bb option, change search list to: \'%s\'\n" "${FIND_PATTERN_BB}"
            fi
        elif [[ "${OPT_STR_1}" == "-mk" ]] ; then
# -mk
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_MK}"
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-21: -mk option, change search list to: \'%s\'\n" "${FIND_PATTERN}"
            fi
        elif [[ "${OPT_STR_1}" == "-ch" ]] ; then
# -ch
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_CH}"
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-22: -ch option, change search list to: \'%s\'\n" "${FIND_PATTERN}"
            fi
        elif [[ "${OPT_STR_1}" == "-cch" ]] ; then
# -cch
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_CCH}"
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-23 -cch option, change search list to: \'%s\'\n" "${FIND_PATTERN}"
            fi
        elif [[ "${OPT_STR_1}" == "-all" ]] ; then
# -all
            FIND_PATTERN="${FIND_PATTERN} ${FIND_PATTERN_ALL}"
            if [[ ${b_DEBUG} -ne 0 ]] ; then
                printf "\nINFO-24: -all option, change search list to: \'%s\'\n" "${FIND_PATTERN}"
            fi
        elif [[ "${OPT_STR_1}" == "--version" ]] ; then
# --version
            printf '%s\t version=%s\n' "$0" "${s_VERSION}"
            exit 0 
            break
#==============================================================================
        elif [[ "${OPT_STR_1}" == "--optend" ]] ; then
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

while [[ ! -z "$1" ]] ;
do
    ARG_SAVED+=("$1")
    N_ARG_SAVED=$((N_ARG_SAVED+1))
    shift 1
done

if [[ "${ARG_SAVED[0]}" == "" &&  "${FIND_PATTERN}" == "" ]] ; then
    this_usage
    exit 1
fi

#
NEXT_ARG_IDX=0
if [[ "${FIND_PATTERN}" == "" ]] ; then
    if [[ "${ARG_SAVED[${NEXT_ARG_IDX}]}" == "" ]] ; then
        printf '\nERROR-30: ARG_SAVED[%d] should not be empty here !\n' ${NEXT_ARG_IDX}
        exit 1
    fi
    FIND_PATTERN="${ARG_SAVED[${NEXT_ARG_IDX}]}"
    NEXT_ARG_IDX=$((NEXT_ARG_IDX+1))
fi

if [[ ${b_DEBUG} -ne 0 ]] ; then
    LOOP=0
    printf '\n=================== dump saved argument ===========================\n'
    printf 'DEBUG-1: N_ARGV_SAVED=%d, entire ARG_SAVED=\"%d"\n' ${N_ARG_SAVED} ${ARG_SAVED[@]}
    while [[ ${LOOP} -lt  ${N_ARG_SAVED} ]]
    do
        printf 'DEBUG-2: ARG_SAVED[%d]=\"%s\"\n' ${LOOP} "${ARG_SAVED[${LOOP}]}"
        LOOP=$((LOOP+1))
    done
    printf '====================================================================\n'
    printf 'DEBUG-3: FIND_PATTERN=\"%s\"\n\n' "${FIND_PATTERN}"
fi

#
name_patterns=()
N_NAME_PATTERN=0
if [[ "${FIND_PATTERN}" == "*" || "${FIND_PATTERN}" == "." ]] ; then
    name_patterns+=(-o ${FIND_NAME} "*")
    name_patterns=("${name_patterns[@]:1}")
    FIND_PATH="${FIND_PATTERN}"
    if [[ ${b_DEBUG} -ne 0 ]] ; then
        printf "\nDEBUG-03a: search ALL files \'%s %s\'\n" "${name_patterns[@]}"
    fi
    N_NAME_PATTERN=$((N_NAME_PATTERN+1))
else
    for pattern in ${FIND_PATTERN}
    do
        if [[ ${b_DEBUG} -ne 0 ]] ; then
            printf "### DEBUG-03b: search files #%s: \"%s\"\n" "${LOOP}" "$pattern"
        fi
        name_patterns+=(-o ${FIND_NAME} "${pattern}")
        N_NAME_PATTERN=$((N_NAME_PATTERN+1))
    done
    name_patterns=("${name_patterns[@]:1}")
fi


if [[ ${b_DEBUG} -ne 0 ]] ; then
    printf 'DEBUG-4: FIND_PATH=\"%s\"\n' "${FIND_PATH}"
fi

if [[ ${b_GLOB_ON} -ne 0 && ${b_GLOB_restore} -ne 0 ]] ; then
#
# restore glob makes using starting path '*' possible
#
    if [[ ${b_DEBUG} -ne 0 ]] ; then
        printf '\nINFO: restore Globbing...\n'
    fi
    set +f
    # without restore globbing, (find *) failed with error:
    #   find: ‘*’: No such file or directory
fi

# ========================================================================================================================
if [[ -z "${ARG_SAVED[${NEXT_ARG_IDX}]}" ]] ; then
#
# no grep texts
#
#
    if [[ ${b_DEBUG} -ne 0 ]] ; then
        printf "\n### DEBUG-no-grep: find, FIND_OPT=\"%s\", GREP_OPT=\"%s\"\n\n" "${FIND_OPT}" "${GREP_OPT}"
        ${EXE_DIR}/asc reset yellow
        if [[ ${b_find_exclude_git} -ne 0 ]] ; then
            echo -e "\t ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} ${FIND_TEST_NOT} \( "${name_patterns[@]}" \) -not -path '*/.git*' ${FIND_TAIL_OPT}\n"
        else
            echo -e "\t ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} ${FIND_TEST_NOT} \( "${name_patterns[@]}" \) ${FIND_TAIL_OPT}\n"
        fi
        ${EXE_DIR}/asc reset
    else
#
# need "\(" so that type is working for all ${FIND_NAME}("-name") not just the first one
#
        if [[ ${b_find_exclude_git} -ne 0 ]] ; then
            ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} ${FIND_TEST_NOT} \( "${name_patterns[@]}" \) -not -path '*/.git*' ${FIND_TAIL_OPT}
        else
            ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} ${FIND_TEST_NOT} \( "${name_patterns[@]}" \) ${FIND_TAIL_OPT}
#        ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} ${FIND_TEST_NOT} \( "${name_patterns[@]}" \) -not -path '*/.git*' ${FIND_TAIL_OPT}
#        find  *  -type f  \( -name index \) -not -path '*/.git*'
# if nothing found/matched, return is non-zero
        fi
    fi
else
#
# with grep texts
#
    while [[ ! -z "${ARG_SAVED[${NEXT_ARG_IDX}]}" ]] ;
    do
    	GREP_TEXT="${ARG_SAVED[${NEXT_ARG_IDX}]}"
    	if [[ ${b_DEBUG} -ne 0 ]] ; then
       	    printf "\n### DEBUG4: LOOP:%s: find FIND_OPT=\"%s\", GREP_OPT=\"%s\"\n\n" "${LOOP}" "${FIND_OPT}" "${GREP_OPT}"
            ${EXE_DIR}/asc reset yellow
            if [[ ${b_find_exclude_git} -ne 0 ]] ; then
                echo -e "\t ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} ${FIND_TEST_NOT} \( "${name_patterns[@]}" \) -not -path '*/.git*' ${FIND_TAIL_OPT} -print0 | ${XARGS_EXE} --null ${XARGS_OPT} ${GREP_EXE} ${GREP_OPT} ${GREP_TEXT}\n\n"
            else
	        echo -e "\t ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} ${FIND_TEST_NOT} \( "${name_patterns[@]}" \) ${FIND_TAIL_OPT} -print 0 | ${XARGS_EXE} --null ${XARGS_OPT} ${GREP_EXE} ${GREP_OPT} \"${GREP_TEXT}\"\n\n"
            fi
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
            if [[ ${b_find_exclude_git} -ne 0 ]] ; then
                ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} ${FIND_TEST_NOT} \( "${name_patterns[@]}" \) -not -path '*/.git*' ${FIND_TAIL_OPT} -print0 | ${XARGS_EXE} --null ${XARGS_OPT} ${GREP_EXE} ${GREP_OPT} "${GREP_TEXT}"
            else
                ${FIND_EXE} ${FIND_HEAD_OPT} ${FIND_PATH} ${FIND_OPT} ${FIND_TYPE} ${FIND_TEST_NOT} \( "${name_patterns[@]}" \) ${FIND_TAIL_OPT} -print0 | ${XARGS_EXE} --null ${XARGS_OPT} ${GREP_EXE} ${GREP_OPT} "${GREP_TEXT}"
            fi
# if nothing found/matched, return is non-zero
# continue to next loop even if nothing matched
    	fi
       	NEXT_ARG_IDX=$((NEXT_ARG_IDX+1))
    done
fi

