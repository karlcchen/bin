#!/bin/bash
#

VERSION="1.5.0"
SAVED_WEST_PROJECT_FILE="saved_west_projects.txt"
BOARD_DIR="./boards"
PWD=`pwd`
BIN_DEST_DIR="./BIN-Firmware"
BUILD_DIR="./build"
BIN_SPEC="bin"
HEX_SPEC="hex"
EXE_SPEC="exe"
ELF_SPEC="elf"

if [[ -z "$1" ]] ; then 
    printf '\nUsage: %s [BOARD_Name] PRJ_PATH\n' "$0" 
    printf 'BOARD examples: stm32h7s78_dk black_f407ve rpi_4b rpi_5\n'
    printf 'PRJ_PATH examples: ./sample/basic/blinky\n\n'
    prinrf 'use \"-b\" as Board Name and \"-p\" as Project Path from (saved) file: \"%s\"\n' "${SAVED_WEST_PROJECT_FILE}"
    exit 1
fi 
if [[ "$1" = "--version" ]] ; then 
    printf '%s Version: %s\n' "$0" "${VERSION}"  
    exit 0 
fi

if [[ -f "${SAVED_WEST_PROJECT_FILE}" ]] ; then 
    printf '# INFO Reading last Board Name and Project Path from file: \"%s\"\n' "${SAVED_WEST_PROJECT_FILE}"
    LAST_BOARD="`cat ${SAVED_WEST_PROJECT_FILE} | tail -n1 | awk '{print $1}'`"
    PIPE_STA="`echo "${PIPESTATUS[@]}"`"
    if [[ "${PIPE_STA}" != "0" ]] ; then
        printf 'ERROR: get last saved Board Name from file \"%s\" failed!\n' "${SAVED_WEST_PROJECT_FILE}"
        exit 9
    fi
    if [[ -z "${LAST_BOARD}" ]] ; then 
        printf 'ERROR: get last Board Name from file \"%s\" got empty string!\n' "${SAVED_WEST_PROJECT_FILE}"
        exit 9
    fi 
    LAST_PRJ_PATH="`cat ${SAVED_WEST_PROJECT_FILE} | tail -n1 | awk '{print $2}'`"
    PIPE_STA="`echo "${PIPESTATUS[@]}"`"
    if [[ "${PIPE_STA}" != "0" ]] ; then
        printf 'ERROR: get last saved Project Path from file \"%s\" failed!\n' "${SAVED_WEST_PROJECT_FILE}"
        exit 9
    fi
    if [[ -z "${LAST_PRJ_PATH}" ]] ; then 
        printf 'ERROR: get last Project Path from file \"%s\" got empty string!\n' "${SAVED_WEST_PROJECT_FILE}"
        exit 9
    fi 
    printf '### INFO: found last Board/Project: %s %s\n' "${LAST_BOARD}" "${LAST_PRJ_PATH}"
else
    LAST_BOARD=""
    LAST_PRJ_PATH=""
fi

if [[ ! -z "${1}" && ! -z "${2}" ]] ; then 
    BOARD="$1"
    PRJ_PATH="$2"
    shift 2
fi 

if [[ -z "${BOARD}" ]] ; then 
    if [[ -z "$1" ]] ; then 
        printf  '\nERROR: no first argument (Board Name) input!\n'   
        exit 1
    else
        BOARD="$1"
        shift 1
    fi  
elif [[ "${BOARD}" == "-b" || "${BOARD}" == "-l" ]] ; then
    if [[ -z "${LAST_BOARD}" ]] ; then 
        printf 'ERROR: Board Name from file \"%s\" got empty string!\n' "${SAVED_WEST_PROJECT_FILE}"
        exit 9
    fi 
    BOARD="${LAST_BOARD}"
    shift 1   
fi

# check board is valid using "west boards"
NAMES_FOUND="`west boards | grep "${BOARD}"`"
PIPE_STA="`echo "${PIPESTATUS[@]}"`"
if [[ "${PIPE_STA}" != "0" ]] ; then
    printf '\nERROR: CMD: west boards | grep \"%s\" failed! status=%s\n' "${BOARD}" "${PIPE_STA}"
    exit 9
