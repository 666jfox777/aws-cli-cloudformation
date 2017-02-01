#!/bin/bash
################################################################################
#
#  Usage:  ./aws_deleteunusedautoscalinggroups.sh [profile-name] [region]
#
# Description:  This script cycles through and attempts to delete all your
#               auto scaling groups. It will post a failure for groups
#               currently in use.
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_deleteunusedautoscalinggroups.sh [profile-name] [region]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_deleteunusedautoscalinggroups.sh [profile-name] [region]"
  exit
else
  region=$2
fi

# Get a list of auto scaling groups.
autoscalinggroups=`aws autoscaling describe-auto-scaling-groups --profile ${profile} --region ${region} | jq -c '.AutoScalingGroups[]'`

# For each auto scaling group, try and delete it.
for group in $autoscalinggroups
do
  name=`echo "${group}" | jq -c '.AutoScalingGroupName' | tr -d '"'`
  min=`echo "${group}" | jq -c '.MinSize' | tr -d '"'`
  max=`echo "${group}" | jq -c '.MaxSize' | tr -d '"'`
  desired=`echo "${group}" | jq -c '.DesiredCapacity' | tr -d '"'`
  count=0
  
  instances=`echo "${group}" | jq -c '.Instances[]' | tr -d '"'`
  for instance in $instances
  do
    count=$count+1
  done

  if [[ "$count" == "0" && "$min" == "0" && "$max" == "0" && "$desired" == "0" ]]; then
    echo "${group}"
    echo "Attempting to delete auto scaling group: ${name}"
    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "${name}" --profile ${profile} --region ${region}
  elif [[ "$desired" == "0" ]]; then
    echo "(Desired set to 0) Attempting to delete auto scaling group: ${name}"
    aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "${name}" --profile ${profile} --region ${region}
  else
    echo "Auto scaling group ${name} has instances or is configured to have instances. And you cannot delete an AutoScalingGroup while there are instances or pending Spot instance request(s) still in the group."
  fi
done

