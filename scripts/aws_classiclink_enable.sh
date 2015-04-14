#!/bin/bash
################################################################################
#
#  Usage:  ./aws_classiclink_enable.sh [profile] [region] [vpc-id] [sg-id]
#  
#  Arguments:
#    - profile: AWS Profile to use.
#    - region:  AWS region we're targeting.
#    - vpc-id:  The VPC identifier of the VPC you want all your VPCs to be
#               peered with.
#    - sg-id:   The security group identifier of the security group you want all
#               the classic instances to join.
#
# Description:  This script takes a VPC ID that you want to enable classic-link
#               on, and the SG-ID (security group id) that the linked instances
#               should be in.
#
################################################################################

if [ -z "$1" ]; then
  echo "Usage:  ./aws_classiclink_enable.sh [profile] [region] [vpc-id] [sg-id]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage:  ./aws_classiclink_enable.sh [profile] [region] [vpc-id] [sg-id]"
  exit
else
  region=$2
fi

if [ -z "$3" ]; then
  echo "Usage:  ./aws_classiclink_enable.sh [profile] [region] [vpc-id] [sg-id]"
  exit
else
  vpc=$3
fi

if [ -z "$4" ]; then
  echo "Usage:  ./aws_classiclink_enable.sh [profile] [region] [vpc-id] [sg-id]"
  exit
else
  sg=$4
fi


# Enable classiclink on a vpc
aws ec2 enable-vpc-classic-link --vpc-id ${vpc} --profile ${profile}

# Activate classiclink on all instances... Note this will show errors for instances in a VPC.
instances=`aws ec2 describe-instances --profile ${profile} --region ${region} | jq -c '.Reservations[].Instances[].InstanceId' | tr -d '"' | tr -d ' '`
for instance in $instances
do
  aws ec2 attach-classic-link-vpc --instance-id ${instance} --vpc-id ${vpc} --groups ${sg} --profile ${profile} --region ${region}
done
