data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

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
  name               = "information-extraction-inference-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume_role.json
  tags = {
    Name    = "information-extraction-inference-sfn-role"
    Project = "furniture"
  }
}

resource "aws_iam_role" "sfn_schedule_invoke" {
  name               = "information-extraction-inference-sfn-schedule-role"
  assume_role_policy = data.aws_iam_policy_document.eventbridge_assume_role.json
  tags = {
    Name    = "information-extraction-inference-sfn-schedule-role"
    Project = "furniture"
  }
}

resource "aws_iam_role_policy" "sfn_schedule_invoke" {
  name = "information-extraction-inference-sfn-schedule-invoke-policy"
  role = aws_iam_role.sfn_schedule_invoke.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "StartInformationExtractionStateMachine"
        Effect   = "Allow"
        Action   = ["states:StartExecution"]
        Resource = aws_sfn_state_machine.information_extraction.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "sfn_inline" {
  # checkov:skip=CKV_AWS_290: "CloudWatch Logs delivery APIs (CreateLogDelivery etc.) do not support resource-level constraints"
  name = "information-extraction-inference-sfn-inline-policy"
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
        Resource = [
          "arn:${data.aws_partition.current.partition}:sagemaker:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:processing-job/generate-ie-inference-dataset-*",
          "arn:${data.aws_partition.current.partition}:sagemaker:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:processing-job/information-extraction-inference-*",
          "arn:${data.aws_partition.current.partition}:sagemaker:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:processing-job/update-ie-inferred-labels-*"
        ]
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
        Sid    = "StateMachineLogGroupActions"
        Effect = "Allow"
        Action = [
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "StateMachineLogDeliveryActions"
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries"
        ]
        Resource = "*"
      }
    ]
  })
}

