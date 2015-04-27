#!/bin/bash
################################################################################
#
#  Usage:  ./aws_bs_saltstack.sh [ec2tag]
#
# Description:  This script runs from a local instance and processes the
#               instances tags. Be default this queries for a tag with a key
#               value of userdata and parses it.
#
#               This script assumes the usage of IAM profiles and drops the
#               "--profile [name]" flag.
#
################################################################################

# Load some basic information about this instance.
EC2_INSTANCE_ID="`curl -s http://169.254.169.254/latest/meta-data/instance-id`"
EC2_AVAIL_ZONE="`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`"
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"

# Store tag based JSON formatted userdata.
# { "salt" : { "minion_id" : ".node.example.com", "roles"     : ["fer"], "bucket"    : "[prefix]-salt-cm" } }
userdata=`aws ec2 describe-tags --filters "Name=resource-id,Values=${EC2_INSTANCE_ID}" "Name=key,Values=userdata" --region ${EC2_REGION} | jq -c '.Tags[].Value'`
roles=`echo ${userdata}| sed 's:^.\(.*\).$:\1:' | tr -d '\\' | jq -c '.salt.roles[]' | tr -d '"' | tr -d ' '`
bucket=`echo ${userdata}| sed 's:^.\(.*\).$:\1:' | tr -d '\\' | jq -c '.salt.bucket' | tr -d '"' | tr -d ' '`

# One liner to install the salt minion (or better, host the minion rpm in your
# S3 bucket!)
#if [ ! -f /usr/bin/salt-minion ]; then
    wget -O - https://bootstrap.saltstack.com | sudo sh
#fi
service salt-minion stop
chkconfig salt-minion off

echo $EC2_INSTANCE_ID > /etc/salt/minion_id

echo "" > /etc/salt/minion
echo "file_client: local" >> /etc/salt/minion
echo "mine_functions:" >> /etc/salt/minion
echo "  network.ip_addrs: []" >> /etc/salt/minion
echo "  network.ip_addrs:" >> /etc/salt/minion
echo "    - eth0" >> /etc/salt/minion
echo "grains:" >> /etc/salt/minion
echo "  roles:" >> /etc/salt/minion
echo "    - All" >> /etc/salt/minion

for role in $roles
do
    echo "    - ${role}" >> /etc/salt/minion
done

# Add a cron job that runs an S3 sync command every 5 mins
echo "*/5 * * * * aws s3 sync s3://${bucket} /" > /etc/cron.d/aws_bs_saltsync

# Add a cron job that runs the salt-call command every 15 mins
echo "*/15 * * * * salt-call --local state.highstate" > /etc/cron.d/aws_bs_saltcall