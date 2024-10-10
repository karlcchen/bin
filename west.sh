#!/bin/bash
#

THIS_BASENAME="`basename $0`"
VERSION="1.7.1"

SAVED_WEST_PROJECT_FILE="saved_west_projects.txt"
BOARD_DIR="./boards"
PWD=`pwd`
BIN_FIRST_NAME="zephyr"
BIN_DEST_DIR="BIN-Firmware"
BUILD_DIR="build"

#
# hex and elf file is much smaller if address is not contigeous
#BIN_SPEC="bin"
BIN_SPEC="elf"
HEX_SPEC="hex"
EXE_SPEC="exe"

#
#BUILD_MAKER="west"
BUILD_MAKER="cmake"
b_DRY_RUN=0
b_NEW_BUILD=0

if [[ -z "$1" ]] ; then 
    printf '\n===== Shell Script for ZephyrRtos, helper for calling west/cmake, Version: %s =====\n' "${VERSION}"  
    printf '\nUsage: %s [PATH]\[BOARD_Name] PRJ_PATH  [--new]\n\n' "${THIS_BASENAME}" 
    printf 'Example of BOARD: %s %s %s\n' "stm32h7s78_dk" "black_f407ve" "rpi_4b rpi_5"
    printf 'Notes:\n'
    printf '\"-b\" or \"-l\" as (last) Board Name\n' 
    printf '\"-p\" or \"-l\" as (last) Project_Path from (saved) file: \"%s\"\n\n' "${SAVED_WEST_PROJECT_FILE}"
    printf '\n Current Default Build_Maker is: \"%s\"\n' "${BUILD_MAKER}" 
    printf ' --west:  force Build_Maker to \"%s\"\n' "west"
    printf ' --cmake: force Build_Maker to \"%s\"\n' "cmake"
    printf 'Examples:\n'
    printf '\t %s f407ve sample/basic/blinky --new\n' "${THIS_BASENAME}" 
    printf '\t %s stm32h7s78_dk samples/application_development/code_relocation_nocopy/\n' "${THIS_BASENAME}" 
    printf '\t %s s78 -l\n' "${THIS_BASENAME}" 
    printf '\t %s --west -l samples/subsys/portability/cmsis_rtos_v2/philosophers\n' "${THIS_BASENAME}" 
    printf '\t %s --dry s78 samples/subsys/fs/fs_sample %s\n' "${THIS_BASENAME}" "-DCONF_FILE=prj_ext.conf"
    exit 1
fi 
if [[ "$1" = "--version" ]] ; then 
    printf '%s Version: %s\n' "${THIS_BASENAME}" "${VERSION}"  
    exit 0 
fi

if [[ "$1" = "--dry" ]] ; then 
    b_DRY_RUN=1
    shift 1
fi
if [[ "$1" = "--new" ]] ; then 
    b_NEW_BUILD=1
    shift 1
fi
if [[ "$1" = "--west" || "$1" = "--ninja" ]] ; then 
    BUILD_MAKER="west"
    shift 1
fi
if [[ "$1" = "--cmake" ]] ; then 
    BUILD_MAKER="cmake"
    shift 1
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

TMP_LOG=".tmp-${PRJ_PREV_DIR}-${PRJ_PATH_BASENAME}.log"
if [ -e "${TMP_LOG}" ] ; then 
    printf '### INFO: Removing Project Build Log File: %s\n' "${TMP_LOG}"
    rm ${TMP_LOG}  
fi
DATE_STR=`date`
printf '\nDATE: %s\n\n' "${DATE_STR}" >> ${TMP_LOG}

if [[ -n "$1" && "$1" == "--new" ]] ; then 
    b_NEW_BUILD=1
    shift 1
fi
if [[ b_NEW_BUILD -eq 1 ]] ; then
    printf '\n### INFO: REMOVE BUILD DIR: %s\n' "./${BUILD_DIR}/"
    rm -rf ./${BUILD_DIR}/
    if [[ $? -ne 0 ]] ; then 
        printf '\nERROR: rm -rf %s failed!\n' "./${BUILD_DIR}/"
        exit 9
    fi 
fi

if [[ ! -z "$1" ]] ; then 
    printf '### INFO: west extra argument:' 
    echo $@
