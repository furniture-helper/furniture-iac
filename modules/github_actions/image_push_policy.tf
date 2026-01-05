variable "crawler_repo_arn" {
  description = "ECR repository URL for the furniture crawler"
  type        = string
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid    = "GetAuthorization"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:CreateRepository",
      "ecr:ListTagsForResource"
    ]
    resources = [
      var.crawler_repo_arn
    ]
  }
}
