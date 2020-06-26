# #########################################
# Cloudtrail
# #########################################
resource "aws_cloudtrail" "cloudtrail" {
  count                         = local.enable_cloudtrail_count
  enable_log_file_validation    = true
  include_global_service_events = true
  is_multi_region_trail         = true
  name                          = format("%s-cloudtrail", module.labels.id)
  s3_bucket_name                = aws_s3_bucket.cloudtrail[0].id
  tags                          = module.labels.tags
}

resource "aws_s3_bucket" "cloudtrail" {
  count  = local.enable_cloudtrail_count
  bucket = local.cloudtrail_s3_bucket_name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "s3:GetBucketAcl",
      "Effect": "Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Resource": "arn:aws:s3:::${local.cloudtrail_s3_bucket_name}",
      "Sid": "AWSCloudTrailAclCheck"
    },
    {
      "Action": "s3:PutObject",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      },
      "Effect": "Allow",
      "Principal": { "Service": "cloudtrail.amazonaws.com" },
      "Resource": "arn:aws:s3:::${local.cloudtrail_s3_bucket_name}/*",
      "Sid": "AWSCloudTrailWrite"
    }
  ]
}
EOF

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "default" {
  count                   = local.enable_cloudtrail_count
  bucket                  = aws_s3_bucket.cloudtrail[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
