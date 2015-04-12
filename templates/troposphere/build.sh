#!/bin/bash
################################################################################
#
#  Usage:  ./build.sh
#
# Description:  Compiles troposphere templates into Cloudformation JSON.
#               Outputs to `../cloudformation/*.json`.
#
################################################################################

echo "Converting templates to JSON:"

for filename in ./*.py; do
    echo " -- Processing ${filename}, outputing to ../cloudformation/`echo $filename | tr -d './' | sed 's/..$//'`.json"
    $filename > ../cloudformation/`echo $filename | tr -d './' | sed 's/..$//'`.json
done

echo "Conversions complete!"