resource "aws_cloudwatch_log_group" "search_v2_log_group" {
  # checkov:skip=CKV_AWS_158: "Will add KMS encryption later"
  # checkov:skip=CKV_AWS_338: "I cannot afford to keep logs for 1 year"
  name              = "/aws/amplify/${aws_amplify_app.furniture_search_v2_app.id}"
  retention_in_days = 14

  tags = {
    Project = var.project
    Name    = "search_v2_log_group"
  }
}
