#!/bin/bash
################################################################################
#
#  Usage:  ./aws_listfirewallrules.sh [profile-name] [region]
#
# Description:  This script reads the configuration of every security group on
#               the AWS account and checks for instances that use the security
#               group. Useful for security auditing purposes.
#
################################################################################
usage ()
{
  echo "Usage: $0 [profile-name] [region] > output.csv"
}

get_security_group()
{
  OLDIFS=$IFS
  IFS=$'\n'
  groups=`echo "$securitygroups" | jq -c '.SecurityGroups[]'`
  for group in $groups
  do
    if [[ `echo "$group" | jq -c '.GroupId' | tr -d '"' | tr -d ' '` == $1 ]]; then
      echo "$group"
    fi
  done
  IFS=$OLDIFS
}

get_vpc_name()
{
  OLDIFS=$IFS
  IFS=$'\n'
  for tag in `echo "$tags" | jq -c '.Tags[]'`
  do
    if [[ `echo "$tag" | jq -c '.ResourceId' | tr -d '"' | tr -d ' '` == $1 ]]; then
      echo "$tag" | jq -c '.Value' | tr -d '"' | tr -d ' '
    fi
  done
  IFS=$OLDIFS
}

# Process all the arguments
while getopts ":h?p:r:" opt; do
    case $opt in
        p)
          PROFILE=$OPTARG
          echo "Account has been set to: $OPTARG" >&2
          ;;
        r)
          REGION=$OPTARG
          echo "Region has been set to: $OPTARG" >&2
          ;;
        h|\?)
          usage
          exit 0
          ;;
        :)
          echo "Option -$OPTARG requires an argument." >&2
          usage
          exit 1
          ;;
    esac
done

# Set a few defaults
PROFILE=${PROFILE:-""}
REGION=${REGION:-""}

if [ -z "$PROFILE" ]; then
  echo "WARN: As no profile has been set, using default credentials." >&2
else
  PROFILE="--profile $PROFILE"
fi

if [ -z "$REGION" ]; then
  echo "WARN: As no region has been set, using default of us-east-1." >&2
  REGION="--region us-east-1"
else
  REGION="--region $REGION"
fi

# BIG VARS
securitygroups=`aws ec2 describe-security-groups $PROFILE $REGION`
tags=`aws ec2 describe-tags --filters "Name=resource-type,Values=vpc" "Name=key,Values=Name" $PROFILE $REGION`

# Print out the CSV header
echo "Security Group ID, Security Group Name, Security Group Type, Ingress or Egress, Security Group Rule, Protocol, From Port, To Port, CIDR or Security Group ID"

# Get the security group ids and iterate through them
securitygroupids=`echo "$securitygroups" | jq -c '.SecurityGroups[].GroupId' | tr -d '"' | tr -d ' '`

for securitygroupid in $securitygroupids
do
  secname=`get_security_group ${securitygroupid} | jq -c '.GroupName' | tr -d '"' | tr -d ' '`
  vpcid=`get_security_group ${securitygroupid} | jq -c '.VpcId' | tr -d '"' | tr -d ' '`
  sectype=""
  if [ "null" != "${vpcid}" ]
  then
    vpcname=`get_vpc_name ${vpcid}`
    sectype="${vpcname} (${vpcid})"
  else
    sectype="Classic"
  fi
  rulesin=`get_security_group ${securitygroupid} | jq -c '.IpPermissions[]'`
  rulesout=`get_security_group ${securitygroupid} | jq -c '.IpPermissionsEgress[]'`
  for rule in $rulesin
  do
    protocol=`echo "$rule" | jq -c '.IpProtocol' | tr -d '"' | tr -d ' '`
    fromport=`echo "$rule" | jq -c '.FromPort' | tr -d '"' | tr -d ' '`
    toport=`echo "$rule" | jq -c '.ToPort' | tr -d '"' | tr -d ' '`
    ipranges=`echo "$rule" | jq -c '.IpRanges[].CidrIp' | tr -d '"' | tr -d ' '`
    refsgids=`echo "$rule" | jq -c '.UserIdGroupPairs[].GroupId' | tr -d '"' | tr -d ' '`
    if [ "" != "${ipranges}" ]
    then
      for cidr in $ipranges
      do
        echo "$securitygroupid,$secname,$sectype,Ingress,#,$protocol,$fromport,$toport,$cidr"
      done
    fi
    if [ "" != "${refsgids}" ]
    then
      for sgid in $refsgids
      do
        sgname=`get_security_group ${sgid} | jq -c '.GroupName' | tr -d '"' | tr -d ' '`
        if [ "" != "${sgname}" ]
        then
          echo "$securitygroupid,$secname,$sectype,Ingress,#,$protocol,$fromport,$toport,$sgname ($sgid)"
        else
          echo "$securitygroupid,$secname,$sectype,Ingress,#,$protocol,$fromport,$toport,$sgid (Name Error)"
        fi
      done
    fi
  done
  for rule in $rulesout
  do
    protocol=`echo "$rule" | jq -c '.IpProtocol' | tr -d '"' | tr -d ' '`
    fromport=`echo "$rule" | jq -c '.FromPort' | tr -d '"' | tr -d ' '`
    toport=`echo "$rule" | jq -c '.ToPort' | tr -d '"' | tr -d ' '`
    ipranges=`echo "$rule" | jq -c '.IpRanges[].CidrIp' | tr -d '"' | tr -d ' '`
    refsgids=`echo "$rule" | jq -c '.UserIdGroupPairs[].GroupId' | tr -d '"' | tr -d ' '`

    if [ "" != "${ipranges}" ]
    then
      for cidr in $ipranges
      do
        echo "$securitygroupid,$secname,$sectype,Egress,#,$protocol,$fromport,$toport,$cidr"
      done
    fi
    if [ "" != "${refsgids}" ]
    then
      for sgid in $refsgids
      do
        sgname=`get_security_group ${sgid} | jq -c '.GroupName' | tr -d '"' | tr -d ' '`
        if [ "" != "${sgname}" ]
        then
          echo "$securitygroupid,$secname,$sectype,Egress,#,$protocol,$fromport,$toport,$sgname ($sgid)"
        else
          echo "$securitygroupid,$secname,$sectype,Egress,#,$protocol,$fromport,$toport,$sgid (Name Error)"
        fi
      done
    fi
  done
done