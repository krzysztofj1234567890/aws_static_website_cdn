# create S3 bucket
resource "aws_s3_bucket" "tf_bucket" {
    bucket = var.bucket_name
}

# bucket ownership
resource "aws_s3_bucket_ownership_controls" "tf_bucket" {
    bucket = aws_s3_bucket.tf_bucket.id
    rule {
        object_ownership = "BucketOwnerPreferred"
    }
}

# open public access
resource "aws_s3_bucket_public_access_block" "tf_bucket" {
    bucket = aws_s3_bucket.tf_bucket.id
    block_public_acls   = false
    block_public_policy = false
    ignore_public_acls  = false
    restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_access_policy" {
    depends_on = [
        aws_s3_bucket_public_access_block.tf_bucket,
    ]
    bucket = aws_s3_bucket.tf_bucket.id
    policy = jsonencode({
        Version = "2012-10-17",
        Statement = [
            { 
                Sid         = "PublicReadGetObject",
                Effect      = "Allow",
                Principal   = "*",
                Action      = "s3:GetObject",
                Resource    = "${aws_s3_bucket.tf_bucket.arn}/**"
            }
        ]
    })
}

# bucket acl
resource "aws_s3_bucket_acl" "tf_bucket" {
    depends_on = [
        aws_s3_bucket_ownership_controls.tf_bucket,
        aws_s3_bucket_public_access_block.tf_bucket,
    ]
    bucket  = aws_s3_bucket.tf_bucket.id
    acl     = "private"
}

# bucket website configuration
resource "aws_s3_bucket_website_configuration" "tf_bucket" {
    bucket  = aws_s3_bucket.tf_bucket.id
    index_document {
        suffix = "index.html"
    }
    error_document {
        key = "error.html"
    }
}

# CDN
locals {
  s3_origin_id   = "${var.bucket_name}-origin"
  s3_domain_name = "${var.bucket_name}.s3-website-${var.region}.amazonaws.com"
}

resource "aws_cloudfront_distribution" "tf_bucket" {
  enabled = true
  
  origin {
    origin_id                = local.s3_origin_id
    domain_name              = local.s3_domain_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  default_cache_behavior {
    target_origin_id = local.s3_origin_id
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_200"
  
}

# upload files
locals {
  content_types = {
    ".html" : "text/html",
    ".css" : "text/css",
    ".js" : "text/javascript"
  }
}
resource "aws_s3_object" "files" {
   depends_on = [
    aws_s3_bucket_acl.tf_bucket,
    aws_s3_bucket_website_configuration.tf_bucket,
  ]
  for_each     = fileset(path.module, "content/**/*.{html,css,js}")
  bucket       = aws_s3_bucket.tf_bucket.id
  key          = replace(each.value, "/^content//", "")
  source       = each.value
  #    acl     = "public-read"
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
  source_hash  = filemd5(each.value)
}

# upload index.html
#resource "aws_s3_object" "file-index" {
#    depends_on = [
#        aws_s3_bucket_acl.tf_bucket,
#        aws_s3_bucket_website_configuration.tf_bucket,
#    ]
#    bucket  = aws_s3_bucket.tf_bucket.id
#    key     = "index.html"
#    source  = "index.html"
#    acl     = "public-read"
#    content_type    = "text/html"
#}

# upload error.html
#resource "aws_s3_object" "file-error" {
#    depends_on = [
#        aws_s3_bucket_acl.tf_bucket,
#        aws_s3_bucket_website_configuration.tf_bucket,
#    ]
#    bucket  = aws_s3_bucket.tf_bucket.id
#    key     = "error.html"
#    source  = "error.html"
#    acl     = "public-read"
#    content_type    = "text/html"
#}