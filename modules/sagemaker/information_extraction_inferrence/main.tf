locals {
  state_machine_definition = templatefile("${path.module}/state_machine.asl.json.tftpl", {
    partition               = data.aws_partition.current.partition
    sagemaker_role_arn      = var.sagemaker_role_arn
    dataset_image_uri       = "763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-training:2.1.0-cpu-py310"
    inference_image_uri     = "763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-training:2.1.0-gpu-py310"
    update_image_uri        = "470317259841.dkr.ecr.eu-west-1.amazonaws.com/sagemaker-base-python-310:1.0"
    dataset_instance_type   = "ml.m7i.xlarge"
    inference_instance_type = "ml.g5.xlarge"
    update_instance_type    = "ml.t3.medium"
    volume_size_gb          = 30

    dataset_script_s3_uri   = "s3://${var.sagemaker_bucket_name}/code/generate_ie_inference_dataset.py"
    inference_script_s3_uri = "s3://${var.sagemaker_bucket_name}/code/information_extraction_inference.py"
    update_script_s3_uri    = "s3://${var.sagemaker_bucket_name}/code/update_ie_inferred_labels.py"

    dataset_output_s3_uri     = "s3://${var.sagemaker_bucket_name}/ie-inference-dataset"
    model_s3_uri              = "s3://kaneel-sagemaker-testing/ie-model-artifacts/ie-hpo-1776402101-010-1a824ab5/output/"
    predictions_output_s3_uri = "s3://${var.sagemaker_bucket_name}/ie-predictions/"
    predictions_input_s3_uri  = "s3://${var.sagemaker_bucket_name}/ie-predictions"

    pg_host                         = var.rds_db_endpoint
    database_credentials_secret_arn = var.database_credentials_secret_arn
    pg_port                         = "5432"

    ie_inference_query_limit = 20000
    markuplm_model_id        = "microsoft/markuplm-base"
    minimized_html_bucket    = "furniture-minimized-html"
    s3_fetch_num_proc        = 2
    tokenize_num_proc        = 1
    s3_fetch_threads         = 16
    inference_batch_size     = 16
    skip_runtime_pip         = 0
    title_score_threshold    = "0.90"
    price_score_threshold    = "0.90"
  })
}

resource "aws_cloudwatch_log_group" "sfn" {
  # checkov:skip=CKV_AWS_158: "KMS encryption is not required for this log group"
  # checkov:skip=CKV_AWS_338: "Log group retention is set to 14 days only for cost management"
  name              = "/aws/states/information-extraction-inference-pipeline"
  retention_in_days = 14
  tags = {
    Name    = "information-extraction-inference-pipeline-logs"
    Project = "furniture"
  }
}

resource "aws_sfn_state_machine" "information_extraction" {
  name       = "information-extraction-inference-pipeline"
  role_arn   = aws_iam_role.sfn_execution.arn
  definition = local.state_machine_definition
  type       = "STANDARD"
  tags = {
    Name    = "information-extraction-inference-pipeline"
    Project = "furniture"
  }

  logging_configuration {
    include_execution_data = true
    level                  = "ALL"

    log_destination = "${aws_cloudwatch_log_group.sfn.arn}:*"
  }

  tracing_configuration {
    enabled = true
  }
}

resource "aws_cloudwatch_event_rule" "information_extraction_daily" {
  name                = "information-extraction-inference-pipeline-daily"
  description         = "Runs the information extraction inference pipeline once per day"
  schedule_expression = var.information_extraction_schedule_expression

  tags = {
    Name    = "information-extraction-inference-pipeline-daily-schedule"
    Project = "furniture"
  }
}

resource "aws_cloudwatch_event_target" "information_extraction_daily" {
  rule      = aws_cloudwatch_event_rule.information_extraction_daily.name
  target_id = "information-extraction-state-machine"
  arn       = aws_sfn_state_machine.information_extraction.arn
  role_arn  = aws_iam_role.sfn_schedule_invoke.arn
}

