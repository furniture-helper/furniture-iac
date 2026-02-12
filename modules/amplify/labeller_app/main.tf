data "aws_secretsmanager_secret" "labeller_github_token" {
  name = "labeller_github_token"
}

data "aws_secretsmanager_secret_version" "labeller_github_token_value" {
  secret_id = data.aws_secretsmanager_secret.labeller_github_token.id
}

variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "database_credentials_secret_name" {
  description = "Name of the Secrets Manager secret containing the database credentials"
  type        = string
}

variable "db_endpoint" {
  description = "Endpoint of the RDS database"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for the furniture crawler"
  type        = string
}

resource "aws_amplify_app" "furniture_labeller_app" {
  name       = "furniture-labeller-app"
  repository = "https://github.com/furniture-helper/furniture-labeller"
  platform   = "WEB_COMPUTE"

  iam_service_role_arn = aws_iam_role.amplify_service_role.arn
  compute_role_arn     = aws_iam_role.amplify_labeller_compute_role.arn

  access_token = jsondecode(data.aws_secretsmanager_secret_version.labeller_github_token_value.secret_string)["token"]

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm install
            # 1. Set Shell variables (Terraform will fill these correctly)
            - export DB_SECRET_NAME="${var.database_credentials_secret_name}"
            - export AWS_REGION_NAME="${data.aws_region.current.region}"
            - export PG_HOST="${var.db_endpoint}"
            - export AWS_S3_BUCKET="${var.s3_bucket_name}"

            # 2. Run Node.js and pull from process.env
            - |
              node -e "
              const { execSync } = require('child_process');
              const fs = require('fs');
              const { DB_SECRET_NAME, AWS_REGION_NAME } = process.env;

              try {
                console.log('Fetching secret: ' + DB_SECRET_NAME + ' in ' + AWS_REGION_NAME);

                // Use standard JS concatenation to avoid any confusion
                const cmd = 'aws secretsmanager get-secret-value --secret-id ' + DB_SECRET_NAME + ' --region ' + AWS_REGION_NAME + ' --query SecretString --output text';

                const raw = execSync(cmd).toString();
                const secrets = JSON.parse(raw);

                const correct_secrets = {
                  PG_HOST: process.env.PG_HOST,
                  PG_USER: secrets.username,
                  PG_PASSWORD: secrets.password,
                  PG_DATABASE: secrets.database_name,
                  AWS_S3_BUCKET: process.env.AWS_S3_BUCKET
                };


                // Format for .env.production
                const content = Object.entries(correct_secrets)
                  .map(([k, v]) => k + '=' + v)
                  .join('\n');


                console.log('Generated .env.production content:\\n' + correct_secrets);
                fs.writeFileSync('.env.production', content);
                console.log('SUCCESS: .env.production generated');
              } catch (err) {
                console.error('CRITICAL ERROR:', err.message);
                process.exit(1);
              }
              "
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: .next
        files:
          - '**/*'
          - '../.env.production'
  EOT
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.furniture_labeller_app.id
  branch_name = "main"

  framework = "Next.js - SSR"
  stage     = "PRODUCTION"

  enable_auto_build = true
}

resource "aws_amplify_domain_association" "this" {
  app_id      = aws_amplify_app.furniture_labeller_app.id
  domain_name = "label.furniture.kaneel.xyz"

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "www"
  }
}