fi
N_B_FOUND=`west boards | grep "${BOARD}" | wc -l`
PIPE_STA="`echo "${PIPESTATUS[@]}"`"
if [[ "${PIPE_STA}" != "0" ]] ; then
    printf '\nERROR: search number of boards failed! status=%s\n' "${PIPE_STA}"
    exit 9
fi
if [[ ${N_B_FOUND} -eq 0 ]] ; then 
    printf '\nERROR: search for board: \"%s\" failed! Number of board found=%d\n' "${BOARD}" ${N_B_FOUND}
    exit 9
fi
if [[ ${N_B_FOUND} -ne 1 ]] ; then 
    printf '\nERROR: Multiple Boards found! Number of board found: %d\n' ${N_B_FOUND}
    printf '%s\n' "${NAMES_FOUND}"
    exit 9  
fi
BOARD="${NAMES_FOUND}"
printf '### INFO: Good, Single Board name matched: \"%s\"\n' "${BOARD}"

if [[ -z "${PRJ_PATH}" ]] ; then 
    if [[ -z "$1" ]] ; then
        printf  '\nERROR: no second argument (Project Source Path) input!\n'   
        exit 2 
    else
        PRJ_PATH="$1"
        shift 1
    fi
elif [[ "${PRJ_PATH}" == "-p" || "${PRJ_PATH}" == "-l" ]] ; then 
    if [[ -z "${LAST_PRJ_PATH}" ]] ; then 
        printf 'ERROR: Project Path from file \"%s\" got empty string!\n' "${SAVED_WEST_PROJECT_FILE}"
        exit 9
    fi 
    PRJ_PATH="${LAST_PRJ_PATH}"
    shift 1
fi

if [[ ! -d "${BOARD_DIR}" ]] ; then
    printf  '\nERROR: expected path %s not found in current directory %s\n' "${BOARD_DIR}" "${PWD}"
    exit 3
fi 
#
# find ./boards -type d -name "${BOARD}" >/dev/null
# if [[ $? -ne 0 ]] ; then
#    printf '\nERROR: first argument: %s Board_Name does not exist!\n' "${BOARD}"
#    exit 4 
# fi 
#

if [[ ! -d "${PRJ_PATH}" ]] ; then
    printf  '\nERROR: second argument Project_Source_Path does no exist: %s\n' "${PRJ_PATH}"  
    exit 5
else
    PRJ_PATH_BASENAME="`basename ${PRJ_PATH}`"
    pushd . >> /dev/null
    cd "${PRJ_PATH}/.."
    if [[ $? -ne 0 ]] ; then 
        printf 'cd %s failed!\n' "${PRJ_PATH}/.."
        exit 9
    fi 
    PRJ_PREV_DIR="`basename $(pwd)`"
    popd >> /dev/null
fi 

# save board name and project path to file
if [[ "${LAST_BOARD}" != "${BOARD}" || "${LAST_PRJ_PATH}" != "${PRJ_PATH}" ]] ; then
    printf '%s\t%s\n' "${BOARD}" "${PRJ_PATH}" >> ${SAVED_WEST_PROJECT_FILE}
    if [[ $? -ne 0 ]] ; then 
        printf 'ERROR: saved Board \"%s\", Project \"%s\" to File \"%s\" failed!\n' "${BOARD}" "${PRJ_PATH}" "${SAVED_WEST_PROJECT_FILE}"
        exit 9 
    fi 
    printf '### INFO: "%s\t%s" saved to file: %s\n' "${BOARD}" "${PRJ_PATH}" "${SAVED_WEST_PROJECT_FILE}"
fi

TMP_LOG=".tmp-${PRJ_PREV_DIR}-${PRJ_PATH_BASENAME}.log"
if [ -e "${TMP_LOG}" ] ; then 
    printf '### INFO: Removing Project Build Log File: %s\n' "${TMP_LOG}"
    rm ${TMP_LOG}  
fi
DATE_STR=`date`
printf '\nDATE: %s\n\n' "${DATE_STR}" >> ${TMP_LOG}

