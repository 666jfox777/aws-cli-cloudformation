# Enable auto-assignment of a public ip to all vpc subnets
# You can tag on a filter to these:
#
#    --filters "Name=vpc-id,Values=vpc-a01106c2"
#
# Otherwise this will do ALL subnets. You can also inverse this with: --no-map-public-ip-on-launch

subnets=`aws ec2 describe-subnets --profile [name] --region [region] | jq -c '.Subnets[].SubnetId' | tr -d '"' | tr -d ' '`

for subnet in $subnets
do
  echo "Attempting to map-public-ip-on-launch for subnet ${subnet}"
  aws ec2 modify-subnet-attribute --subnet-id ${subnet} --map-public-ip-on-launch --profile [name] --region [region]
done
