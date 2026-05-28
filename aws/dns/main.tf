# use existing hosted zone
data "aws_route53_zone" "devopswiki-hosted-zone" {
  name         = "devopswiki.info"
  private_zone = false
}

# dns record 
resource "aws_route53_record" "devopswiki-test-dns-record" {
  zone_id = data.aws_route53_zone.devopswiki-hosted-zone.zone_id
  name    = "test.devopswiki.info"
  type    = "A"
  ttl     = "300"
  records = [var.testbed_fe_eip]
}
