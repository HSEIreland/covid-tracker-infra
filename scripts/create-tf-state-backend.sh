#!/bin/bash
# Assumes you have already configured AWS_PROFILE
# Being optimistic that the S3 bucket is available
# Usage is
#	./create-tf-state-backend.sh eu-west-1 cti-dev-terraform-store cti-dev-terraform-lock
#	./create-tf-state-backend.sh eu-west-2 cti-prod-terraform-store cti-prod-terraform-lock
#
set -eou pipefail
: ${1?AWS region is required} 
: ${2?S3 bucket name is required} 
: ${3?DynamoDB table name is required} 

aws_region=${1}
s3_bucket_name=${2}
dynamodb_table_name=${3}


# Get account ARN and create a policy doc
# PENDING This should be for an AWS group
user_arn=$(aws sts get-caller-identity | jq -r .Arn)
cat > /tmp/policy.json <<EOF
{
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${user_arn}"
            },
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${s3_bucket_name}"
        }
    ]
}
EOF


# S3 bucket
# Create bucket
aws s3api create-bucket --bucket ${s3_bucket_name} \
    --region ${aws_region} \
    --create-bucket-configuration LocationConstraint=${aws_region}
# Encrypt bucket
aws s3api put-bucket-encryption \
    --bucket ${s3_bucket_name} \
    --server-side-encryption-configuration='{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
# Apply policy
aws s3api put-bucket-policy --bucket ${s3_bucket_name} --policy file:///tmp/policy.json
# Apply versioning
aws s3api put-bucket-versioning --bucket ${s3_bucket_name} --versioning-configuration Status=Enabled
# Apply block public access config
aws s3api put-public-access-block \
    --bucket ${s3_bucket_name} \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \


# DynamoDb table
aws dynamodb create-table \
    --table-name ${dynamodb_table_name} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
