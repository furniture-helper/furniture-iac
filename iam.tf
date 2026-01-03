resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["2b18947a6a9fc7764fd8b5fb18a863b0c6dac24f"]

  tags = {
    Name    = "${var.project}-github-oidc-provider"
    Project = var.project
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_organization}/*"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = "${var.project}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name    = "${var.project}-github-actions-role"
    Project = var.project
  }
}

data "aws_caller_identity" "current" {}

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
      "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${var.ecr_repository_name}/*",
    ]
  }
}

resource "aws_iam_role_policy" "ecr_push" {
  name   = "github-actions-ecr-push"
  role   = aws_iam_role.github_actions_role.name
  policy = data.aws_iam_policy_document.ecr_push.json
}

data "aws_iam_policy_document" "terraform_backend_access" {

  statement {
    sid    = "AllowS3Access"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::furniture-iac",
      "arn:aws:s3:::furniture-iac/*"
    ]
  }
}

resource "aws_iam_role_policy" "terraform_backend_access" {
  name   = "github-actions-terraform-backend-access"
  role   = aws_iam_role.github_actions_role.name
  policy = data.aws_iam_policy_document.terraform_backend_access.json
}

data "aws_iam_policy_document" "cloudwatch_logs_access" {

  statement {
    sid    = "AllowDescribeLogGroups"
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/vpc/flow-logs*"
    ]
  }
}

resource "aws_iam_role_policy" "cloudwatch_logs_access" {
  name   = "github-actions-cloudwatch-logs-access"
  role   = aws_iam_role.github_actions_role.name
  policy = data.aws_iam_policy_document.cloudwatch_logs_access.json
}

data "aws_iam_policy_document" "github_actions_manage_iam" {
  statement {
    sid    = "AllowCreateRole"
    effect = "Allow"
    actions = [
      "iam:CreateRole"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-flow-logs-role"]
  }

  statement {
    sid    = "AllowManageSpecificFlowLogsRole"
    effect = "Allow"
    actions = [
      "iam:GetRole",
      "iam:PutRolePolicy",
      "iam:PassRole",
      "iam:ListRolePolicies"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-flow-logs-role",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.project}-github-actions-role"
    ]
  }

  statement {
    sid    = "AllowGetOIDCProvider"
    effect = "Allow"
    actions = [
      "iam:GetOpenIDConnectProvider"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
    ]
  }

  statement {
    sid    = "AllowCreateOIDCProvider"
    effect = "Allow"
    actions = [
      "iam:CreateOpenIDConnectProvider"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
  }
}

resource "aws_iam_role_policy" "github_actions_manage_iam" {
  name   = "github-actions-manage-iam-for-flow-logs"
  role   = aws_iam_role.github_actions_role.name
  policy = data.aws_iam_policy_document.github_actions_manage_iam.json
}

data "aws_iam_policy_document" "ec2_read" {
  statement {
    sid    = "AllowEC2Describe"
    effect = "Allow"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeAddresses",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "ec2_read" {
  name   = "github-actions-ec2-read"
  role   = aws_iam_role.github_actions_role.name
  policy = data.aws_iam_policy_document.ec2_read.json
}
