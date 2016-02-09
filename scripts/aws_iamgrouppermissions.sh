#!/bin/bash
################################################################################
#
# Usage:        ./aws_iamgrouppermissions.sh [profile-name]
#
# Description:  This script uses the AWS CLI retrieve a print out of all groups
#               (including user accounts) with permissions assigned to the
#               groups. Additionally retrieves a print out of all users with
#               special permissions assigned and users without groups.
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_iamgrouppermissions.sh [profile-name]"
  echo "Usage: ./aws_iamgrouppermissions.sh [profile-name] csv > output.csv"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "--- Groups with permissions ---"
  iamgroups=`aws iam list-groups --profile ${profile} | jq -c '.Groups[].GroupName' | tr -d '"' | tr -d ' '`
  for iamgroup in $iamgroups
  do
    echo "    ${iamgroup}"
    iamusers=`aws iam get-group --group-name ${iamgroup} --profile ${profile} | jq -c '.Users[].UserName' | tr -d '"' | tr -d ' '`
    echo "        Users:"
    for iamuser in $iamusers
    do
      echo "            ${iamuser}"
    done
    iaminlinepolicies=`aws iam list-group-policies --group-name ${iamgroup} --profile ${profile} | jq -c '.PolicyNames[]' | tr -d '"' | tr -d ' '`
    echo "        Inline Policies:"
    for inlinepolicy in $iaminlinepolicies
    do
      iaminlinepolicy=`aws iam get-group-policy --group-name ${iamgroup} --policy-name ${inlinepolicy} --profile ${profile} | jq -c '.PolicyDocument.Statement[]' | tr -d '"' | tr -d ' '`
      echo "            ${inlinepolicy}"
      for policy in $iaminlinepolicy
      do
        echo "                ${policy}"
      done
    done
    iammanagedpolicies=`aws iam list-attached-group-policies --group-name ${iamgroup} --profile ${profile} | jq -c '.AttachedPolicies[]'`
    echo "        Managed Policies:"
    for managedpolicy in $iammanagedpolicies
    do
      iampolicyarn=`echo ${managedpolicy} | jq -c '.PolicyArn' | tr -d '"' | tr -d ' '`
      echo "${iampolicyarn}"
      iampolicyname=`echo ${managedpolicy} | jq -c '.PolicyName' | tr -d '"' | tr -d ' '`
      iampolicyversion=`aws iam get-policy --policy-arn ${iampolicyarn} --profile ${profile} | jq -c '.Policy.DefaultVersionId' | tr -d '"' | tr -d ' '`
      iammanagedpolicy=`aws iam get-policy-version --policy-arn ${iampolicyarn} --version-id ${iampolicyversion} --profile ${profile} | jq -c '.PolicyVersion.Document.Statement[]' | tr -d '"' | tr -d ' '`
      echo "            ${iampolicyname}"
      for policy in $iammanagedpolicy
      do
        echo "                ${policy}"
      done
    done
    echo ""
    echo ""
  done
  echo "--- IAM users with special policies ---"
  iamusers=`aws iam list-users --profile ${profile} | jq -c '.Users[].UserName' | tr -d '"' | tr -d ' '`
  for iamuser in $iamusers
  do
    policycount=`aws iam list-user-policies --user-name ${iamuser} --profile ${profile} | jq -c '.PolicyNames[]' | wc -l | tr -d ' '`
    if [[ "0" != "${policycount}" ]]
    then
      echo "    ${iamuser}"
      policynames=`aws iam list-user-policies --user-name ${iamuser} --profile ${profile} | jq -c '.PolicyNames[]' | tr -d '"' | tr -d ' '`
      for policyname in $policynames
      do
        policy=`aws iam get-user-policy --user-name ${iamuser} --policy-name ${policyname} --profile ${profile} | jq -c '.PolicyDocument.Statement' | tr -d '"' | tr -d ' '`
        echo "        ${policyname}"
        echo "            ${policy}"
      done
    fi
  done
  echo "--- IAM users without a group ---"
  iamusers=`aws iam list-users --profile ${profile} | jq -c '.Users[].UserName' | tr -d '"' | tr -d ' '`
  for iamuser in $iamusers
  do
    groupcount=`aws iam list-groups-for-user --user-name ${iamuser} --profile ${profile} | jq -c '.Groups[].GroupName' | wc -l | tr -d ' '`
    if [[ "0" == "${groupcount}" ]]
    then
      echo "    ${iamuser}"
    fi
  done
