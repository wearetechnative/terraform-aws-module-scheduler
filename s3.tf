
resource "aws_s3_bucket" "webpage_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "index.html"
  source = templatefile("${path.module}/html/index.html.tftpl")
  content_type = "text/html"
  etag = filemd5("${path.module}/html/index.html")

}

resource "aws_s3_bucket_object" "object2" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "periods.html"
  source = "${path.module}/html/periods.html"
  content_type = "text/html"
  etag = filemd5("${path.module}/html/periods.html")

}
resource "aws_s3_bucket_object" "object3" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "schedules.html"
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