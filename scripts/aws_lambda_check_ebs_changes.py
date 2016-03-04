#!/usr/bin/env python
################################################################################
#                                                                              #
#  check_ebs_changes                                                           #
#  -----------------                                                           #
#  This script makes use of the EC2, SimpleDB, and SNS APIs to track and alert #
#  on EBS volume changes within a region.                                      #
#                                                                              #
#  You can schedule this check with CloudWatch Events & Lambda.                #
#                                                                              #
################################################################################
from __future__ import print_function
import json
import boto3

# User configured settings
aws_sdb_name    = "ebs"
aws_sns_topic   = "arn:aws:sns:us-west-2:123456789012:ebs-volumes"
aws_sns_subject = "EBS Volumes Report: Volume Changes"

# lambda_function.handler
# -----------------------
# This is the function that will be triggered by AWS Lambda. When defining your
# Lambda function ensure the handler is set correctly.
def handler(event, context):
    # Log the request, for troubleshooting
    #print("Received event: " + json.dumps(event, indent=2))
    #print("Context event: " + json.dumps(context, indent=2))
    
    # Start building our message.
    aws_sns_message = "Missing EBS:\n"

    # Connect to the AWS SimpleDB service. We're going to request a list of
    # volume ids.
    print('Connecting to SimpleDB.')
    sdb = boto3.client('sdb')

    # Get a list of currently existing SimpleDBs and test to see if ours is 
    # there.
    aws_sdb_exists = False
    print('Getting a list of SimpleDB.')
    domains = sdb.list_domains()
    for domain in domains:
        if domain == aws_sdb_name:
            aws_sdb_exists = True

    # If the SimpleDB does not yet exist, create the database.
    if aws_sdb_exists is False:
        try:
            print('Creating a SimpleDB named ' + aws_sdb_name + ' as one does not exist!')
            response = sdb.create_domain(DomainName=aws_sdb_name)
        except Exception as e:
            print(e)
            print('Exception: Error sending creating SimpleDB domain.')
            raise e

    # Get a list of SimpleDB entries.
    query = 'select * from `' + aws_sdb_name + '`'
    print('Query: ' + query)
    aws_sdb_volumes = sdb.select(SelectExpression=query)['Items']
    aws_sdb_recorded = [];
    for volume in aws_sdb_volumes:
        aws_sdb_recorded.append(volume['Name']);

    # Connect to the AWS EC2 service. We're going to request a current list of
    # volumes.
    ec2 = boto3.client('ec2')
    aws_ec2_volumes = ec2.describe_volumes()['Volumes']
    aws_ec2_list = []
    for volume in aws_ec2_volumes:
        aws_ec2_list.append(volume['VolumeId'])
        # Compare to list in SimpleDB
        if volume['VolumeId'] not in aws_sdb_recorded:
            print('Missing volume ' + volume['VolumeId'] + ' is not in SimpleDB.')
            aws_sns_message += '- ' + volume['VolumeId'] + '\n'

    # Update our SimpleDB database by iterating through the existing records and
    # comparing them to a list of records from EC2.
    for volume in aws_sdb_recorded:
        if volume not in aws_ec2_list:
            print('Update: Deleting ' + volume + ' from SimpleDB named ' + aws_sdb_name)
            sdb.delete_attributes(DomainName=aws_sdb_name, ItemName=volume)

    # Update our SimpleDB database by iterating through the records from the EC2
    # service and update/insert the record into SimpleDB.
    for volume in aws_ec2_volumes:
        print('Update: Calling update/insert on ' + volume['VolumeId'] + ' into SimpleDB named ' + aws_sdb_name)
        sdb.put_attributes(DomainName=aws_sdb_name, ItemName=volume['VolumeId'],Attributes=[{ 'Name': 'VolumeId', 'Value': volume['VolumeId'], 'Replace': True }])

    # Connect to the AWS SNS service. We're going to publish a SNS message in
    # order to generate the email.
    sns = boto3.client('sns')

    # Attempt to send the SNS notification. Raise an exception if it fails.
    try:
        email = sns.publish(
            TopicArn=aws_sns_topic,
            Message=aws_sns_message,
            Subject=aws_sns_subject
        )
        print('Email sent!')
        return email
    except Exception as e:
        print(e)
        print('Exception: Error sending SNS topic.')
        raise e