else
  echo "ARN,FriendlyName,Type,Memberships,Can disable cloudtrail? (cloudtrail:DeleteTrail/cloudtrail:DeleteTrail/cloudtrail:DeleteTrail),Can add Users? (iam:CreateUser/iam:DeleteUser/iam:UpdateUser),Can modify firewall rules? (ec2:AuthorizeSecurityGroupEgress/ec2:AuthorizeSecurityGroupIngress/ec2:CreateSecurityGroup/ec2:DeleteSecurityGroup/ec2:RevokeSecurityGroupEgress/ec2:RevokeSecurityGroupIngress),InlinePolicies,InlinePoliciesExpanded,ManagedPolicies,ManagedPoliciesExpanded"
  iamusers=`aws iam list-users --profile ${profile} | jq -c '.Users[]'`
  for iamuser in $iamusers
  do
    arn=`echo ${iamuser} | jq -c '.Arn' | tr -d '"'`
    friendlyname=`echo ${iamuser} | jq -c '.UserName' | tr -d '"'`
    groupnames=`aws iam list-groups-for-user --user-name ${friendlyname} --profile ${profile} | jq -c '.Groups[].GroupName' | tr '"' ' '| tr -d '\n'`
    policynames=`aws iam list-user-policies --user-name ${friendlyname} --profile ${profile} | jq -c '.PolicyNames[]' | tr '"' ' '| tr -d '\n'`
    csvpolicy=""
    policies=`aws iam list-user-policies --user-name ${friendlyname} --profile ${profile} | jq -c '.PolicyNames[]' | tr -d '"' | tr -d ' '`
    for policy in $policies
    do
      p=`aws iam get-user-policy --user-name ${friendlyname} --policy-name ${policy} --profile ${profile} | jq -c '.PolicyDocument.Statement' | tr -d '"' | tr -d ' '`
      csvpolicy="$csvpolicy$p"
    done
    managedpolicynames=`aws iam list-attached-user-policies --user-name ${friendlyname} --profile ${profile} | jq -c '.AttachedPolicies[].PolicyName' | tr '"' ' '| tr -d '\n'`
    csvmanagedpolicy=""
    managedpolicies=`aws iam list-attached-user-policies --user-name ${friendlyname} --profile ${profile} | jq -c '.AttachedPolicies[].PolicyArn' | tr -d '"' | tr -d ' '`
    cloudtrail=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "cloudtrail:DeleteTrail" "cloudtrail:DeleteTrail" "cloudtrail:DeleteTrail" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
    addusers=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "iam:CreateUser" "iam:DeleteUser" "iam:UpdateUser" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
    firewall=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:AuthorizeSecurityGroupEgress" "ec2:AuthorizeSecurityGroupIngress" "ec2:CreateSecurityGroup" "ec2:DeleteSecurityGroup" "ec2:RevokeSecurityGroupEgress" "ec2:RevokeSecurityGroupIngress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
    for policy in $managedpolicies
    do
      parn=`aws iam get-policy --policy-arn ${policy} --profile ${profile} | jq -c '.Policy.Arn' | tr -d '"' | tr -d ' '`
      pversion=`aws iam get-policy --policy-arn ${policy} --profile ${profile} | jq -c '.Policy.DefaultVersionId' | tr -d '"' | tr -d ' '`
      p=`aws iam get-policy-version --policy-arn ${parn} --version-id ${pversion} --profile ${profile} | jq -c '.PolicyVersion.Document.Statement' | tr -d '"' | tr -d ' '`
      csvmanagedpolicy="$csvmanagedpolicy$p"
    done
    echo "$arn,$friendlyname,user,$groupnames,$cloudtrail,$addusers,$firewall,$policynames,\"$csvpolicy\",$managedpolicynames,\"$csvmanagedpolicy\""
  done
  iamgroups=`aws iam list-groups --profile ${profile} | jq -c '.Groups[]'`
  for iamgroup in $iamgroups
  do
    arn=`echo ${iamgroup} | jq -c '.Arn' | tr -d '"'`
    friendlyname=`echo ${iamgroup} | jq -c '.GroupName' | tr -d '"'`
    usernames=`aws iam get-group --group-name $friendlyname --profile ${profile} | jq -c '.Users[].UserName' | tr '"' ' '| tr -d '\n'`
    policynames=`aws iam list-group-policies --group-name ${friendlyname} --profile ${profile} | jq -c '.PolicyNames[]' | tr '"' ' '| tr -d '\n'`
    csvpolicy=""
    policies=`aws iam list-group-policies --group-name ${friendlyname} --profile ${profile} | jq -c '.PolicyNames[]' | tr -d '"' | tr -d ' '`
    for policy in $policies
    do
      p=`aws iam get-group-policy --group-name ${friendlyname} --policy-name ${policy} --profile ${profile} | jq -c '.PolicyDocument.Statement' | tr -d '"' | tr -d ' '`
      csvpolicy="$csvpolicy$p"
    done
    managedpolicynames=`aws iam list-attached-group-policies --group-name ${friendlyname} --profile ${profile} | jq -c '.AttachedPolicies[].PolicyName' | tr '"' ' '| tr -d '\n'`
    csvmanagedpolicy=""
    managedpolicies=`aws iam list-attached-group-policies --group-name ${friendlyname} --profile ${profile} | jq -c '.AttachedPolicies[].PolicyArn' | tr -d '"' | tr -d ' '`
    cloudtrail=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "cloudtrail:DeleteTrail" "cloudtrail:DeleteTrail" "cloudtrail:DeleteTrail" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
    addusers=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "iam:CreateUser" "iam:DeleteUser" "iam:UpdateUser" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
    firewall=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:AuthorizeSecurityGroupEgress" "ec2:AuthorizeSecurityGroupIngress" "ec2:CreateSecurityGroup" "ec2:DeleteSecurityGroup" "ec2:RevokeSecurityGroupEgress" "ec2:RevokeSecurityGroupIngress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
    for policy in $managedpolicies
    do
      parn=`aws iam get-policy --policy-arn ${policy} --profile ${profile} | jq -c '.Policy.Arn' | tr -d '"' | tr -d ' '`
      pversion=`aws iam get-policy --policy-arn ${policy} --profile ${profile} | jq -c '.Policy.DefaultVersionId' | tr -d '"' | tr -d ' '`
      p=`aws iam get-policy-version --policy-arn ${parn} --version-id ${pversion} --profile ${profile} | jq -c '.PolicyVersion.Document.Statement' | tr -d '"' | tr -d ' '`
      csvmanagedpolicy="$csvmanagedpolicy$p"
    done
    echo "$arn,$friendlyname,group,\"$usernames\",$cloudtrail,$addusers,$firewall,$policynames,\"$csvpolicy\",$managedpolicynames,\"$csvmanagedpolicy\""
  done
fi