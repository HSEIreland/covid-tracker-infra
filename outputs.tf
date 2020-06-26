output "key" {
  value = aws_iam_access_key.ci_user.id
}

output "secret" {
  value = aws_iam_access_key.ci_user.secret
}

output "push_aws_dns" {
  value = aws_lb.push.dns_name
}

output "api_aws_dns" {
  value = join("", aws_api_gateway_domain_name.main.*.cloudfront_domain_name)
}
