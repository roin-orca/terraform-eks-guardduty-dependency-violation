#!/bin/sh

set -e

query_dangling_vpc_endpoint() {
  aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=$1" --profile $2 | jq -r '.VpcEndpoints[].VpcEndpointId'
}

delete_vpc_endpoint() {
  echo "aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $1 --profile $2"
  aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $1 --profile $2
}

echo "Initiating dangling cleanup.\nDeleting VPC endpoints."
query_dangling_vpc_endpoint $1 $2 | while read endpoint; do
  delete_vpc_endpoint $endpoint $2
done

