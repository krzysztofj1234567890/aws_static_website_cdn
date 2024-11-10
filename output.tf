output "s3_url" {
  value = "http://${aws_s3_bucket.tf_bucket.bucket}.s3-website.${var.region}.amazonaws.com"
}

output "cloudfront_website_url" {
  value = try(aws_cloudfront_distribution.tf_bucket.domain_name, "")
}
