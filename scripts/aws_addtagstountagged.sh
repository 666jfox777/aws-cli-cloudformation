#!/bin/bash
################################################################################
#
#  Usage:  ./aws_addtagstountagged.sh [profile-name] [region] [tag key]\
#          [tag value] [Optional: security group id]
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

# Get a JSON object with the instance ids.
if [ -z "$5" ]; then
  instances=`aws ec2 describe-instances --profile ${profile} --region ${region} | jq -c '.Reservations[].Instances[].InstanceId' | tr -d '"' | tr -d ' '`
else
  instances=`aws ec2 describe-instances --filters Name=instance.group-id,Values=${5} --profile ${profile} --region ${region} | jq -c '.Reservations[].Instances[].InstanceId' | tr -d '"' | tr -d ' '`
fi


# For each instance, check for a tag and add it if missing.
for instance in $instances
do
  
  echo "InstanceID: ${instance}"

  # Store a list of keys.
  tags=`aws ec2 describe-instances --instance-ids ${instance} --profile ${profile} --region ${region} | jq -c '.Reservations[].Instances[].Tags[].Key' | tr -d '"' | tr -d ' '`
  
  # By default assume the key does not exist.
  tagexists=false
  
  # For each tag on the instance.
  for tag in $tags
  do

    # Check and see if the tag exists that matches the one we're looking to add.
    if [ "$tag" == "$key" ];then

      # Tag exists, set value to true.
      tagexists=true
      
    fi
    
  done
  
  # If we found the tag, then skip the instance, otherwise add the tag.
  if $tagexists; then
    echo "-- Tag exists, skipping ${instance}."
  else
    echo "-- Adding tag ${key}=${value} to ${instance}."
    aws ec2 create-tags --resources ${instance} --tags Key=${key},Value=${value} --profile ${profile} --region ${region}
  fi

done


# Get a JSON object with the ebs volume ids.
volumes=`aws ec2 describe-volumes --profile ${profile} --region ${region} | jq -c '.Volumes[].VolumeId' | tr -d '"' | tr -d ' '`

# For each volume, check for a tag and add it if missing.
for volume in $volumes
do
  
  echo "VolumeID: ${volume}"

  # Store a list of keys.
  tags=`aws ec2 describe-volumes --volume-ids ${volume} --profile ${profile} --region ${region} | jq -c '.Volumes[].Tags[].Key' | tr -d '"' | tr -d ' '`
  
  # By default assume the key does not exist.
  tagexists=false
  
  # For each tag on the instance.
  for tag in $tags
  do

    # Check and see if the tag exists that matches the one we're looking to add.
    if [ "$tag" == "$key" ];then

      # Tag exists, set value to true.
      tagexists=true
      
    fi
    
  done
  
  # If we found the tag, then skip the instance, otherwise add the tag.
  if $tagexists; then
    echo "-- Tag exists, skipping ${volume}."
  else
    echo "-- Adding tag ${key}=${value} to ${volume}."
    aws ec2 create-tags --resources ${volume} --tags Key=${key},Value=${value} --profile ${profile} --region ${region}
  fi

done

