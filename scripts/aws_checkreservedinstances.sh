#!/bin/bash
################################################################################
#
#  Usage:  ./aws_checkreservedinstances.sh [profile-name] [region]
#
# Description:  Displays a table with reserved instance data.
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_checkreservedinstances.sh [profile-name] [region]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_checkreservedinstances.sh [profile-name] [region]"
  exit
else
  region=$2
fi

reserves=`aws ec2 describe-reserved-instances-modifications --profile ${profile} --region ${region} | jq -c '.ReservedInstancesModifications[]'`

echo "Reservation ID | Platform | Availability Zone | Instance Type | Instance Count"
echo "--------------------------------------------------------------------------------"
# For each launch config, try and delete it.
for reserved in $reserves
do
  r_id=`echo ${reserved} | jq -c '.ReservedInstancesIds[].ReservedInstancesId' | tr -d '"' | tr '\n' ' ' | sed -e's/[[:space:]]*$//'`
  platform=`echo ${reserved} | jq -c '.ModificationResults[].TargetConfiguration.Platform' | tr -d '"' | tr '\n' ' '`
  az=`echo ${reserved} | jq -c '.ModificationResults[].TargetConfiguration.AvailabilityZone' | tr -d '"' | tr '\n' ' '`
  i_type=`aws ec2 describe-reserved-instances --reserved-instances-ids ${r_id} --profile ${profile} --region ${region} | jq -c '.ReservedInstances[].InstanceType' | tr -d '"'`
  count=`echo ${reserved} | jq -c '.ModificationResults[].TargetConfiguration.InstanceCount' | tr -d '"'` | tr '\n' ' '
  echo "${r_id} | ${platform} | ${az} |  ${i_type} | ${count}"
  echo "--------------------------------------------------------------------------------"
done