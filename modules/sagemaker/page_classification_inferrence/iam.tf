data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "sfn_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "eventbridge_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn_execution" {
  name               = "page-classification-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume_role.json
  tags = {
    Name    = "page-classification-sfn-role"
    Project = "furniture"
  }
}

resource "aws_iam_role" "sfn_schedule_invoke" {
  name               = "page-classification-sfn-schedule-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json
  tags = {
    Name    = "page-classification-sfn-schedule-role"
    Project = "furniture"
  }
}

resource "aws_iam_role_policy" "sfn_schedule_invoke" {
  name = "page-classification-sfn-schedule-invoke-policy"
  role = aws_iam_role.sfn_schedule_invoke.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StartPageClassificationStateMachine"
        Effect   = "Allow"
        Action   = ["states:StartExecution"]
        Resource = aws_sfn_state_machine.page_classification.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "sfn_inline" {
  name = "page-classification-sfn-inline-policy"
  role = aws_iam_role.sfn_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CreateAndDescribeProcessingJobs"
        Effect = "Allow"
        Action = [
          "sagemaker:CreateProcessingJob",
          "sagemaker:AddTags",
          "sagemaker:DescribeProcessingJob",
          "sagemaker:StopProcessingJob"
        ]
        Resource = "*"
      },
      {
        Sid      = "PassSageMakerRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = var.sagemaker_role_arn
      },
      {
        Sid      = "ReadDatabaseCredentialsSecret"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.database_credentials_secret_arn
      },
      {
        Sid    = "ManageStepFunctionsManagedEventsRule"
        Effect = "Allow"
        Action = [
          "events:PutRule",
          "events:PutTargets",
          "events:DescribeRule",
          "events:DeleteRule",
          "events:RemoveTargets"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:events:*:*:rule/StepFunctionsGetEventsForSageMakerProcessingJobsRule"
      },
      {
        Sid    = "StateMachineLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

