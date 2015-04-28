#!/bin/bash
################################################################################
#
#  Usage:  ./aws_s3MfaDelete_disable.sh [profile] [bucket] [MFA-Serial] [MFA-Token]
#  
#  Arguments:
#    - profile: AWS Profile to use.
#    - region:  AWS region we're targeting.
#    - vpc-id:  The VPC identifier of the VPC you want all your VPCs to be
#               peered with.
#
# Description:  This script takes a VPC ID that you want to enable public ips on
#               by default. If no VPC ID is provide, it will do this to all VPCs
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_s3MfaDelete_disable.sh [profile] [bucket] [MFA-Serial] [MFA-Token]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_s3MfaDelete_disable.sh [profile] [bucket] [MFA-Serial] [MFA-Token]"
  exit
else
  bucket=$2
fi

if [ -z "$3" ]; then
  echo "Usage: ./aws_s3MfaDelete_disable.sh [profile] [bucket] [MFA-Serial] [MFA-Token]"
  exit
else
  serial=$3
fi

if [ -z "$4" ]; then
  echo "Usage: ./aws_s3MfaDelete_disable.sh [profile] [bucket] [MFA-Serial] [MFA-Token]"
  exit
else
  token=$4
fi
echo "Disabling MFA delete on S3 bucket ${bucket}..."
aws s3api put-bucket-versioning --bucket ${bucket} --versioning-configuration MFADelete=Disabled,Status=Enabled --mfa "${serial} ${token}" --profile ${profile}
echo "Done. MFA to delete is diabled, but versioning is still enabled."