# Shared Services hosts the metricsglobal.dev domain.

resource "aws_route53_delegation_set" "mongodb_hu" {
  reference_name = "mongodb.hu"
}

resource "aws_route53_zone" "mongodb_hu" {
  name              = aws_route53_delegation_set.mongodb_hu.reference_name
  delegation_set_id = aws_route53_delegation_set.mongodb_hu.id
}

resource "aws_route53_record" "google_mx" {
  zone_id = aws_route53_zone.mongodb_hu.id
  name    = aws_route53_zone.mongodb_hu.name
  type    = "MX"
  ttl     = "1440"
  records = [
    "1 aspmx.l.google.com.",
    "5 alt1.aspmx.l.google.com.",
    "5 alt2.aspmx.l.google.com.",
    "10 alt3.aspmx.l.google.com.",
    "10 alt4.aspmx.l.google.com.",
  ]
}

resource "aws_route53_record" "google_txt" {
  zone_id = aws_route53_zone.mongodb_hu.id
  name    = aws_route53_zone.mongodb_hu.name
  type    = "TXT"
  ttl     = 1800

  records = [
    "v=spf1 include:_spf.google.com ~all"
  ]
}

resource "aws_route53_record" "google_spf" {
  zone_id = aws_route53_zone.mongodb_hu.id
  name    = aws_route53_zone.mongodb_hu.name
  type    = "SPF"
  ttl     = 3600

  records = [
    "v=spf1 include:_spf.google.com ~all"
  ]
}

resource "aws_route53_record" "google_dkim" {
  zone_id = aws_route53_zone.mongodb_hu.id
  name    = "google._domainkey.${aws_route53_zone.mongodb_hu.name}"
  type    = "TXT"
  ttl     = 3600

  # Provided by Google Workspaces. Get it from https://domains.google.com/registrar/metricsglobal.dev/dns
  records = [
    "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtB7U6kriBRpUa33xWXfaaon0RYnVVise4tNNdIQTarPL988ZxRdy9sHsbar1MAp8wzAtul+tdtOH/ohhx5E7VDrpw/JaEztxo/C+kOWWNKInGDo+PYzS8jaoXgXuQa3eL/pKn5wK8z5x1Hxa2V66Tl3RuaqnelQMvabgaopRm3yq8CooBmfmSOk8cN6kj046b\" \"bzsKYcHO9Q/nsc63fcIL8GPm1V22r4yXKDmi2wgCHBR/kFtVo2isvHzVNiv7dt0hhNrPaSsHCtoI3g3P1HWy03OEahXJGNj3xmxCdgjtf38TTNFJt6bQ/cHceupMOJOP83gwAelXHXVCjxJ8EtKbwIDAQAB"
  ]
}

resource "aws_route53_record" "google_connect" {
  zone_id = aws_route53_zone.mongodb_hu.id
  name    = "_domainconnect.${aws_route53_zone.mongodb_hu.name}"
  type    = "CNAME"
  ttl     = 14400

  records = [
    "connect.domains.google.com.",
  ]
}
