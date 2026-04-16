locals {
  state_machine_definition = templatefile("${path.module}/state_machine.asl.json.tftpl", {
    partition               = data.aws_partition.current.partition
    sagemaker_role_arn      = var.sagemaker_role_arn
    dataset_image_uri       = "763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-training:2.1.0-cpu-py310"
    inference_image_uri     = "763104351884.dkr.ecr.eu-west-1.amazonaws.com/pytorch-training:2.1.0-gpu-py310"
    update_image_uri        = "470317259841.dkr.ecr.eu-west-1.amazonaws.com/sagemaker-base-python-310:1.0"
    dataset_instance_type   = "ml.r7i.xlarge"
    inference_instance_type = "ml.g5.xlarge"
    update_instance_type    = "ml.t3.medium"
    volume_size_gb          = 30

    dataset_script_s3_uri   = "s3://${var.sagemaker_bucket_name}/code/generate_classification_inference_dataset.py"
    inference_script_s3_uri = "s3://${var.sagemaker_bucket_name}/code/classification_inference.py"
    update_script_s3_uri    = "s3://${var.sagemaker_bucket_name}/code/update_classification_table.py"

    dataset_output_s3_uri     = "s3://${var.sagemaker_bucket_name}/classification-inference-dataset"
    model_s3_uri              = "s3://${var.sagemaker_bucket_name}/model-artifacts/classification-hpo-1774390325-009-f165bada/output/"
    predictions_output_s3_uri = "s3://${var.sagemaker_bucket_name}/predictions/"
    predictions_input_s3_uri  = "s3://${var.sagemaker_bucket_name}/predictions"

    pg_host                         = var.rds_db_endpoint
    database_credentials_secret_arn = var.database_credentials_secret_arn
    pg_port                         = "5432"

    inference_query_limit    = 20000
    markuplm_model_id        = "microsoft/markuplm-base"
    s3_fetch_num_proc        = 2
    tokenize_num_proc        = 1
    s3_fetch_threads         = 8
    inference_batch_size     = 32
    cpu_dynamic_quantization = 0
    skip_runtime_pip         = 0
  })
}

resource "aws_cloudwatch_log_group" "sfn" {
  # checkov:skip=CKV_AWS_158: "KMS encryption is not required for this log group"
  # checkov:skip=CKV_AWS_338: "Log group retention is set to 14 days only for cost management"
  name              = "/aws/states/page-classification-pipeline"
  retention_in_days = 14
  tags = {
    Name    = "page-classification-pipeline-logs"
    Project = "furniture"
  }
}

resource "aws_sfn_state_machine" "page_classification" {
  name       = "page-classification-pipeline"
  role_arn   = aws_iam_role.sfn_execution.arn
  definition = local.state_machine_definition
  type       = "STANDARD"
  tags = {
    Name    = "page-classification-pipeline"
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

resource "aws_cloudwatch_event_rule" "page_classification_daily" {
  name                = "page-classification-pipeline-daily"
  description         = "Runs the page classification pipeline once per day"
  schedule_expression = var.page_classification_schedule_expression

  tags = {
    Name    = "page-classification-pipeline-daily-schedule"
    Project = "furniture"
  }
}

resource "aws_cloudwatch_event_target" "page_classification_daily" {
  rule      = aws_cloudwatch_event_rule.page_classification_daily.name
  target_id = "page-classification-state-machine"
  arn       = aws_sfn_state_machine.page_classification.arn
  role_arn  = aws_iam_role.sfn_schedule_invoke.arn
}


