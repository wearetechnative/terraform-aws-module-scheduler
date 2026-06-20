
resource "aws_s3_bucket" "webpage_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "webpage_bucket" {
  bucket = aws_s3_bucket.webpage_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "webpage_bucket" {
  bucket = aws_s3_bucket.webpage_bucket.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

data "aws_iam_policy_document" "webpage_bucket" {
  statement {
    sid    = "PublicReadWebsiteObjects"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.webpage_bucket.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "webpage_bucket" {
  bucket = aws_s3_bucket.webpage_bucket.id
  policy = data.aws_iam_policy_document.webpage_bucket.json

  depends_on = [
    aws_s3_bucket_ownership_controls.webpage_bucket,
    aws_s3_bucket_public_access_block.webpage_bucket
  ]
}

resource "aws_s3_bucket_object" "object" {
  bucket       = aws_s3_bucket.webpage_bucket.id
  key          = "index.html"
  content      = templatefile("${path.module}/html/index.html.tftpl", { api_url = aws_apigatewayv2_api.my_api.api_endpoint })
  content_type = "text/html"
  etag         = filemd5("${path.module}/html/index.html.tftpl")

}

resource "aws_s3_bucket_object" "object2" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "periods.html"
  content = templatefile("${path.module}/html/periods.html.tftpl", {
    api_url        = aws_apigatewayv2_api.my_api.api_endpoint
    schedule_names = jsonencode([for schedule in var.schedules : schedule.name])
  })
  content_type = "text/html"
  etag         = filemd5("${path.module}/html/periods.html.tftpl")

}
resource "aws_s3_bucket_object" "object3" {
  bucket       = aws_s3_bucket.webpage_bucket.id
  key          = "schedules.html"
  content      = templatefile("${path.module}/html/schedules.html.tftpl", { api_url = aws_apigatewayv2_api.my_api.api_endpoint })
  content_type = "text/html"
  etag         = filemd5("${path.module}/html/schedules.html.tftpl")

}

resource "aws_s3_bucket_object" "instances" {
  bucket       = aws_s3_bucket.webpage_bucket.id
  key          = "instances.html"
  content      = templatefile("${path.module}/html/instances.html.tftpl", { api_url = aws_apigatewayv2_api.my_api.api_endpoint })
  content_type = "text/html"
  etag         = filemd5("${path.module}/html/instances.html.tftpl")
}

resource "aws_s3_bucket_website_configuration" "website_conf" {
  bucket = aws_s3_bucket.webpage_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}
