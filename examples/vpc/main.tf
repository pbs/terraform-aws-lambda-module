module "lambda" {
  source = "../.."

  handler  = "main"
  filename = "../artifacts/handler.zip"
  runtime  = "go1.x"

  add_vpc_config = true
  timeout        = 10

  environment  = var.environment
  product      = var.product
  repo         = var.repo
  organization = var.organization
}
