#!/bin/bash
echo "=== build single package: $1 ==="
#make MAKE1_PACKAGE=$1 rootfs-pkg1 2>&1 | tee $1.log
make MAKE1_PACKAGE=$1 rootfs-sm-pkg1 2>&1 | tee $1.log
