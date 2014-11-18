AWS CloudFormation Templates
============================

A basic repository containing various CloudFormation templates that are
used internally by my Jenkins servers to launch, update, and maintain various
peices of my infrastructure. Jenkins is needed to bridge the automation gap
for peices that CloudFormation misses. Alternative suggestions welcome! I'm
always looking for ways to improve.

`./foxcorporations/frontend.json`

Creates an S3 bucket for holding website resources. Then creates a
CloudFront distribution to serve content for multiple specified aliases.
When the stack is up and running, verify correctness and update DNS.

`./foxcorporations/api-nodes.json`

Creates a regional VPC based on your input parameter, with a subnet per
availability zone. Each subnet is associated with a created InternetGateway
and PublicRoute. An EC2 AutoScalingGroup is created to automatically create
or recreate instances. And part of the launch and update process, the EC2
instances will reclone the appropriate git project and restart the api
application. When the stack is up and running, verify correctness and update
DNS.
