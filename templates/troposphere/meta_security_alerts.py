#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys, getopt, csv
from troposphere import GetAtt, Output, Parameter, Ref, Template
from troposphere.cloudwatch import Alarm


def main(argv):
    FILE = None
    try:
        opts, args = getopt.getopt(argv,"hf:",["FILE="])
    except getopt.GetoptError:
        print sys.argv[0], ' -f <metric-csv-file>' 
        sys.exit(2)

    # An array to contain any parameters for the template.
    parameters = []
    # An array to contain any conditions for the template.
    conditions = {}
    # An array to contain any key value maps for the template.
    maps = []
    # An array to contain any resource objects for the template.
    resources = []
    # An array to contain any output objects for the template.
    outputs = []

    with open(FILE, 'rbU') as f:
        reader = csv.reader(f)
        try:
            for row in islice(reader, 1, None):
                resources.append(Alarm(
                    "QueueDepthAlarm",
                    AlarmDescription="Alarm if queue depth grows beyond 10 messages",
                    Namespace="AWS/SQS",
                    MetricName="ApproximateNumberOfMessagesVisible",
                    Dimensions=[
                        MetricDimension(
                            Name="QueueName",
                            Value=GetAtt(myqueue, "QueueName")
                        ),
                    ],
                    Statistic="Sum",
                    Period="300",
                    EvaluationPeriods="1",
                    Threshold="10",
                    ComparisonOperator="GreaterThanThreshold",
                    AlarmActions=[Ref(alarmtopic), ],
                    InsufficientDataActions=[Ref(alarmtopic), ],
                ))
        except csv.Error as e:
            sys.exit('file %s, line %d: %s' % (VPC_ID, reader.line_num, e))

    t = Template()
    t.add_version('2010-09-09')
    t.add_description(
        "This is an AWS CloudFormation template that provisions metric filters "
        "based on a spreadsheet of applicable metric filters. ***WARNING*** This "
        "template creates many Amazon CloudWatch alarms based on a Amazon "
        "CloudWatch Logs Log Group. You will be billed for the AWS resources used "
        "if you create a stack from this template."
    )
    for p in parameters:
        t.add_parameter(p)
    for k in conditions:
        t.add_condition(k, conditions[k])
    for r in resources:
        t.add_resource(r)
    for o in outputs:
        t.add_output(o)

    # Print the template to JSON
    print(t.to_json())

if __name__ == "__main__":
   main(sys.argv[1:])