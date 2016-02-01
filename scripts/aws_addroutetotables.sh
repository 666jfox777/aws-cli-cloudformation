#!/bin/bash
################################################################################
#
#  Usage:  ./aws_addroutetotables.sh [profile] [region] [route] [ip]
#  
#  Arguments:
#    - profile: AWS Profile to use.
#    - region:  AWS region we're targeting.
#
################################################################################

if [ -z "$1" ]; then
  echo "Usage:  ./aws_addroutetotables.sh [profile] [region] [route] [ip]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage:  ./aws_addroutetotables.sh [profile] [region] [route] [ip]"
  exit
else
  region=$2
fi

if [ -z "$3" ]; then
  echo "Usage:  ./aws_addroutetotables.sh [profile] [region] [route] [ip]"
  exit
else
  iproute=$3
fi

if [ -z "$4" ]; then
  echo "Usage:  ./aws_addroutetotables.sh [profile] [region] [route] [ip]"
  exit
else
  ipaddr=$4
fi

routetables=`aws ec2 describe-route-tables --profile ${profile} --region ${region} --filters Name=tag-value,Values=*Private | jq -c '.RouteTables[].RouteTableId' | tr -d '"' | tr -d ' '`

for routetable in $routetables
do
  echo "Test"
done
