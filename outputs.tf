output "bucket_url" {
  value = aws_s3_bucket.webpage_bucket.website_endpoint
}
