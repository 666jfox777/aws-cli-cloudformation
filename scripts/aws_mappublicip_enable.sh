#!/bin/bash
################################################################################
#
#  Usage:  ./aws_mappublicip_enable.sh [profile] [region] [Optional:vpc-id]
#  
#  Arguments:
#    - profile: AWS Profile to use.
#    - region:  AWS region we're targeting.
#    - vpc-id:  The VPC identifier of the VPC you want all your VPCs to be
#               peered with.
#
# Description:  This script takes a VPC ID that you want to enable public ips on
#               by default. If no VPC ID is provide, it will do this to all VPCs
#
################################################################################

if [ -z "$1" ]; then
  echo "Usage:  ./aws_mappublicip_enable.sh [profile] [region] [Optional:vpc-id]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage:  ./aws_mappublicip_enable.sh [profile] [region] [Optional:vpc-id]"
  exit
else
  region=$2
fi

if [ -z "$3" ]; then
  subnets=`aws ec2 describe-subnets --profile ${profile} --region ${region} | jq -c '.Subnets[].SubnetId' | tr -d '"' | tr -d ' '`
else
  vpc=$3
  subnets=`aws ec2 describe-subnets --filters "Name=vpc-id,Values=${vpc}" --profile ${profile} --region ${region} | jq -c '.Subnets[].SubnetId' | tr -d '"' | tr -d ' '`
fi

for subnet in $subnets
do
  aws ec2 modify-subnet-attribute --subnet-id ${subnet} --map-public-ip-on-launch --profile ${profile} --region ${region}
done