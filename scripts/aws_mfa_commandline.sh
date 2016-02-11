#!/bin/bash
################################################################################
#
#  Usage:  ./aws_mfa_commandline.sh [profile-name] [region]
#
#  Description:  Easy way to authenticate using a virtual mfa device without
#                having to remember the exact command. Injects temporary
#                credentials into your environment.
#
################################################################################
usage ()
{
  echo "Usage: source $0 [account-id] [username] [token] [duration] [profile-name]"
  echo "  Example Arguments:"
  echo "  ------------------"
  echo "    account-id = 123456789012"
  echo "    username   = justin"
  echo "    token      = 123456"
  echo "    duration   = 3600"
  echo "    profile    = justin (optional)"
}

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
  usage
  exit
else
  account=$1
  username=$2
  token=$3
  duration=$4
fi

if [ -z "$5" ]; then
  aws sts get-session-token --duration-seconds ${duration} --serial-number arn:aws:iam::${account}:mfa/${username} --token-code ${token}  > mfa-user-output.txt
else
  profile=$5
  aws sts get-session-token --duration-seconds ${duration} --serial-number arn:aws:iam::${account}:mfa/${username} --token-code ${token} --profile ${profile}  > mfa-user-output.txt
fi

export AWS_ACCESS_KEY_ID=`cat mfa-user-output.txt | jq -c '.Credentials.AccessKeyId' | tr -d '"' | tr -d ' '`
export AWS_SECRET_ACCESS_KEY=`cat mfa-user-output.txt | jq -c '.Credentials.SecretAccessKey' | tr -d '"' | tr -d ' '`
export AWS_SECURITY_TOKEN=`cat mfa-user-output.txt | jq -c '.Credentials.SessionToken' | tr -d '"' | tr -d ' '`
rm mfa-user-output.txt
