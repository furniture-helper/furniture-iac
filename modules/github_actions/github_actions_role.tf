variable "project" {
  type = string
}

resource "aws_iam_role" "github_actions_role" {
  name               = "${var.project}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name    = "${var.project}-github-actions-role"
    Project = var.project
  }
}

resource "aws_iam_role_policy" "ecr_push" {
  name   = "github-actions-ecr-push"
  role   = aws_iam_role.github_actions_role.name
  policy = data.aws_iam_policy_document.ecr_push.json
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions_role.arn
}
