#!/bin/bash
#
#   cmake.sh
#
#
THIS_NAME="`basename $0`"
THIS_VERSION="1.0.0"
VER_MSG="${THIS_NAME}, Version ${THIS_VERSION}"

BUILD_DIR="build"
CFLAGS="${CFLAGS} -O3 -Wall -Wextra -Wstrict-prototypes -Wmissing-prototypes -Wshadow -Wconversion -g -lm -lpthread -lgomp -lrt"
CMAKE_C_COMPILER="gcc"
CMAKE_C_FLAGS="${CFLAGS}"
b_RM_BUILD_DIR=0

if [[ -n "${CC}" ]] ; then
    CMAKE_C_COMPILER="${CC}"
fi 

while [[ -n $1 ]] ;
do 
    if [[ $1 == "--new" ]] ; then
        b_RM_BUILD_DIR=1
        shift 1 
    elif [[ $1 == "--version" ]] ; then
        printf '\n=====  %s  =====\n' "${VER_MSG}" 
        exit 0 
    elif [[ $1 == "--help" ]] ; then
        printf '\n=====  %s  =====\n' "${VER_MSG}" 
        printf '\n Usage: %s\n' "${THIS_NAME}"
        exit 0
    else 
        break
    fi
done

if [[ b_RM_BUILD_DIR ]] ; then
    if [[ -d "${BUILD_DIR}" ]]; then 
        printf '#INFO: Removing Buid_DIR \"%s\" ...\n' "${BUILD_DIR}"
        rm -rf ./${BUILD_DIR}/
        if [[ $? -ne 0 ]] ; then
            printf '\nERROR: remove Build_DIR \"%s\" failed!\n' "${BUILD_DIR}"
            exit 1 
        fi
    fi
fi
if [[ -n "${CMAKE_C_FLAGS}" ]] ; then
    printf '#INFO: cmake -B %s -DCMAKE_C_FLAGS=\"%s\"\n' "${BUILD_DIR}" "${CMAKE_C_FLAGS}"
    cmake -S . -B ${BUILD_DIR} -DCMAKE_C_FLAGS="${CMAKE_C_FLAGS}" -DCMAKE_C_COMPILER="${CMAKE_C_COMPILER}"
else
    printf '#INFO: cmake -B %s\n' "${BUILD_DIR}" 
    cmake -S . -B ${BUILD_DIR} -DCMAKE_C_COMPILER="${CMAKE_C_COMPILER}"
fi
if [[ $? -ne 0 ]] ; then
    printf '\nERROR: cmake configuration failed!\n' 
    exit 1 
fi
#cmake -build ${BUILD_DIR}
make -C ${BUILD_DIR}
if [[ $? -ne 0 ]] ; then
    printf '\nERROR: cmake --build %s failed!\n' "${BUILD_DIR}"
    exit 1 
fi
ls -ltr ${BUILD_DIR} | tail
