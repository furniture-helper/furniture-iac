variable "search_api_http_api_id" {
  description = "The ID of the HTTP API to associate with the custom domain"
  type        = string
}

variable "search_api_stage_name" {
  description = "The name of the stage to associate with the custom domain"
  type        = string
}

resource "aws_acm_certificate" "api_cert" {
  domain_name       = "api.search.furniture.kaneel.xyz"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Project = var.project
    Name    = "${var.project}-api-certificate"
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.furniture_kaneel_xyz.zone_id
}

resource "aws_acm_certificate_validation" "api_cert_val" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_apigatewayv2_domain_name" "api_domain" {
  domain_name = "api.search.furniture.kaneel.xyz"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_cert_val.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }

  tags = {
    Project = var.project
    Name    = "${var.project}-api-domain"
  }
}

resource "aws_apigatewayv2_api_mapping" "api_mapping" {
  api_id      = var.search_api_http_api_id
  domain_name = aws_apigatewayv2_domain_name.api_domain.id
  stage       = var.search_api_stage_name
}

resource "aws_route53_record" "api_dns" {
  name    = aws_apigatewayv2_domain_name.api_domain.domain_name
  type    = "A"
  zone_id = aws_route53_zone.furniture_kaneel_xyz.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api_domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

output "custom_domain_url" {
  value = "https://${aws_apigatewayv2_domain_name.api_domain.domain_name}"
}
