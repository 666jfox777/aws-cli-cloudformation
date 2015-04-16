#!/bin/bash
################################################################################
#
#  Usage:  ./aws_addtagstountagged.sh [profile-name] [region] [tag key]\
#          [tag value]
#
# Description:  This script cycles through all EC2 instances and EBS volumes
#               and adds the tag requested if a tag does not exist.
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_addtagstountagged.sh [profile-name] [region] [tag key] [tag value]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_addtagstountagged.sh [profile-name] [region] [tag key] [tag value]"
  exit
else
  region=$2
fi

if [ -z "$3" ]; then
  echo "Usage: ./aws_addtagstountagged.sh [profile-name] [region] [tag key] [tag value]"
  exit
else
  key=$3
fi

if [ -z "$4" ]; then
  echo "Usage: ./aws_addtagstountagged.sh [profile-name] [region] [tag key] [tag value]"
  exit
else
  value=$4
fi

# Get a JSON object with the instance and tags.
instances=`aws ec2 describe-instances --profile ${profile} --region ${region} | jq -c '.Reservations[].Instances'`

# For each instance, check for a tag and add it if missing.
for instance in $instances
do

  # Store the instance id.
  id=`echo $instance | jq -c '.InstanceId'`
  
  # Store a list of keys.
  tags=`echo $instance | jq -c '.Tags[].Key'`
  
  # By default assume the key does not exist.
  tagexists=1
  
  # For each tag on the instance.
  for tag in $tags
  do
  
    # Check and see if the tag exists that matches the one we're looking to add.
    if [ "$tag" -eq "$key" ];then
      
      # Tag exists, set value to true.
      tagexists=0
      
    fi
    
  done
  
  # If we found the tag, then skip the instance, otherwise add the tag.
  if [ $tagexists ]; then
    echo "Tag exists, skipping ${id}."
  else
    aws ec2 create-tags --resources ${id} --tags Key=${key},Value=${value} --profile ${profile} --region ${region}
  fi

done
