variable "project" {
  type        = string
  description = "Project name"
}

resource "aws_route53_zone" "furniture_kaneel_xyz" {
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

output "namecheap_nameservers" {
  value       = aws_route53_zone.furniture_kaneel_xyz.name_servers
  description = "Copy these 4 servers and paste them into Namecheap Custom DNS"
}
