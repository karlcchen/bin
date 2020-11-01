#!/bin/bash
#
# 
NVME_DEV_LIST="`ls /dev/nvme*`"

for d in ${NVME_DEV_LIST}
do 
    echo "read $d:"
    sudo nvme smart-log $d | grep "^temperature"
done 

