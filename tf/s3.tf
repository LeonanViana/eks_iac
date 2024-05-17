resource "aws_s3_bucket" "bucket" {
  bucket = "${local.prefix}-bucket"
  tags   = local.tags
}
