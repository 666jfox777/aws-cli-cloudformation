#!/bin/bash
################################################################################
#
#  Usage:  ./aws_listinstancerules.sh [profile-name] [region]
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
if [ -z "$1" ] || [ -z "$2" ]; then
  usage
  exit
else
  profile=$1
  region=$2
fi

echo "Instance ID, Instance Name, Auto Scaling Group, BC Tag, Private IP, Public IP, Security Group ID, Security Group Name, Security Group Type, Ingress or Egress, Security Group Rule, Protocol, From Port, To Port, CIDR or Security Group ID"

instances=`aws ec2 describe-instances --profile $profile --region $region | jq -c '.Reservations[].Instances[]' | tr -d ' '`
for instance in $instances
do
  instanceid=`echo "${instance}" | jq -c '.InstanceId' | tr -d '"' | tr -d ' '`
  instancename=`aws ec2 describe-tags --filters Name=resource-id,Values=${instanceid} Name=key,Values=Name --profile $profile --region $region | jq -c '.Tags[].Value' | tr -d '"' | tr -d ' '`
  instanceasg=`aws ec2 describe-tags --filters Name=resource-id,Values=${instanceid} Name=key,Values="aws:autoscaling:groupName" --profile $profile --region $region | jq -c '.Tags[].Value' | tr -d '"' | tr -d ' '`
  instancebc=`aws ec2 describe-tags --filters Name=resource-id,Values=${instanceid} Name=key,Values=bc --profile $profile --region $region | jq -c '.Tags[].Value' | tr -d '"' | tr -d ' '`
  instanceprivate=`echo "${instance}" | jq -c '.PrivateIpAddress' | tr -d '"' | tr -d ' '`
  instancepublic=`echo "${instance}" | jq -c '.PublicIpAddress' | tr -d '"' | tr -d ' '`
  instancesecuritygroups=`echo "${instance}" | jq -c '.SecurityGroups[].GroupId' | tr -d '"' | tr -d ' '`
  for securitygroup in $instancesecuritygroups
  do
    secname=`aws ec2 describe-security-groups --group-ids ${securitygroup} --profile $profile --region $region | jq -c '.SecurityGroups[].GroupName' | tr -d '"' | tr -d ' '`
    vpcid=`aws ec2 describe-security-groups --group-ids ${securitygroup} --profile $profile --region $region | jq -c '.SecurityGroups[].VpcId' | tr -d '"' | tr -d ' '`
    sectype=""
    if [ "null" != "${vpcid}" ]
    then
      vpcname=`aws ec2 describe-tags --filters "Name=resource-id,Values=${vpcid}" "Name=key,Values=Name" --profile $profile --region $region | jq -c '.Tags[].Value' | tr -d '"' | tr -d ' '`
      sectype="${vpcname} (${vpcid})"
    else
      sectype="Classic"
    fi
    rulesin=`aws ec2 describe-security-groups --group-ids ${securitygroup} --profile $profile --region $region | jq -c '.SecurityGroups[].IpPermissions[]'`
    rulesout=`aws ec2 describe-security-groups --group-ids ${securitygroup} --profile $profile --region $region | jq -c '.SecurityGroups[].IpPermissionsEgress[]'`
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
          echo "$instanceid,$instancename,$instanceasg,$instancebc,$instanceprivate,$instancepublic,$securitygroup,$secname,$sectype,Ingress,#,$protocol,$fromport,$toport,$cidr"
        done
      fi
      if [ "" != "${refsgids}" ]
      then
        for sgid in $refsgids
        do
          sgname=`aws ec2 describe-security-groups --group-ids ${sgid} --profile $profile --region $region 2> /dev/null | jq -c '.SecurityGroups[].GroupName' | tr -d '"' | tr -d ' '`
          if [ "" != "${sgname}" ]
          then
            echo "$instanceid,$instancename,$instanceasg,$instancebc,$instanceprivate,$instancepublic,$securitygroup,$secname,$sectype,Ingress,#,$protocol,$fromport,$toport,$sgname ($sgid)"
          else
            echo "$instanceid,$instancename,$instanceasg,$instancebc,$instanceprivate,$instancepublic,$securitygroup,$secname,$sectype,Ingress,#,$protocol,$fromport,$toport,$sgid (Name Error)"
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
          echo "$instanceid,$instancename,$instanceasg,$instancebc,$instanceprivate,$instancepublic,$securitygroup,$secname,$sectype,Egress,#,$protocol,$fromport,$toport,$cidr"
        done
      fi
      if [ "" != "${refsgids}" ]
      then
        for sgid in $refsgids
        do
          sgname=`aws ec2 describe-security-groups --group-ids ${sgid} --profile $profile --region $region | jq -c '.SecurityGroups[].GroupName' | tr -d '"' | tr -d ' '`
          if [ "" != "${sgname}" ]
          then
            echo "$instanceid,$instancename,$instanceasg,$instancebc,$instanceprivate,$instancepublic,$securitygroup,$secname,$sectype,Egress,#,$protocol,$fromport,$toport,$sgname ($sgid)"
          else
            echo "$instanceid,$instancename,$instanceasg,$instancebc,$instanceprivate,$instancepublic,$securitygroup,$secname,$sectype,Egress,#,$protocol,$fromport,$toport,$sgid (Name Error)"
          fi
        done
      fi
    done
  done
done