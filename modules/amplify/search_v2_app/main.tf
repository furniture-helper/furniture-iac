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

variable "search_api_base_url" {
  description = "The base URL of the search API"
  type        = string
}

resource "aws_amplify_app" "furniture_search_v2_app" {
  name       = "furniture-search-v2-app"
  repository = "https://github.com/furniture-helper/furniture-search-frontend-v2"
  platform   = "WEB_COMPUTE"

  iam_service_role_arn = aws_iam_role.search_v2_amplify_service_role.arn
  compute_role_arn     = aws_iam_role.amplify_search_v2_compute_role.arn

  access_token = jsondecode(data.aws_secretsmanager_secret_version.labeller_github_token_value.secret_string)["token"]

  depends_on = [
    aws_iam_role_policy_attachment.amplify_ssr_policy_attachment
  ]

  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm install
            - export API_BASE_URL="${var.search_api_base_url}"

            # 2. Run Node.js and pull from process.env
            - |
              node -e "
              const fs = require('fs');

              try {
                const correct_secrets = {
                  API_BASE_URL: process.env.API_BASE_URL,
                  NEXT_PUBLIC_API_BASE_URL: process.env.API_BASE_URL,
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

  tags = {
    Project = var.project
    Name    = "search_v2_amplify_app"
  }
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.furniture_search_v2_app.id
  branch_name = "main"

  framework = "Next.js - SSR"
  stage     = "PRODUCTION"

  enable_auto_build = true

  tags = {
    Project = var.project
    Name    = "search_v2_amplify_branch_main"
  }
}

resource "aws_amplify_domain_association" "this" {
  app_id      = aws_amplify_app.furniture_search_v2_app.id
  domain_name = "search-v2.furniture.kaneel.xyz"

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = ""
  }

  sub_domain {
    branch_name = aws_amplify_branch.main.branch_name
    prefix      = "www"
  }
}

output "search_v2_app_endpoint" {
  description = "URL of the search v2 app"
  value       = aws_amplify_domain_association.this.domain_name
}
