#!/bin/bash
################################################################################
#
#  Usage:  ./build.sh
#
# Description:  Compiles troposphere templates into Cloudformation JSON.
#               Outputs to `../Cloudformation/*.json`.
#
################################################################################

for filename in ./*.py; do
    echo $filename
done
