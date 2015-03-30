# Enable classiclink on a vpc
aws ec2 enable-vpc-classic-link --vpc-id [vpc-id] --profile [name]

# Activate classiclink on all instances... Note this will show errors for instances in a VPC.
instances=`aws ec2 describe-instances --profile [name] --region [region] | jq -c '.Reservations[].Instances[].InstanceId' | tr -d '"' | tr -d ' '`
for instance in $instances
do
  echo "Attempting to intitialize ClassicLink for ${instance}"
  aws ec2 attach-classic-link-vpc --instance-id ${instance} --vpc-id [vpc-id] --groups [vpc-sg] --profile [name] --region [region]
done
