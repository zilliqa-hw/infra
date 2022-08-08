resource "aws_route53_delegation_set" "dev_mongodb_hu" {
  reference_name = "dev.metricsglobal.dev"
}

resource "aws_route53_zone" "dev_mongodb_hu" {
  name              = "dev.mongodb.hu"
  delegation_set_id = aws_route53_delegation_set.dev_mongodb_hu.id
}

data "aws_route53_zone" "mongodb_hu" {
  provider = aws.shared-services-eu-central-1
  name     = "mongodb.hu."
}

resource "aws_route53_record" "dev_mongodb_hu_ns" {
  provider = aws.shared-services-eu-central-1
  zone_id  = data.aws_route53_zone.mongodb_hu.id
  name     = aws_route53_zone.dev_mongodb_hu.name
  type     = "NS"
  ttl      = 14400

  records = aws_route53_delegation_set.dev_mongodb_hu.name_servers
}

# The External DNS controlles is not installed in the cluster yet,
# so we just manage here the few hostnames until there is a need to have that.
# resource "aws_route53_record" "ingress_dev_mongodb_hu" {
#   for_each = local.k8s_ingress

#   zone_id = aws_route53_zone.dev_mongodb_hu.id
#   name    = "${each.value}.${aws_route53_zone.dev_mongodb_hu.name}"
#   type    = "A"

#   alias {
#     name                   = data.aws_lb.k8s_ingress.dns_name
#     zone_id                = data.aws_lb.k8s_ingress.zone_id
#     evaluate_target_health = false
#   }
# }
