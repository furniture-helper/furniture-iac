resource "aws_iam_role" "amplify_search_compute_role" {
  name = "amplify-search-compute-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "amplify.amazonaws.com",
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = {
    Project = var.project
    Name    = "amplify_search_compute_role"
  }
}
