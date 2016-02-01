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
if [ -z "$1" ]; then
  echo "Usage: ./aws_listfirewallrules.sh [profile-name] [region]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_listfirewallrules.sh [profile-name] [region]"
  exit
else
  region=$2
fi

# Get a list of all security groups for a region.
securitygroups=`aws ec2 describe-security-groups --profile $profile --region $region | jq -c '.SecurityGroups[].GroupId' | tr -d '"' | tr -d ' '`

# Iterate through the groups
for securitygroup in $securitygroups
do
  secname=`aws ec2 describe-security-groups --group-ids ${securitygroup} --profile $profile --region $region | jq -c '.SecurityGroups[].GroupName' | tr -d '"' | tr -d ' '`
  vpcid=`aws ec2 describe-security-groups --group-ids ${securitygroup} --profile $profile --region $region | jq -c '.SecurityGroups[].VpcId' | tr -d '"' | tr -d ' '`
  if [ "null" != "${vpcid}" ]
  then
    vpcname=`aws ec2 describe-tags --filters "Name=resource-id,Values=${vpcid}" "Name=key,Values=Name" --profile $profile --region $region | jq -c '.Tags[].Value' | tr -d '"' | tr -d ' '`
    echo "    ${secname} (SG: ${securitygroup} | VPC: ${vpcname} / ${vpcid})"
  else
    echo "    ${secname} (SG: ${securitygroup} | Classic)"
  fi
  rulesin=`aws ec2 describe-security-groups --group-ids ${securitygroup} --profile $profile --region $region | jq -c '.SecurityGroups[].IpPermissions[]'`
  rulesout=`aws ec2 describe-security-groups --group-ids ${securitygroup} --profile $profile --region $region | jq -c '.SecurityGroups[].IpPermissionsEgress[]'`
  echo "        Firewall Rules:"
  echo "            Ingress:"
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
        echo "                Protocol: ${protocol}, FromPort: ${fromport}, ToPort: ${toport}, CIDR: ${cidr}"
      done
    fi
    if [ "" != "${refsgids}" ]
    then
      for sgid in $refsgids
      do
        sgname=`aws ec2 describe-security-groups --group-ids ${sgid} --profile $profile --region $region 2> /dev/null | jq -c '.SecurityGroups[].GroupName' | tr -d '"' | tr -d ' '`
        if [ "" != "${sgname}" ]
        then
          echo "                Protocol: ${protocol}, FromPort: ${fromport}, ToPort: ${toport}, Security Group: ${sgname} (${sgid})"
        else
          echo "                Protocol: ${protocol}, FromPort: ${fromport}, ToPort: ${toport}, Security Group: Name Unavailable (${sgid})"
        fi
      done
    fi
  done
  echo "            Egress:"
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
        echo "                Protocol: ${protocol}, FromPort: ${fromport}, ToPort: ${toport}, CIDR: ${cidr}"
      done
    fi
    if [ "" != "${refsgids}" ]
    then
      for sgid in $refsgids
      do
        sgname=`aws ec2 describe-security-groups --group-ids ${sgid} --profile $profile --region $region | jq -c '.SecurityGroups[].GroupName' | tr -d '"' | tr -d ' '`
        echo "                Protocol: ${protocol}, FromPort: ${fromport}, ToPort: ${toport}, Security Group: ${sgname} (${sgid})"
      done
    fi
  done
  instances=`aws ec2 describe-instances --filters "Name=instance.group-id,Values=${securitygroup}" --profile $profile --region $region| jq -c '.Reservations[].Instances[]' | tr -d ' '`
  echo "        Instances:"
  for instance in $instances
  do
    instanceid=`echo "${instance}" | jq -c '.InstanceId' | tr -d '"' | tr -d ' '`
    instancename=`aws ec2 describe-tags --filters Name=resource-id,Values=${instanceid} Name=key,Values=Name --profile $profile --region $region | jq -c '.Tags[].Value' | tr -d '"' | tr -d ' '`
    instanceasg=`aws ec2 describe-tags --filters Name=resource-id,Values=${instanceid} Name=key,Values="aws:autoscaling:groupName" --profile $profile --region $region | jq -c '.Tags[].Value' | tr -d '"' | tr -d ' '`
    instancebc=`aws ec2 describe-tags --filters Name=resource-id,Values=${instanceid} Name=key,Values=bc --profile $profile --region $region | jq -c '.Tags[].Value' | tr -d '"' | tr -d ' '`
    instanceprivate=`echo "${instance}" | jq -c '.PrivateIpAddress' | tr -d '"' | tr -d ' '`
    instancepublic=`echo "${instance}" | jq -c '.PublicIpAddress' | tr -d '"' | tr -d ' '`
    echo "            Instance Id: ${instanceid}, Instance Name: ${instancename}, Auto Scaling Group: ${instanceasg}, BC Tag: ${instancebc}, Private IP: ${instanceprivate}, Public IP: ${instancepublic}"
  done
  echo ""
done