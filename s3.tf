
resource "aws_s3_bucket" "webpage_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "index.html"
  source = "${path.module}/html/index.html"
  content_type = "text/html"
  etag = filemd5("${path.module}/html/index.html")

}

resource "aws_s3_bucket_object" "object2" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "periods"
  source = "${path.module}/html/periods.html"
  content_type = "text/html"
  etag = filemd5("${path.module}/html/periods.html")

}
resource "aws_s3_bucket_object" "object3" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "schedules"
  source = "${path.module}/html/schedules.html"
  content_type = "text/html"
  etag = filemd5("${path.module}/html/schedules.html")

}

resource "aws_s3_bucket_website_configuration" "website_conf" {
  bucket = aws_s3_bucket.webpage_bucket.id

  index_document {
    suffix = "index.html"
  }

  
}