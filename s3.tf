
resource "aws_s3_bucket" "webpage_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "index.html"
  source = "./index.html"
  content_type = "text/html"
  etag = filemd5("./index.html")

}

resource "aws_s3_bucket_object" "object2" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "periods"
  source = "./periods.html"
  content_type = "text/html"
  etag = filemd5("./periods.html")

}
resource "aws_s3_bucket_object" "object3" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "schedules"
  source = "./schedules.html"
  content_type = "text/html"
  etag = filemd5("./schedules.html")

}

resource "aws_s3_bucket_website_configuration" "website_conf" {
  bucket = aws_s3_bucket.webpage_bucket.id

  index_document {
    suffix = "index.html"
  }

  
}