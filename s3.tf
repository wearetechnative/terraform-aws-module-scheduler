
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
  block_public_policy     = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "webpage_bucket" {
  statement {
    sid    = "AllowCloudFrontReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.webpage_bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.webpage.arn]
    }
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
  content      = templatefile("${path.module}/html/index.html.tftpl", { api_url = local.application_url })
  content_type = "text/html"
  etag         = filemd5("${path.module}/html/index.html.tftpl")

}

resource "aws_s3_bucket_object" "object2" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "periods.html"
  content = templatefile("${path.module}/html/periods.html.tftpl", {
    api_url        = local.application_url
    schedule_names = jsonencode([for schedule in var.schedules : schedule.name])
  })
  content_type = "text/html"
  etag         = filemd5("${path.module}/html/periods.html.tftpl")

}
resource "aws_s3_bucket_object" "object3" {
  bucket       = aws_s3_bucket.webpage_bucket.id
  key          = "schedules.html"
  content      = templatefile("${path.module}/html/schedules.html.tftpl", { api_url = local.application_url })
  content_type = "text/html"
  etag         = filemd5("${path.module}/html/schedules.html.tftpl")

}

resource "aws_s3_bucket_object" "instances" {
  bucket       = aws_s3_bucket.webpage_bucket.id
  key          = "instances.html"
  content      = templatefile("${path.module}/html/instances.html.tftpl", { api_url = local.application_url })
  content_type = "text/html"
  etag         = filemd5("${path.module}/html/instances.html.tftpl")
}

resource "aws_s3_bucket_object" "technative_logo" {
  bucket       = aws_s3_bucket.webpage_bucket.id
  key          = "technativelogo.svg"
  source       = "${path.module}/technativelogo.svg"
  content_type = "image/svg+xml"
  etag         = filemd5("${path.module}/technativelogo.svg")
}

resource "aws_s3_bucket_object" "favicon" {
  bucket        = aws_s3_bucket.webpage_bucket.id
  key           = "favicon.svg"
  source        = "${path.module}/favicon.svg"
  content_type  = "image/svg+xml"
  cache_control = "public, max-age=86400"
  etag          = filemd5("${path.module}/favicon.svg")
}

resource "aws_s3_bucket_object" "auth" {
  bucket = aws_s3_bucket.webpage_bucket.id
  key    = "auth.js"
  content = templatefile("${path.module}/html/auth.js.tftpl", {
    api_url         = local.application_url
    application_url = local.application_url
    callback_url    = local.callback_url
    client_id       = aws_cognito_user_pool_client.scheduler.id
    cognito_domain  = "https://${aws_cognito_user_pool_domain.scheduler.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
  })
  content_type  = "application/javascript"
  cache_control = "no-store"
  etag          = filemd5("${path.module}/html/auth.js.tftpl")
}
