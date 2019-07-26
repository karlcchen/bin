#!/bin/bash

while [ ! -z "$1" ] ; 
do 
    #make j=${CONCURRENCY_LEVEL} $1 2>&1 | tee $1.log
    make $1 2>&1 | tee $1.log
    shift 1
done
