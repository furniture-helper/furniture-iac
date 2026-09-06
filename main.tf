terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

provider "aws" {
  alias  = "tertiary"
  region = var.tertiary_region
}

module "s3" {
  source  = "./modules/s3"
  project = var.project
}

module "ecr" {
  source              = "./modules/ecr"
  project             = var.project
  replication_regions = [var.secondary_region, var.tertiary_region]
}

module "vpc" {
  source = "./modules/vpc"
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
    aws.tertiary  = aws.tertiary
  }
  primary_availability_zone_1   = var.availability_zone_1
  primary_availability_zone_2   = var.availability_zone_2
  secondary_availability_zone_1 = var.secondary_availability_zone_1
  secondary_availability_zone_2 = var.secondary_availability_zone_2
  tertiary_availability_zone_1  = var.tertiary_availability_zone_1
  tertiary_availability_zone_2  = var.tertiary_availability_zone_2
}

module "ecs" {
  source = "./modules/ecs"
  providers = {
    aws           = aws
    aws.secondary = aws.secondary
    aws.tertiary  = aws.tertiary
  }
  project                               = var.project
  crawler_s3_bucket_name                = module.s3.crawler_storage_s3_bucket_name
  crawler_ecr_repo_urls                 = module.ecr.furniture_crawler_ecr_regional_uris
  crawler_s3_bucket_arn                 = module.s3.crawler_storage_s3_bucket_arn
  rds_sg_id                             = module.rds.rds_sg_id
  database_credentials_secret_arn       = module.rds.database_credentials_secret_arn
  rds_db_endpoint                       = module.rds.db_endpoint_v2
  shared_services_region                = var.region
  crawler_sqs_queue_url                 = module.sqs.crawler_queue_url
  crawler_sqs_queue_arn                 = module.sqs.crawler_queue_arn
  secondary_crawler_sqs_queue_url       = module.sqs.crawler_secondary_queue_url
  secondary_crawler_sqs_queue_arn       = module.sqs.crawler_secondary_queue_arn
  tertiary_crawler_sqs_queue_url        = module.sqs.crawler_tertiary_queue_url
  tertiary_crawler_sqs_queue_arn        = module.sqs.crawler_tertiary_queue_arn
  primary_crawler_schedule_expression   = var.primary_crawler_schedule_expression
  secondary_crawler_schedule_expression = var.secondary_crawler_schedule_expression
  tertiary_crawler_schedule_expression  = var.tertiary_crawler_schedule_expression
  anchor_tree_s3_bucket_arn             = module.sagemaker.sagemaker_storage_s3_bucket_arn
  anchor_tree_s3_bucket_name            = module.sagemaker.sagemaker_storage_s3_bucket_name
  html_minimizer_ecr_repo_url           = module.ecr.html_minimizer_ecr_repo_uri
  html_minimizer_s3_bucket_arn          = module.s3.minimized_html_storage_s3_bucket_arn
  html_minimizer_s3_bucket_name         = module.s3.minimized_html_storage_s3_bucket_name
  primary_public_subnet_ids             = module.vpc.primary_public_subnet_ids
  primary_vpc_id                        = module.vpc.primary_vpc_id
  secondary_public_subnet_ids           = module.vpc.secondary_public_subnet_ids
  secondary_vpc_id                      = module.vpc.secondary_vpc_id
  tertiary_public_subnet_ids            = module.vpc.tertiary_public_subnet_ids
  tertiary_vpc_id                       = module.vpc.tertiary_vpc_id
  kafka_public_ip                       = module.kafka.kafka_server_public_ip
  database_credentials_secret_name      = module.rds.database_credentials_secret_name
  analytics_ecr_repo_url                = module.ecr.furniture_analytics_ecr_repo_uri
  anchor_tree_generator_ecr_repo_url    = module.ecr.anchor_tree_generator_ecr_repo_uri
}