fi

if [[ -n "$1" && "$1" == "--dry" ]] ; then 
    b_DRY_RUN=1
    shift 1
fi
if [[ b_DRY_RUN -eq 1 ]] ; then
    echo 
    echo "--dry run command:"
    echo " west build -p always -b ${BOARD} ${PRJ_PATH} $@ | tee ${TMP_LOG}"
    echo
    exit 0 
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

if [[ "${BUILD_MAKER}" == "west" ]] ; then 
    ${BUILD_MAKER} build -p always -b ${BOARD} ${PRJ_PATH} $@ | tee ${TMP_LOG}
    PIPE_STA="`echo "${PIPESTATUS[@]}"`"
elif [[ "${BUILD_MAKER}" == "cmake" ]] ; then 
    ${BUILD_MAKER} -B${BUILD_DIR} -DBOARD=${BOARD} ${PRJ_PATH} $@ | tee ${TMP_LOG}
    PIPE_STA="`echo "${PIPESTATUS[@]}"`"
    if [[ "${PIPE_STA}" != "0 0" ]] ; then
        printf '\nERROR: %s failed PIPED Status: %s\n' "${BUILD_MAKER}" "${PIPE_STA}"
        mv ${TMP_LOG} ${TMP_LOG}.ERR
        exit 6 
    fi 
    make -C ${BUILD_DIR} -j | tee -a ${TMP_LOG}
    PIPE_STA="`echo "${PIPESTATUS[@]}"`"
fi
if [[ "${PIPE_STA}" != "0 0" ]] ; then
    printf '\nERROR: %s failed, Piped Status: %s\n' "${BUILD_MAKER}" "${PIPE_STA}"
    mv ${TMP_LOG} ${TMP_LOG}.ERR
    exit 6 
fi 

printf '\n### INFO: Build completed, find Binary File under Dir: \"%s\", Name: \"%s\"\n' "./${BUILD_DIR}" "${BIN_FIRST_NAME}.${BIN_SPEC}"
HEX_FILE=`find ./${BUILD_DIR} -type f -name "${BIN_FIRST_NAME}.${HEX_SPEC}"`
if [[ $? -ne 0 ]] ; then
    printf '\nERROR: No Binary File (%s) generated!\n' "${BIN_FIRST_NAME}.${HEX_SPEC}"
    exit 7 
fi 
BIN_FILE=`find ./${BUILD_DIR} -type f -name "${BIN_FIRST_NAME}.${BIN_SPEC}"`
if [[ $? -ne 0 ]] ; then
    printf '\nERROR: No Binary File \"%s\" generated!\n' "${BIN_FIRST_NAME}.${BIN_SPEC}"
    exit 7 
fi 
if [[ ! -z "${BIN_FILE}" ]] ; then
	printf '\n#####  build complete, %s file found: %s\n' "*.${BIN_SPEC}" "${BIN_FILE}"
        BIN_FILE="`realpath ${BIN_FILE}`"
        SAVED_BIN_FILE="zephyr-${BOARD}-${PRJ_PREV_DIR}_${PRJ_PATH_BASENAME}.${BIN_SPEC}"
        SAVED_HEX_FILE="zephyr-${BOARD}-${PRJ_PREV_DIR}_${PRJ_PATH_BASENAME}.${HEX_SPEC}"
        cp ${BIN_FILE} ./${BIN_DEST_DIR}/${SAVED_BIN_FILE}
        if [[ $? -ne 0 ]] ; then
            printf '\nERROR: cp binaey file %s to Dir %s failed!\n' "${SAVED_BIN_FILE}" "./${BIN_DEST_DIR}"
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
        EXE_FILE=`find ./${BUILD_DIR} -type f -name "*.${EXE_SPEC}"`
        if [[ $? -ne 0 ]] ; then
            printf '\nERROR: find Executable file %s failed!\n' "*.${EXE_SPEC}"
            exit 9 
        fi 
        if [[ ! -z "${EXE_FILE}" ]] ; then
            printf '\n#####  INFO: %s file found: %s\n' "*.${EXE_SPEC}" "${EXE_FILE}"
	    ls -l "${EXE_FILE}"
        fi
fi
