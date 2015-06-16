#!/bin/bash
################################################################################
#
#  Usage:  ./aws_terminatespot.sh [profile-name] [region]
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_terminatespot.sh [profile-name] [region]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_terminatespot.sh [profile-name] [region]"
  exit
else
  region=$2
fi

instances=`aws ec2 describe-spot-instance-requests --filters Name=state,Values=cancelled --profile ${profile} --region ${region} | jq -c '.SpotInstanceRequests[].InstanceId' | tr -d '"' | tr -d ' '`

for instance in $instances
do
  aws ec2 terminate-instances --instance-ids ${instance} --profile ${profile} --region ${region} > /dev/null 2>&1
done
