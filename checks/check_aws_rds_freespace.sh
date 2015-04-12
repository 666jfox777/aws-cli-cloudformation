#!/bin/bash
################################################################################
#
#  Usage:  ./check_aws_rds_freespace.sh [db name]
#  
#  Arguments:
#    - db name: The AWS RDS database name to use.
#
################################################################################

if [ -z "$1" ]; then
  echo "Usage:  ./check_aws_rds_freespace.sh [db name]"
  exit
else
  db=$1
fi

aws cloudwatch get-metric-statistics --metric-name FreeStorageSpace --period 60 --start-time `date -u --date 'now -5 mins' '+%FT%T'` --end-time `date -u '+%FT%T'` --namespace "AWS/RDS" --dimensions="Name=DBInstanceIdentifier,Value=${db}" --statistics Average