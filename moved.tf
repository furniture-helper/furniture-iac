moved {
  from = module.iam_roles.aws_iam_openid_connect_provider.github
  to   = module.github_actions.aws_iam_openid_connect_provider.github
}

moved {
  from = module.iam_roles.aws_iam_role.github_actions_role
  to   = module.github_actions.aws_iam_role.github_actions_role
}

moved {
  from = module.iam_roles.aws_iam_role_policy.ecr_push
  to   = module.github_actions.aws_iam_role_policy.ecr_push
}
