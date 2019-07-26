#!/bin/bash
#
# Remove all SysV message queues
#
# Author:  Mark F. Haigh, 6/24/10
#          <mfhaigh@anacaz.com>
#

name=`basename "$0"`

usage() {
    cat <<EOF

Usage: $name [OPTIONS]

    A script to remove all SysV message queues on a system.  This can
    be used to clean up after programs that leak message queues, which
    are not automatically freed on process termination.

    Options:
        -h, --help              Output usage information (this text).
        -v, --verbose           Output extra informational messages.
        -q, --quiet             Don't prompt user or output extra info.

    The exit status is 0 if no errors are encountered.  The exit status
    is 1 if an error occurred or if the --help option was used.

EOF
    exit 1
}


# Print a message and exit.  1st argument: the string to print.  2nd
# argument: nonzero if "  Use -h for help" should be appended to the
# 1st argument before printing.  3rd argument:  the value to pass to
# exit.  The 2nd and 3rd arguments are optional and default to 0 and
# 1 respectively.

error() {
    local arg2="$2"
    local arg3="$3"
    [ -z "$2" ] && arg2="0"             # default
    [ -z "$3" ] && arg3="1"             # default

    local what="error"
    if [ "$arg3" -eq 0 ]; then
        what="warning"
    fi

    local msg="$1"
    if [ "$arg2" -ne 0 ]; then
        msg="$msg  Use -h for help."
    fi

    echo "$name $what: $msg" 1>&2
    exit $arg3
}


warn_user() {
    echo -e "\n*** Warning!  This will remove all message queues. ***"
    echo -ne "    Are you sure you want to do this? (yes/no): "
    read response
    if [ "$response" != "yes" ]; then
        echo ""
        error "Terminated by user." 1 0
    fi
}



                          # Script Start #


# Check for a functioning host environment.  In particular, we need
# an enhanced getopt(1) command and to be running on Linux.

if `getopt -T > /dev/null 2>&1` ; [ $? != 4 ] ; then
    error "Unenhanced or missing getopt(1) command."
fi
if [ "`uname 2> /dev/null`" != "Linux" ]; then
    error "This script can only be run under Linux."
fi


# Parse the command line.

quiet="0"
verbose="0"

temp=`getopt -o hqv --long help,quiet,verbose -n "$name error" -- "$@"`
[ $? != 0 ] && exit 1
eval set -- "$temp"

while true; do
    case "$1" in
        -h|--help)      usage;;
        -q|--quiet)     quiet="1"; shift;;
        -v|--verbose)   verbose="1"; shift;;
        --)             shift; break;;
        *)              error "Internal error 1.";;
    esac
done

[ $# -ne 0 ] && error "Too many arguments." 1


# If we're not in quiet mode, we warn the user and print list of the
# message queues before and after.  If we're in verbose mode, don't
# silence ipcrm output.

if [ "$quiet" = 0 ]; then
    echo -e "\nListing of message queues before:"
    ipcs -q | sed 's/^/    /1'
    warn_user
fi

for msqid in `ipcs -q | tail -n+4 | cut -f 2 -d ' '`; do
    if [ "$verbose" = 0 ]; then
        ipcrm -q $msqid > /dev/null 2>&1
    else
        ipcrm -q $msqid
    fi
done

if [ "$quiet" = 0 ]; then
    echo -e "\nListing of message queues after:"
    ipcs -q | sed 's/^/    /1'
fi

# Success
exit 0

