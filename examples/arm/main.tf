module "lambda" {
  source = "../.."

  handler  = "main"
  filename = "../artifacts/arm-handler.zip"
  runtime  = "go1.x"

  architectures = ["arm64"]

  environment  = var.environment
  product      = var.product
  repo         = var.repo
  organization = var.organization
}
