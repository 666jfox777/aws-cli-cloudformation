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
usage ()
{
  echo "Usage: $0 [profile-name] > output.csv"
}
if [ -z "$1" ]; then
  usage
  exit
else
  profile=$1
fi

echo "ARN,FriendlyName,Type,Memberships,cloudtrail:DeleteTrail,iam:CreateUser,iam:DeleteUser,iam:UpdateUser,ec2:AuthorizeSecurityGroupEgress,ec2:AuthorizeSecurityGroupIngress,ec2:CreateSecurityGroup,ec2:DeleteSecurityGroup,ec2:RevokeSecurityGroupEgress,ec2:RevokeSecurityGroupIngress,InlinePolicies,InlinePoliciesExpanded,ManagedPolicies,ManagedPoliciesExpanded"
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
  cloudtrail=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "cloudtrail:DeleteTrail" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  CreateUser=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "iam:CreateUser" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  DeleteUser=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "iam:DeleteUser" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  UpdateUser=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "iam:UpdateUser" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  AuthorizeSecurityGroupEgress=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:AuthorizeSecurityGroupEgress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  AuthorizeSecurityGroupIngress=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:AuthorizeSecurityGroupIngress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  CreateSecurityGroup=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:CreateSecurityGroup" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  DeleteSecurityGroup=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:DeleteSecurityGroup" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  RevokeSecurityGroupEgress=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:RevokeSecurityGroupEgress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  RevokeSecurityGroupIngress=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:RevokeSecurityGroupIngress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  for policy in $managedpolicies
  do
    parn=`aws iam get-policy --policy-arn ${policy} --profile ${profile} | jq -c '.Policy.Arn' | tr -d '"' | tr -d ' '`
    pversion=`aws iam get-policy --policy-arn ${policy} --profile ${profile} | jq -c '.Policy.DefaultVersionId' | tr -d '"' | tr -d ' '`
    p=`aws iam get-policy-version --policy-arn ${parn} --version-id ${pversion} --profile ${profile} | jq -c '.PolicyVersion.Document.Statement' | tr -d '"' | tr -d ' '`
    csvmanagedpolicy="$csvmanagedpolicy$p"
  done
  echo "$arn,$friendlyname,user,$groupnames,$cloudtrail,$CreateUser,$DeleteUser,$UpdateUser,$AuthorizeSecurityGroupEgress,$AuthorizeSecurityGroupIngress,$CreateSecurityGroup,$DeleteSecurityGroup,$RevokeSecurityGroupEgress,$RevokeSecurityGroupIngress,$policynames,\"$csvpolicy\",$managedpolicynames,\"$csvmanagedpolicy\""
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
  cloudtrail=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "cloudtrail:DeleteTrail" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  CreateUser=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "iam:CreateUser" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  DeleteUser=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "iam:DeleteUser" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  UpdateUser=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "iam:UpdateUser" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  AuthorizeSecurityGroupEgress=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:AuthorizeSecurityGroupEgress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  AuthorizeSecurityGroupIngress=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:AuthorizeSecurityGroupIngress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  CreateSecurityGroup=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:CreateSecurityGroup" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  DeleteSecurityGroup=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:DeleteSecurityGroup" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  RevokeSecurityGroupEgress=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:RevokeSecurityGroupEgress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  RevokeSecurityGroupIngress=`aws iam simulate-principal-policy --policy-source-arn ${arn} --action-names "ec2:RevokeSecurityGroupIngress" --profile ${profile} | jq -c '.EvaluationResults[].EvalDecision' | tr '"' ' '| tr -d '\n'`
  for policy in $managedpolicies
  do
    parn=`aws iam get-policy --policy-arn ${policy} --profile ${profile} | jq -c '.Policy.Arn' | tr -d '"' | tr -d ' '`
    pversion=`aws iam get-policy --policy-arn ${policy} --profile ${profile} | jq -c '.Policy.DefaultVersionId' | tr -d '"' | tr -d ' '`
    p=`aws iam get-policy-version --policy-arn ${parn} --version-id ${pversion} --profile ${profile} | jq -c '.PolicyVersion.Document.Statement' | tr -d '"' | tr -d ' '`
    csvmanagedpolicy="$csvmanagedpolicy$p"
  done
  echo "$arn,$friendlyname,group,\"$usernames\",$cloudtrail,$CreateUser,$DeleteUser,$UpdateUser,$AuthorizeSecurityGroupEgress,$AuthorizeSecurityGroupIngress,$CreateSecurityGroup,$DeleteSecurityGroup,$RevokeSecurityGroupEgress,$RevokeSecurityGroupIngress,$policynames,\"$csvpolicy\",$managedpolicynames,\"$csvmanagedpolicy\""
done