module "github_actions" {
  source                         = "./modules/github_actions"
  project                        = var.project
  github_organization            = var.github_organization
  crawler_repo_arn               = module.ecr.furniture_crawler_ecr_repo_arn
  crawler_queue_manager_repo_arn = module.ecr.furniture_crawler_queue_manager_ecr_repo_arn
  html_minimizer_repo_arn        = module.ecr.html_minimizer_ecr_repo_arn
  search_api_repo_arn            = module.ecr.furniture_search_api_ecr_repo_arn
  analytics_repo_arn             = module.ecr.furniture_analytics_ecr_repo_arn
  anchor_tree_generator_repo_arn = module.ecr.anchor_tree_generator_ecr_repo_arn
}

module "rds" {
  source                   = "./modules/rds"
  project                  = var.project
  vpc_id                   = module.vpc.primary_vpc_id
  private_subnet_ids       = module.vpc.primary_private_subnet_ids
  public_subnet_ids        = module.vpc.primary_public_subnet_ids
  allow_public_connections = true
  ecs_primary_tasks_sg_id  = module.ecs.ecs_primary_tasks_sg_id
}

module "sqs" {
  source  = "./modules/sqs"
  project = var.project
}

module "lambda" {
  source                          = "./modules/lambda"
  crawler_sqs_queue_arn           = module.sqs.crawler_queue_arn
  crawler_ecr_repo_url            = module.ecr.furniture_crawler_queue_manager_ecr_repo_uri
  search_api_ecr_repo_url         = module.ecr.furniture_search_api_ecr_repo_uri
  project                         = var.project
  database_credentials_secret_arn = module.rds.database_credentials_secret_arn
  crawler_sqs_queue_url           = module.sqs.crawler_queue_url
  database_credentials_name       = module.rds.database_credentials_secret_name
  rds_db_endpoint                 = module.rds.db_endpoint_v2
  frontend_origin                 = module.amplify.search_app_endpoint
  crawler_storage_s3_bucket       = module.s3.crawler_storage_s3_bucket_name
  minimized_pages_s3_bucket       = module.s3.minimized_html_storage_s3_bucket_name
  s3_region                       = var.region
}

module "r53" {
  source                 = "./modules/r53"
  project                = var.project
  search_api_http_api_id = module.api_gateway.search_api_id
  search_api_stage_name  = module.api_gateway.search_api_stage_name
  kafka_server_public_ip = module.kafka.kafka_server_public_ip
}

module "amplify" {
  source                           = "./modules/amplify"
  project                          = var.project
  database_credentials_secret_arn  = module.rds.database_credentials_secret_arn
  database_credentials_secret_name = module.rds.database_credentials_secret_name
  db_endpoint                      = module.rds.db_endpoint_v2
  s3_minimized_html_bucket_name    = module.s3.minimized_html_storage_s3_bucket_name
  s3_raw_html_bucket_name          = module.s3.crawler_storage_s3_bucket_name
  search_api_base_url              = module.r53.custom_domain_url
}

module "sagemaker" {
  source                   = "./modules/sagemaker"
  project                  = var.project
  database_credentials_arn = module.rds.database_credentials_secret_arn
  rds_db_endpoint          = module.rds.db_endpoint_v2
}

module "api_gateway" {
  source                          = "./modules/api_gateway"
  project                         = var.project
  search_api_lambda_invoke_arn    = module.lambda.search_api_lambda_invoke_arn
  search_api_lambda_function_name = module.lambda.search_api_lambda_name
  search_frontend_origin          = module.amplify.search_app_endpoint
}

module "kafka" {
  source                          = "./modules/kafka"
  project                         = var.project
  vpc_id                          = module.vpc.primary_vpc_id
  subnet_id                       = module.vpc.primary_public_subnet_ids[0]
  database_credentials_secret_arn = module.rds.database_credentials_secret_arn
  rds_db_endpoint                 = module.rds.db_endpoint_v2
}

output "db_endpoint_v2" {
  description = "RDS Database Endpoint v2"
  value       = module.rds.db_endpoint_v2
}

output "furniture_kaneel_xyz_nameservers" {
  description = "Nameservers for furniture.kaneel.xyz (copy these to Namecheap Custom DNS)"
  value       = module.r53.namecheap_nameservers
}

output "search_api_endpoint" {
  description = "Endpoint of the Search API"
  value       = module.api_gateway.search_api_endpoint
}

output "kafka_server_public_ip" {
  description = "Public IP of the Kafka server"
  value       = module.kafka.kafka_server_public_ip
}
