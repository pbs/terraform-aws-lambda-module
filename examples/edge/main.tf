module "lambda" {
  source = "../.."

  handler  = "main"
  filename = "../artifacts/handler.zip"
  runtime  = "go1.x"

  environment_vars    = {}
  layers              = []
  tracing_config_mode = "Disabled"

  environment  = var.environment
  product      = var.product
  repo         = var.repo
  organization = var.organization
}
