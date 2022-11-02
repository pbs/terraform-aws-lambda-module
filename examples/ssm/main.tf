locals {
  # This is the default SSM path for Lambdas created like this.
  ssm_path = "/${var.environment}/${var.product}/"
}

resource "aws_ssm_parameter" "name" {
  name  = "${local.ssm_path}name"
  type  = "SecureString"
  value = "John"
}

module "lambda" {
  source = "../.."

  handler  = "main"
  filename = "../artifacts/handler.zip"
  runtime  = "go1.x"

  environment  = var.environment
  product      = var.product
  repo         = var.repo
  organization = var.organization
}
