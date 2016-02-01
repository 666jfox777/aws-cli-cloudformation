#!/bin/bash
################################################################################
#
#  Usage:  ./aws_route53_copy.sh [profile-name] [region] [-f]
#
# Description:  
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_route53_copy.sh [source-profile] [destination-profile] [domain]"
  exit
else
  p1=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_route53_copy.sh [source-profile] [destination-profile] [domain]"
  exit
else
  p2=$2
fi

if [ -z "$3" ]; then
  echo "Usage: ./aws_route53_copy.sh [source-profile] [destination-profile] [domain]"
  exit
else
  domain=$3
fi


# First we need to get the hosted zone id.
sourceid=`aws route53 list-hosted-zones-by-name --dns-name ${domain} --max-items 1 --profile ${p1} | jq -c '.HostedZones[].Id' | tr -d '"' | sed 's|.*\/hostedzone\/\(.*\)|\1|'`
destid=`aws route53 list-hosted-zones-by-name --dns-name ${domain} --max-items 1 --profile ${p2} | jq -c '.HostedZones[].Id' | tr -d '"' | sed 's|.*\/hostedzone\/\(.*\)|\1|'`

# Get a nicely trimmed list of unused security groups.
sgs=`comm -23  <(aws ec2 describe-security-groups --query 'SecurityGroups[*].GroupId'  --output text --profile $profile --region $region | tr '\t' '\n'| sort) <(aws ec2 describe-instances --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text  --profile $profile --region $region | tr '\t' '\n' | sort | uniq)`

# For each launch config, try and delete it.
for sg in $sgs
do
  name=`aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[*].GroupName'  --output text --profile $profile --region $region`
  echo "Attempting to delete ${sg}: ${name}"
  echo -n "Do you really want to delete ${sg}? [N/y] "
  read -n 1 REPLY
  echo
  if test "$REPLY" = "y" -o "$REPLY" = "Y" -o "$FORCE" = "y"; then
    aws ec2 delete-security-group --group-id ${sg}  --profile $profile --region $region
  else
    echo "Did not delete ${sg} - ${name}"
  fi
done