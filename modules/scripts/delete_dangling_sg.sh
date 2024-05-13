#!/bin/sh

set -e

query_dangling_vpc_sg() {
  aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$1" --profile $2 | jq -r '.SecurityGroups[] | select (.GroupName != "default") | .GroupId'
}

delete_security_group() {
  echo "aws ec2 delete-security-group --group-id $1 --profile $2"
  aws ec2 delete-security-group --group-id $1 --profile $2
}

echo "Initiating dangling cleanup.\nDeleting VPC sg."
query_dangling_vpc_sg $1 $2 | while read sg; do
  delete_security_group $sg $2
done

