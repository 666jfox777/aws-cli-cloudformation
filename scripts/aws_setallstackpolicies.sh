#!/bin/bash
################################################################################
#
#  Usage:  ./aws_setallstackpolicies.sh [profile-name] [region] [policy]
#
# Description:  This script cycles through and attempts to delete all your
#               launch configurations. It will post a failure for configs
#               currently in use.
#
# Sample Policy:
#
# {"Statement":[{"Effect":"Deny","Action":["Update:Delete","Update:Replace"],"Principal":"*","Resource":"*"},{"Effect":"Allow","Action":"Update:*","Principal":"*","Resource":"*"}]}
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_setallstackpolicies.sh [profile-name] [region] [policy]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_setallstackpolicies.sh [profile-name] [region] [policy]"
  exit
else
  region=$2
fi

if [ -z "$3" ]; then
  echo "Usage: ./aws_setallstackpolicies.sh [profile-name] [region] [policy]"
  exit
else
  policy=$3
fi

# Get a nicely trimmed list of all cloudformation stacks.
stacks=`aws cloudformation list-stacks --stack-status-filter "UPDATE_COMPLETE" "CREATE_COMPLETE" "ROLLBACK_COMPLETE" --profile ${profile} --region ${region} | jq -c '.StackSummaries[].StackName' | tr -d '"' | tr -d ' '`

# For each launch config, try and delete it.
for stack in $stacks
do
  echo
  echo "Attempting to set stack policy for: ${stack}"
  aws cloudformation set-stack-policy --stack-name ${stack} --stack-policy-body ${policy} --profile ${profile} --region ${region}
done
