resource "aws_cloudwatch_log_group" "labeller_log_group" {
  name              = "/aws/amplify/${aws_amplify_app.furniture_labeller_app.id}"
  retention_in_days = 14

  tags = {
    Project = var.project
    Name    = "labeller_log_group"
  }
}
