resource "aws_s3_bucket" "this" {
  bucket        = var.bucket
  force_destroy = true
}

resource "aws_s3_bucket_acl" "this" {
  count = var.is_public_read ? 1 : 0

  bucket = aws_s3_bucket.this.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "this" {
  count = var.is_website ? 1 : 0

  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_policy" "this" {
  count = var.is_public_read ? 1 : 0

  bucket = aws_s3_bucket.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.this.arn}/*"]
      }
    ]
  })
}

output "id" {
  value = aws_s3_bucket.this.id
}

output "arn" {
  value = aws_s3_bucket.this.arn
}

output "regional_domain_name" {
  value = aws_s3_bucket.this.bucket_regional_domain_name
}

output "website_endpoint" {
  value = aws_s3_bucket.this.website_endpoint
}
