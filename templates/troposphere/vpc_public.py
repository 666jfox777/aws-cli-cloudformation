#!/usr/bin/python
# -*- coding: utf-8 -*-

# Import libraries
from troposphere import *
from troposphere.ec2 import *

# An array to contain any parameters for the template.
parameters = [
    Parameter(
        "VPCCIDR",
        Description    = "The IP Address space used by this VPC. Changing the CIDR issues a replacement of the stack.",
        Type           = "String",
        Default        = "10.0.0.0/16",
        AllowedPattern = "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
    ),
    Parameter(
        "VPCName",
        Description    = "The name of this VPC. Useful for distinguishing different VPCs.",
        Type           = "String",
        Default        = "Basic VPC"
    )
]

# Append the required number of subnet parameters
i = 0
while i < 3:
    parameters.append(
        Parameter(
            "PublicSubnet"+ str(i + 1) +"CIDR",
            Description    = "The IP Address space used by this subnet. Changing the CIDR issues a replacement of the stack.",
            Type           = "String",
            Default        = "10.0.2.0/24",
            AllowedPattern = "(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})"
        )
    )
    parameters.append(
        Parameter(
            "PublicSubnet"+ str(i + 1) +"AZ",
            Description   = "The availaibility zone to place this subnet in. Changing the AZ issues a replacement of the stack.",
            Type          = "String",
            Default       = "us-east-1b",
            AllowedValues = ["us-east-1a","us-east-1b","us-east-1c","us-east-1e","us-west-2a","us-west-2b","us-west-2c"]
        )
    )
    i += 1

# An array to contain any conditions for the template
conditions     = {}

ref_stack_id   = Ref('AWS::StackId')
ref_region     = Ref('AWS::Region')
ref_stack_name = Ref('AWS::StackName')

# An array to contain any resource objects for the template.
resources = [
    VPC(
        'VPC',
        CidrBlock            = Ref('VPCCIDR'),
        Tags                 = Tags(Name=Ref('VPCName')),
        EnableDnsSupport     = 'true',
        EnableDnsHostnames   = 'true'
    ),
    InternetGateway(
        'InternetGateway',
        Tags                 = Tags(Name=Ref('VPCName'))
    ),
    VPCGatewayAttachment(
        'AttachGateway',
        VpcId                = Ref('VPC'),
        InternetGatewayId    = Ref('InternetGateway')
    ),
    RouteTable(
        'PublicRouteTable',
        VpcId                = Ref('VPC')
    ),
    Route(
        'PublicRoute',
        DependsOn            = 'AttachGateway',
        GatewayId            = Ref('InternetGateway'),
        DestinationCidrBlock = '0.0.0.0/0',
        RouteTableId         = Ref('PublicRouteTable')
    ),
    NetworkAcl(
        'PublicSubnetAcl',
        VpcId                = Ref('VPC')
    ),
    NetworkAclEntry(
        'PublicInSubnetAclEntry',
        NetworkAclId         = Ref('PublicSubnetAcl'),
        RuleNumber           = '32000',
        Protocol             = '-1',
        PortRange            = PortRange(To='80', From='80'),
        Egress               = 'false',
        RuleAction           = 'allow',
        CidrBlock            = '0.0.0.0/0'
    ),
    NetworkAclEntry(
        'PublicOutSubnetAclEntry',
        NetworkAclId         = Ref('PublicSubnetAcl'),
        RuleNumber           = '32000',
        Protocol             = '-1',
        PortRange            = PortRange(To='1', From='65535'),
        Egress               = 'true',
        RuleAction           = 'allow',
        CidrBlock            = '0.0.0.0/0'
    )
]

# Append the required number of subnet resources
i = 0
while i < 3:
    resources.append(
        Subnet(
            'PublicSubnet' + str(i + 1),
            CidrBlock      = '10.0.0.0/24',
            VpcId          = Ref('VPC'),
            Tags           = Tags(Application=ref_stack_id)
        )
    )
    resources.append(
        SubnetRouteTableAssociation(
            'Subnet' + str(i + 1) + 'RouteTableAssociation',
            SubnetId      = Ref('PublicSubnet' + str(i + 1)),
            RouteTableId  = Ref('PublicRouteTable')
        )
    )
    resources.append(
        SubnetNetworkAclAssociation(
            'Subnet' + str(i + 1) + 'NetworkAclAssociation',
            SubnetId      = Ref('PublicSubnet' + str(i + 1)),
            NetworkAclId  = Ref('PublicSubnetAcl')
        )
    )
    i += 1


# An array to contain any output objects for the template.
outputs = [
    Output(
        "VPC",
        Value       = Ref('VPC'),
        Description = ""
    ),
    Output(
        "PublicRouteTable",
        Value       = Ref('PublicRouteTable'),
        Description = ""
    )
]

# Append the required number of subnet parameters
i = 0
while i < 3:
    outputs.append(
        Output(
            "Subnet"+ str(i + 1) + "ID",
            Value       = Ref("PublicSubnet"+ str(i + 1)),
            Description = ""
        )
    )
    outputs.append(
        Output(
            "Subnet"+ str(i + 1) + "AZ",
            Value       = Ref("PublicSubnet"+ str(i + 1) +"AZ"),
            Description = ""
        )
    )
    i += 1

# Build the template
t = Template()
t.add_version('2010-09-09')
t.add_description("This CloudFormation template provisions a standard VPC with 3 subnets across 3 Availability Zones. All 3 are public.")
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
