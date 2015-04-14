#!/bin/bash
################################################################################
#
#  Usage:  ./aws_deleteunusedlaunchconfigs.sh [profile-name] [region]
#
# Description:  This script cycles through and attempts to delete all your
#               launch configurations. It will post a failure for configs
#               currently in use.
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_deleteunusedlaunchconfigs.sh [profile-name] [region]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_deleteunusedlaunchconfigs.sh [profile-name] [region]"
  exit
else
  region=$2
fi

# Get a nicely trimmed list of launch configurations.
lconfigs=`aws autoscaling describe-launch-configurations --profile ${profile} --region ${region} | jq -c '.LaunchConfigurations[].LaunchConfigurationName' | tr -d '"' | tr -d ' '`

# For each launch config, try and delete it.
for lconfig in $lconfigs
do

  echo "Attempting to delete launch configuration: ${lconfig}"
  aws autoscaling delete-launch-configuration --launch-configuration-name ${lconfig} --profile ${profile} --region ${region}

done
