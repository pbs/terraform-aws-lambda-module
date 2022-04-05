module "lambda" {
  source = "../.."

  handler  = "main"
  filename = "../artifacts/handler.zip"
  runtime  = "go1.x"

  layers = [
    "arn:aws:lambda:${data.aws_region.region.name}:580247275435:layer:LambdaInsightsExtension:2",
  ]

  environment  = var.environment
  product      = var.product
  repo         = var.repo
  organization = var.organization
}
