#!/bin/bash
################################################################################
#
#  Usage:  ./aws_peerallvpctovpc.sh [profile-name] [region] [vpc-id]
#  
#  Arguments:
#    - vpc-id: The VPC identifier of the VPC you want all your VPCs to be
#              peered with.
#
# Description:  This script takes a VPC ID that you want everything to be
#               peered to, and peers all your VPCs to it, and creates the
#               appropriate routes in all of the route tables.
#
#  Use Case:    I used this when migrating an older AWS account from EC2
#               Classic into a bunch of isolated VPCs. Because of the
#               desired isolated VPC design they wanted classic instances
#               first needed to be classic linked into a transitionary VPC.
#               Everything was then moved into the transitionary VPC and the
#               isolated VPCs were spawned. The transitionary VPC then needed
#               to be quickly peered with everything.
#
################################################################################
if [ -z "$1" ]; then
  echo "Usage: ./aws_peerallvpctovpc.sh [profile-name] [region] [vpc-id]"
  exit
else
  profile=$1
fi

if [ -z "$2" ]; then
  echo "Usage: ./aws_peerallvpctovpc.sh [profile-name] [region] [vpc-id]"
  exit
else
  region=$2
fi

# Check the command line parameters for a vpc-id.
if [ -z "$3" ]; then
  echo "Usage: ./aws_peerallvpctovpc.sh [profile-name] [region] [vpc-id]"
  exit
else
  trans=$3
fi

# Get a nicely trimmed list of vpc-ids.
vpcs=`aws ec2 describe-vpcs --profile ${profile} --region ${region} | jq -c '.Vpcs[].VpcId' | tr -d '"' | tr -d ' '`

# For each VPC create the peering connection and required routes.
for vpc in $vpcs
do

  # Create the peering connection request and store the peering connection id.
  conn=`aws ec2 create-vpc-peering-connection --vpc-id ${trans} --peer-vpc-id ${vpc} --profile ${profile} --region ${region} | jq -c '.VpcPeeringConnection.VpcPeeringConnectionId' | tr -d '"' | tr -d ' '`
  
  # Accept the peering connection request.
  aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id ${conn} --profile ${profile} --region ${region}
  
  # Look at all of the current VPC route tables...
  routetables=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=${vpc} --profile ${profile} --region ${region} | jq -c '.RouteTables[].RouteTableId' | tr -d '"' | tr -d ' '`
  
  # For each route table...
  for table in $routetables
  do
  
    # Add required routes!
    aws ec2 create-route --route-table-id ${table} --destination-cidr-block `aws ec2 describe-vpcs --vpc-ids ${trans} --profile ${profile} --region ${region} | jq -c '.Vpcs[].CidrBlock' | tr -d '"' | tr -d ' '` --vpc-peering-connection-id ${conn} --profile ${profile} --region ${region}
    
  done
  
  # Add the routes to the transitionary vpc as well!
  routetables=`aws ec2 describe-route-tables --filters Name=vpc-id,Values=${trans} --profile ${profile} --region ${region} | jq -c '.RouteTables[].RouteTableId' | tr -d '"' | tr -d ' '`
  
  # For each transitionary route table...
  for table in $routetables
  do
  
    # Add the route!
    aws ec2 create-route --route-table-id ${table} --destination-cidr-block `aws ec2 describe-vpcs --vpc-ids ${vpc} --profile ${profile} --region ${region} | jq -c '.Vpcs[].CidrBlock' | tr -d '"' | tr -d ' '` --vpc-peering-connection-id ${conn} --profile ${profile} --region ${region}
    
  done
  
done
