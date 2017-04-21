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
REGION=${REGION:-"us-east-1"}

if [ -z "$PROFILE" ]; then
  echo "WARN: As no profile has been set, using default credentials." >&2
else
  PROFILE="$PROFILE"
fi

echo "Security Group ID, Security Group Name, Security Group Type, Ingress or Egress, Security Group Rule, Protocol, From Port, To Port, CIDR or Security Group ID"
securitygroups=`aws ec2 describe-security-groups $PROFILE --region $REGION | jq -c '.SecurityGroups[].GroupId' | tr -d '"' | tr -d ' '`
for securitygroup in $securitygroups
do
  secname=`aws ec2 describe-security-groups --group-ids ${securitygroup} $PROFILE --region $REGION | jq -c '.SecurityGroups[].GroupName' | tr -d '"' | tr -d ' '`
  vpcid=`aws ec2 describe-security-groups --group-ids ${securitygroup} $PROFILE --region $REGION | jq -c '.SecurityGroups[].VpcId' | tr -d '"' | tr -d ' '`
  sectype=""
  if [ "null" != "${vpcid}" ]
  then
    vpcname=`aws ec2 describe-tags --filters "Name=resource-id,Values=${vpcid}" "Name=key,Values=Name" $PROFILE --region $REGION | jq -c '.Tags[].Value' | tr -d '"' | tr -d ' '`
    sectype="${vpcname} (${vpcid})"
  else
    sectype="Classic"
  fi
  rulesin=`aws ec2 describe-security-groups --group-ids ${securitygroup} $PROFILE --region $REGION | jq -c '.SecurityGroups[].IpPermissions[]'`
  rulesout=`aws ec2 describe-security-groups --group-ids ${securitygroup} $PROFILE --region $REGION | jq -c '.SecurityGroups[].IpPermissionsEgress[]'`
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
        echo "$securitygroup,$secname,$sectype,Ingress,#,$protocol,$fromport,$toport,$cidr"
      done
    fi
    if [ "" != "${refsgids}" ]
    then
      for sgid in $refsgids
      do
        sgname=`aws ec2 describe-security-groups --group-ids ${sgid} $PROFILE --region $REGION 2> /dev/null | jq -c '.SecurityGroups[].GroupName' | tr -d '"' | tr -d ' '`
        if [ "" != "${sgname}" ]
        then
          echo "$securitygroup,$secname,$sectype,Ingress,#,$protocol,$fromport,$toport,$sgname ($sgid)"
        else
          echo "$securitygroup,$secname,$sectype,Ingress,#,$protocol,$fromport,$toport,$sgid (Name Error)"
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
        echo "$securitygroup,$secname,$sectype,Egress,#,$protocol,$fromport,$toport,$cidr"
      done
    fi
    if [ "" != "${refsgids}" ]
    then
      for sgid in $refsgids
      do
        sgname=`aws ec2 describe-security-groups --group-ids ${sgid} $PROFILE --region $REGION | jq -c '.SecurityGroups[].GroupName' | tr -d '"' | tr -d ' '`
        if [ "" != "${sgname}" ]
        then
          echo "$securitygroup,$secname,$sectype,Egress,#,$protocol,$fromport,$toport,$sgname ($sgid)"
        else
          echo "$securitygroup,$secname,$sectype,Egress,#,$protocol,$fromport,$toport,$sgid (Name Error)"
        fi
      done
    fi
  done
done