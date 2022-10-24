resource "aws_appconfig_application" "app" {
  name        = var.product
  description = "Example ${var.product} AppConfig Application"

  tags = merge(
    var.tags,
    {
      Name                                      = local.name
      "${var.organization}:billing:product"     = var.product
      "${var.organization}:billing:environment" = var.environment
      creator                                   = "terraform"
      repo                                      = var.repo
    }
  )
}

resource "aws_appconfig_configuration_profile" "config_profile" {
  application_id = aws_appconfig_application.app.id

  name         = var.product
  description  = "Example ${var.product} Configuration Profile"
  location_uri = "hosted"

  tags = merge(
    var.tags,
    {
      Name                                      = local.name
      "${var.organization}:billing:product"     = var.product
      "${var.organization}:billing:environment" = var.environment
      creator                                   = "terraform"
      repo                                      = var.repo
    }
  )
}

resource "aws_appconfig_environment" "environment" {
  application_id = aws_appconfig_application.app.id

  name        = var.product
  description = "Example ${var.product} Environment"

  monitor {
    alarm_arn      = aws_cloudwatch_metric_alarm.example.arn
    alarm_role_arn = aws_iam_role.example.arn
  }

  tags = {
    Type = "AppConfig Environment"
  }
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