if [[ -n "$1" && "$1" == "--new" ]] ; then 
    printf '\n### INFO: REMOVE BUILD DIR: %s\n' "${BUILD_DIR}"
    rm -rf ${BUILD_DIR}
    if [[ $? -ne 0 ]] ; then 
        printf '\nERROR: rm -rf %s failed!\n' "${BUILD_DIR}"
        exit 9
    fi 
    shift 1
fi

if [[ ! -z "$1" ]] ; then 
    printf '\n### INFO: west extra argument 1=%s, 2=%s, 3=%s\n' "$1" "$2" "$3"
fi
west build -p always -b ${BOARD} ${PRJ_PATH} $1 $2 $3 | tee ${TMP_LOG}
PIPE_STA="`echo "${PIPESTATUS[@]}"`"
if [[ "${PIPE_STA}" != "0 0" ]] ; then
    printf '\nERROR: west failed status: %s\n' "${PIPE_STA}"
    mv ${TMP_LOG} ${TMP_LOG}.ERR
    exit 6 
fi 

printf '\nINFO: build completed, find Binary Output %s under PATH %s\n' "${BUILD_DIR}" "*.${BIN_SPEC}"
BIN_FILE=`find ${BUILD_DIR} -type f -name "*.${BIN_SPEC}"`
HEX_FILE=`find ${BUILD_DIR} -type f -name "*.${HEX_SPEC}"`
if [[ $? -ne 0 ]] ; then
    printf '\nERROR: find Binary File (%s) failed!\n' "*.${BIN_SPEC}"
    exit 7 
fi 
if [[ ! -z "${BIN_FILE}" ]] ; then
	printf '\n#####  build complete, %s file found: %s\n' "*.${BIN_SPEC}" "${BIN_FILE}"
        BIN_FILE=`realpath ${BIN_FILE}`
        SAVED_BIN_FILE="zephyr-${BOARD}-${PRJ_PREV_DIR}_${PRJ_PATH_BASENAME}.${BIN_SPEC}"
        SAVED_HEX_FILE="zephyr-${BOARD}-${PRJ_PREV_DIR}_${PRJ_PATH_BASENAME}.${HEX_SPEC}"
        cp ${BIN_FILE} ${BIN_DEST_DIR}/${SAVED_BIN_FILE}
        if [[ $? -ne 0 ]] ; then
            printf '\nERROR: cp binaey file %s to Dir %s failed!\n' "${SAVED_BIN_FILE}" "${BIN_DEST_DIR}}"
            exit 8 
        fi 
        cp ${HEX_FILE} ${BIN_DEST_DIR}/${SAVED_HEX_FILE}
        if [[ $? -ne 0 ]] ; then
            printf '\nERROR: cp binaey file %s to Dir %s failed!\n' "${SAVED_HEX_FILE}" "${BIN_DEST_DIR}}"
            exit 8 
        fi 
        ls -l "${BIN_FILE}"
        SAVED_BIN_FILE_FULLPATH=`realpath ${BIN_DEST_DIR}/${SAVED_BIN_FILE}`
        printf '\n### Binary Saved: %s\n' "${SAVED_BIN_FILE_FULLPATH}"
        SAVED_HEX_FILE_FULLPATH=`realpath ${BIN_DEST_DIR}/${SAVED_HEX_FILE}`
        printf '\n### Hex Saved: %s\n' "${SAVED_HEX_FILE_FULLPATH}"
else
	printf '\n =====   WARNING: No .bin file found!   =====\n'
        EXE_FILE=`find ${BUILD_DIR} -type f -name "*.${EXE_SPEC}"`
        if [[ $? -ne 0 ]] ; then
            printf '\nERROR: find Executable file %s failed!\n' "*.${EXE_SPEC}"
            exit 9 
        fi 
        if [[ ! -z "${EXE_FILE}" ]] ; then
            printf '\n#####  INFO: %s file found: %s\n' "*.${EXE_SPEC}" "${EXE_FILE}"
	    ls -l "${EXE_FILE}"
        fi
fi
