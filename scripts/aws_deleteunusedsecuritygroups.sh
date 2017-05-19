#!/bin/bash
################################################################################
#
#  Usage:  ./aws_deleteunusedsecuritygroups.sh [profile-name] [region] [-f]
#
# Description:  This script cycles through and attempts to delete all your
#               launch configurations. It will post a failure for configs
#               currently in use.
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_deleteunusedsecuritygroups.sh [profile-name] [region]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_deleteunusedsecuritygroups.sh [profile-name] [region]"
  exit
else
  region=$2
fi

if [ -z "$3" ]; then
  echo "Force option not used, will prompt for each security group."
else
  FORCE="y"
fi

# Get a nicely trimmed list of unused security groups.
sgs=`comm -23  <(aws ec2 describe-security-groups --query 'SecurityGroups[*].GroupId'  --output text --profile $profile --region $region | tr '\t' '\n'| sort) <(aws ec2 describe-instances --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text  --profile $profile --region $region | tr '\t' '\n' | sort | uniq)`

# For each launch config, try and delete it.
for sg in $sgs
do
  name=`aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[*].GroupName'  --output text --profile $profile --region $region`
  echo "Attempting to delete ${sg}: ${name}"
  if [ -z "$FORCE" ]; then
    echo -n "Do you really want to delete ${sg}? [N/y] "
    read -n 1 REPLY
    echo
  fi
  if test "$REPLY" = "y" -o "$REPLY" = "Y" -o "$FORCE" = "y"; then
    aws ec2 delete-security-group --group-id ${sg}  --profile $profile --region $region
  else
    echo "Did not delete ${sg} - ${name}"
  fi
done
