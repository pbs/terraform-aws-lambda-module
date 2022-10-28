resource "aws_appconfig_application" "app" {
  name        = var.product
  description = "Example ${var.product} AppConfig Application"

  tags = {
    Name                                      = "${var.product} App"
    "${var.organization}:billing:product"     = var.product
    "${var.organization}:billing:environment" = var.environment
    creator                                   = "terraform"
    repo                                      = var.repo
  }
}

resource "aws_appconfig_configuration_profile" "config_profile" {
  application_id = aws_appconfig_application.app.id

  name         = var.product
  description  = "Example ${var.product} Configuration Profile"
  location_uri = "hosted"
  type         = "AWS.AppConfig.FeatureFlags"

  tags = {
    Name                                      = "${var.product} Config Profile"
    "${var.organization}:billing:product"     = var.product
    "${var.organization}:billing:environment" = var.environment
    creator                                   = "terraform"
    repo                                      = var.repo
  }
}

module "alarm" {
  source = "github.com/pbs/terraform-aws-cloudwatch-alarms-module?ref=0.0.2"

  namespace       = "AWS/Lambda"
  lambda_function = module.lambda.name

  threshold = 50

  # Tagging Parameters
  organization = var.organization
  environment  = var.environment
  product      = var.product
  repo         = var.repo

  # Optional Parameters
}

module "role" {
  source = "github.com/pbs/terraform-aws-iam-role-module?ref=0.1.1"

  policy_json = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "cloudwatch:DescribeAlarms"
        ],
        "Resource" : "*"
      }
    ]
  })

  # Tagging Parameters
  organization = var.organization
  environment  = var.environment
  product      = var.product
  repo         = var.repo

  # Optional Parameters
  aws_services = ["appconfig"]
}

resource "aws_appconfig_environment" "environment" {
  application_id = aws_appconfig_application.app.id

  name        = var.environment
  description = "Example ${var.product} Environment"

  monitor {
    alarm_arn      = module.alarm.arn
    alarm_role_arn = module.role.arn
  }

  tags = {
    Name                                      = "${var.product} Environment"
    "${var.organization}:billing:product"     = var.product
    "${var.organization}:billing:environment" = var.environment
    creator                                   = "terraform"
    repo                                      = var.repo
  }
}

resource "aws_appconfig_deployment_strategy" "deployment_strategy" {
  name        = var.product
  description = "Example ${var.product} Deployment Strategy"

  deployment_duration_in_minutes = 0 # Recommended is 15 minutes
  final_bake_time_in_minutes     = 0 # Recommended is 10 minutes
  growth_factor                  = 10
  growth_type                    = "EXPONENTIAL"
  replicate_to                   = "NONE"

  tags = {
    Name                                      = "${var.product} Deployment Strategy"
    "${var.organization}:billing:product"     = var.product
    "${var.organization}:billing:environment" = var.environment
    creator                                   = "terraform"
    repo                                      = var.repo
  }
}

resource "aws_appconfig_hosted_configuration_version" "config_version" {
  application_id           = aws_appconfig_application.app.id
  configuration_profile_id = aws_appconfig_configuration_profile.config_profile.configuration_profile_id
  description              = "Example ${var.product} Feature Flag Configuration Version"
  content_type             = "application/json"

  content = jsonencode({
    flags : {
      person : {
        name : "person",
        attributes : {
          firstName : {
            constraints : {
              type : "string",
              required : true
            }
          },
          age : {
            constraints : {
              type : "number",
              required : true
            }
          }
        }
      }
    },
    values : {
      person : {
        enabled : "true",
        firstName : "Billy",
        age : 10
      }
    },
    version : "1"
  })
}

resource "aws_appconfig_deployment" "deployment" {
  application_id           = aws_appconfig_application.app.id
  configuration_profile_id = aws_appconfig_configuration_profile.config_profile.configuration_profile_id
  configuration_version    = aws_appconfig_hosted_configuration_version.config_version.version_number
  deployment_strategy_id   = aws_appconfig_deployment_strategy.deployment_strategy.id
  description              = "Example ${var.product} Deployment"
  environment_id           = aws_appconfig_environment.environment.environment_id

  tags = {
    Name                                      = "${var.product} Deployment"
    "${var.organization}:billing:product"     = var.product
    "${var.organization}:billing:environment" = var.environment
    creator                                   = "terraform"
    repo                                      = var.repo
  }
}

module "lambda" {
  source = "../.."

  handler  = "main.lambda_handler"
  filename = "../artifacts/app-config-handler.zip"
  runtime  = "python3.9"

  environment_vars = {
    APP_NAME = aws_appconfig_application.app.name
    # We can't directly infer the environment name like this because it
    # causes a cyclic dependency. We can just predict the name.
    ENV_NAME    = var.environment # aws_appconfig_environment.environment.name
    CONFIG_NAME = aws_appconfig_configuration_profile.config_profile.name
    FLAG_NAME   = "person"
  }

  environment  = var.environment
  product      = var.product
  repo         = var.repo
  organization = var.organization
}
