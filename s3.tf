
resource "aws_s3_bucket" "webpage_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "index.html"
  content = templatefile("${path.module}/html/index.html.tftpl", {bucket_url = aws_s3_bucket.webpage_bucket.website_endpoint})
  content_type = "text/html"
  etag = filemd5("${path.module}/html/index.html.tftpl")

}

resource "aws_s3_bucket_object" "object2" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "periods.html"
  content = templatefile("${path.module}/html/periods.html.tftpl", {api_url = aws_apigatewayv2_api.my_api.api_endpoint})
  content_type = "text/html"
  etag = filemd5("${path.module}/html/periods.html.tftpl")

}
resource "aws_s3_bucket_object" "object3" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "schedules.html"
  content = templatefile("${path.module}/html/schedules.html.tftpl", {api_url = aws_apigatewayv2_api.my_api.api_endpoint})
  content_type = "text/html"
  etag = filemd5("${path.module}/html/schedules.html.tftpl")

}

resource "aws_s3_bucket_website_configuration" "website_conf" {
  bucket = aws_s3_bucket.webpage_bucket.id

  index_document {
    suffix = "index.html"
  }

  
}