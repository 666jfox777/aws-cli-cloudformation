#!/bin/bash
################################################################################
#
#  Usage:  ./aws_s3_configuration.sh [profile]
#  
#  Arguments:
#    - profile: AWS Profile to use.
#
# Description: 
#
################################################################################
usage ()
{
  echo "Usage: $0 [profile] > output.csv"
}

if [ -z "$1" ]; then
  usage
  exit
else
  profile=$1
fi

# Print column headers
echo "S3 Bucket Name, S3 Bucket ARN, Region, Logs To, Versioning Status, MFA to Delete, Bucket Replicated, Life Cycle Status, Life Cycle Rules"

s3buckets=`aws s3api list-buckets --profile ${profile} | jq -c '.Buckets[].Name' | tr -d '"' | tr -d ' '`

for s3bucket in $s3buckets
  do
  arn="arn:aws:s3:::$s3bucket"
  region=`aws s3api get-bucket-location --bucket ${s3bucket} --profile ${profile} | jq -c '.LocationConstraint' | tr -d '"' | tr -d ' '`
  if [ "$region" == "null" ]; then
    region="us-east-1"
  fi
  logging=`aws s3api get-bucket-logging --bucket ${s3bucket} --profile ${profile} | jq -c '.LoggingEnabled.TargetBucket' | tr -d '"' | tr -d ' '`
  versioning=`aws s3api get-bucket-versioning --bucket ${s3bucket} --profile ${profile} | jq -c '.Status' | tr -d '"' | tr -d ' '`
  if [ -z "$versioning" ]; then
    versioning="Not Enabled"
  fi
  mfadelete=`aws s3api get-bucket-versioning --bucket ${s3bucket} --profile ${profile} | jq -c '.MFADelete' | tr -d '"' | tr -d ' '`
  if [ "$mfadelete" == "null" ] || [ -z "$mfadelete" ]; then
    mfadelete="Not Enabled"
  fi
  replication=`aws s3api get-bucket-replication --bucket ${s3bucket} --profile ${profile} 2> /dev/null | jq -c '.ReplicationConfiguration.Rules[].Destination.Bucket' | tr '"' ' '| tr -d '\n'`
  if [ -z "$replication" ]; then
    replication="Not Enabled"
  fi
  lifecycle=`aws s3api get-bucket-lifecycle --bucket ${s3bucket} --profile ${profile} 2> /dev/null`
  if [ -z "$lifecycle" ]; then
    lifecycle="Not Enabled"
    lifecyclerules="Not Enabled"
  else
    lifecycle="Enabled"
    lifecyclerules=`aws s3api get-bucket-lifecycle --bucket ${s3bucket} --profile ${profile} | jq -c '.Rules[].Transition' | tr '"' ' ' | tr ',' '+' | tr -d '\n'`
  fi

  echo "$s3bucket,$arn,$region,$logging,$versioning,$mfadelete,$replication,$lifecycle,$lifecyclerules"
done
