#!/bin/bash
################################################################################
#
#  Usage:  ./aws_ec2inventory.sh [profile-name] [region]
#
# Description:  This script cycles through all EC2 instances and displays some
#               info.
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_ec2inventory.sh [profile-name] [region]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_ec2inventory.sh [profile-name] [region]"
  exit
else
  region=$2
fi

instances=`aws ec2 describe-instances --profile ${profile} --region ${region} | jq -c '.Reservations[].Instances[].InstanceId' | tr -d '"' | tr -d ' '`

# Print headings
echo "Profile / Account, Region, Instance ID, Public Hostname, Private Hostname, Public IP, Private IP, Operating System, Instance Size, AMI ID, AMI Description, AMI Location, AMI Architecture, Security Groups (; deliminated)"

for instance in $instances
do
  base=`aws ec2 describe-instances --profile ${profile} --region ${region} --instance-ids ${instance}`
  pub_host=`echo $base | jq -c '.Reservations[].Instances[].PublicDnsName' | tr -d '"' | tr -d ' '`
  pri_host=`echo $base | jq -c '.Reservations[].Instances[].PrivateDnsName' | tr -d '"' | tr -d ' '`
  pub_ip=`echo $base | jq -c '.Reservations[].Instances[].PublicIpAddress' | tr -d '"' | tr -d ' '`
  pri_ip=`echo $base | jq -c '.Reservations[].Instances[].PrivateIpAddress' | tr -d '"' | tr -d ' '`
  os_type=`echo $base | jq -c '.Reservations[].Instances[].Platform' | tr -d '"' | tr -d ' '`
  if [ -z "$os_type" ]; then
    os_type="linux"
  fi
  i_size=`echo $base | jq -c '.Reservations[].Instances[].InstanceType' | tr -d '"' | tr -d ' '`
  ami=`echo $base | jq -c '.Reservations[].Instances[].ImageId' | tr -d '"' | tr -d ' '`
  ami_details=`aws ec2 describe-images --profile ${profile} --region ${region} --image-ids $ami`
  ami_desc=`echo $ami_details | jq -c '.Images[].Description' | tr -d '"' | tr -d ' '`
  ami_arch=`echo $ami_details | jq -c '.Images[].Architecture' | tr -d '"' | tr -d ' '`
  ami_loc=`echo $ami_details | jq -c '.Images[].ImageLocation' | tr -d '"' | tr -d ' '`

  sgs=`echo $base | jq -c '.Reservations[].Instances[].SecurityGroups[]'`
  sgs_t=""
  for sg in $sgs
  do
    name=`echo $sg | jq -c '.GroupName' | tr -d '\"' | tr -d ' '`
    sgs_t="$sgs_t$name;"
  done

  echo "${profile}, ${region}, ${instance}, ${pub_host}, ${pri_host}, ${pub_ip}, ${pri_ip}, ${os_type}, ${i_size}, ${ami}, ${ami_desc}, ${ami_loc}, ${ami_arch}, ${sgs_t}"
done