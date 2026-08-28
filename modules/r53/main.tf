variable "project" {
  type        = string
  description = "Project name"
}

variable "kafka_server_public_ip" {
  description = "Public IP of the Kafka EC2 instance EIP"
  type        = string
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

resource "aws_route53_record" "search_to_www" {
  zone_id = aws_route53_zone.furniture_kaneel_xyz.zone_id
  name    = "search.furniture.kaneel.xyz"
  type    = "CNAME"
  ttl     = 300
  records = ["www.search.furniture.kaneel.xyz."]
}

resource "aws_route53_record" "kafka_dns" {
  # checkov:skip=CKV2_AWS_23: Static A record intentionally points to external EIP.
  zone_id = aws_route53_zone.furniture_kaneel_xyz.zone_id
  name    = "kafka.furniture.kaneel.xyz"
  type    = "A"
  ttl     = 300
  records = [var.kafka_server_public_ip]
}

resource "aws_route53_record" "metabase_dns" {
  # checkov:skip=CKV2_AWS_23: Static A record intentionally points to external EIP.
  zone_id = aws_route53_zone.furniture_kaneel_xyz.zone_id
  name    = "metabase.furniture.kaneel.xyz"
  type    = "A"
  ttl     = 300
  records = [var.kafka_server_public_ip]
}

output "namecheap_nameservers" {
  value       = aws_route53_zone.furniture_kaneel_xyz.name_servers
  description = "Copy these 4 servers and paste them into Namecheap Custom DNS"
}
