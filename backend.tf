terraform {
  backend "s3" {
    bucket       = "furniture-iac-new"
    key          = "terraform.tfstate"
    region       = "eu-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
