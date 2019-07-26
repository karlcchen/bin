#!/bin/bash
#
gawk -M '{t+=$1}END{print t}'
