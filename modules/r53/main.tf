variable "project" {
  type        = string
  description = "Project name"
}

resource "aws_route53_zone" "furniture_kaneel_xyz" {
  # checkov:skip=CKV2_AWS_39: "Will havw to enable DNS query logging later."
  # checkov:skip=CKV2_AWS_38: "Ignoring DNSSEC for now."
  name = "furniture.kaneel.xyz"

  tags = {
    Project = var.project
    Name    = "furniture_kaneel_xyz_r53_zone"
  }
}

resource "aws_route53_record" "label_to_www" {
  zone_id = aws_route53_zone.furniture_kaneel_xyz.zone_id
  name    = "label.furniture.kaneel.xyz"
  type    = "CNAME"
  ttl     = 300
  records = ["www.label.furniture.kaneel.xyz."]
}

# resource "aws_route53_hosted_zone_dnssec" "example" {
#   hosted_zone_id = aws_route53_zone.furniture_kaneel_xyz.zone_id
# }

output "namecheap_nameservers" {
  value       = aws_route53_zone.furniture_kaneel_xyz.name_servers
  description = "Copy these 4 servers and paste them into Namecheap Custom DNS"
}
