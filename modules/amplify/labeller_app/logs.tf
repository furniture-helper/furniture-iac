resource "aws_cloudwatch_log_group" "labeller_log_group" {
  name              = "/aws/amplify/${aws_amplify_app.furniture_labeller_app.id}"
  retention_in_days = 14
  tags = {
    Service = "amplify"
    App     = aws_amplify_app.furniture_labeller_app.name
    Branch  = aws_amplify_branch.main.branch_name
  }
}
