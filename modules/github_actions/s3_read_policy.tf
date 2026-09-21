variable "sagemaker_s3_bucket_arn" {
  description = "The ARN of the S3 bucket used by SageMaker for model artifacts."
  type        = string
}


data "aws_iam_policy_document" "s3_read_policy" {
  statement {
    sid       = "S3ListBucket"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [var.sagemaker_s3_bucket_arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["model-artifacts/*"]
    }
  }

  statement {
    sid       = "S3GetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${var.sagemaker_s3_bucket_arn}/model-artifacts/*"]
  }
}
