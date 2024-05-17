resource "aws_cloudfront_distribution" "cdn" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${local.prefix} - BackEnd and FrontEnd"
  aliases         = [""]
  tags            = local.tags

  dynamic "origin" {
    for_each = var.origin_domain_name_apis
    content {
      domain_name = origin.value
      origin_id   = "${local.prefix}-origin-${split("-", origin.value)[0]}"
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "http-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  default_cache_behavior {
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.prefix}-origin-bff"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  dynamic "ordered_cache_behavior" {
    for_each = [
      {
        path_pattern     = "",
        target_origin_id = "${local.prefix}-origin-bff"
      },
      {
        path_pattern     = "",
        target_origin_id = "${local.prefix}-origin"
      },
      {
        path_pattern     = "",
        target_origin_id = "${local.prefix}-origin"
      },
      {
        path_pattern     = "",
        target_origin_id = "${local.prefix}-origin"
      },
      {
       path_pattern     = "",
       target_origin_id = "${local.prefix}-origin"
      },
      {
        path_pattern     = "",
        target_origin_id = "${local.prefix}-origin"
      },
      {
        path_pattern     = "",
        target_origin_id = "${local.prefix}-origin"
      },
      {
        path_pattern     = "",
        target_origin_id = "${local.prefix}-origin"
      }
    ]
    content {
      path_pattern     = ordered_cache_behavior.value["path_pattern"]
      allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]
      target_origin_id = ordered_cache_behavior.value["target_origin_id"]

      forwarded_values {
        query_string = true
        headers      = ["*"]
        cookies {
          forward = "all"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 86400
      max_ttl                = 31536000
    }
  }

  origin {
    domain_name              = var.origin_domain_name_front
    origin_id                = "${local.prefix}-origin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  ordered_cache_behavior {
    path_pattern     = ""
    allowed_methods  = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.prefix}-origin"

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = ""
    minimum_protocol_version       = "TLSv1.2_2021"
    ssl_support_method             = "sni-only"
  }

}
