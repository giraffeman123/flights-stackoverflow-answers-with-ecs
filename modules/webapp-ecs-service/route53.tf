# Retrieve information about your hosted zone from AWS
data "aws_route53_zone" "this" {
  name = var.main_domain_name
}

resource "aws_route53_record" "alias_record" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.static_website_domain
  type    = "A"
  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = false
  }
}

# Create the TLS/SSL certificate for static website domain
resource "aws_acm_certificate" "cert" {
  domain_name               = var.static_website_domain
  validation_method         = "DNS"
  subject_alternative_names = []

  # Ensure that the resource is rebuilt before destruction when running an update
  lifecycle {
    create_before_destroy = true
  }
}

# Create DNS record that will be used for our certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = { for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
    name   = dvo.resource_record_name
    type   = dvo.resource_record_type
    record = dvo.resource_record_value
  } }

  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
  zone_id = data.aws_route53_zone.this.zone_id
}

# Validate the certificate
resource "aws_acm_certificate_validation" "validate-cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  depends_on = [aws_route53_record.cert_validation]
}