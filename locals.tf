locals {
  name = var.name != null ? var.name : var.product

  ssm_path                            = "/${var.environment}/${local.name}"
  environment_vars                    = var.environment_vars != null ? var.environment_vars : { "SSM_PATH" = local.ssm_path }
  environment_map                     = length(local.environment_vars) == 0 ? toset([]) : toset([local.environment_vars])
  default_lambda_insights_version_x86 = "16"
  default_lambda_insights_version_arm = "1"
  lambda_insights_version             = var.lambda_insights_version != null ? var.lambda_insights_version : var.architectures == tolist(["arm64"]) ? local.default_lambda_insights_version_arm : local.default_lambda_insights_version_x86
  lambda_insights_name                = var.architectures == tolist(["arm64"]) ? "LambdaInsightsExtension-Arm64" : "LambdaInsightsExtension"
  layers                              = var.layers != null ? var.layers : ["arn:aws:lambda:${data.aws_region.current.name}:580247275435:layer:${local.lambda_insights_name}:${local.lambda_insights_version}"]
  description                         = var.description != null ? var.description : "${local.name} function"
  policy_json                         = var.policy_json != null ? var.policy_json : data.aws_iam_policy_document.default_policy_document[0].json
  role                                = var.role_arn != null ? var.role_arn : module.default_role[0].arn
  vpc_id                              = var.vpc_id != null ? var.vpc_id : var.add_vpc_config ? data.aws_vpc.vpc[0].id : null
  create_security_group               = var.add_vpc_config && var.security_group_id == null
  subnet_ids                          = var.subnets != null ? var.subnets : var.add_vpc_config ? flatten([for subnet in data.aws_subnets.private_subnets : subnet.ids]) : []
  security_group_id                   = local.create_security_group ? aws_security_group.sg[0].id : var.security_group_id
  log_group_name                      = "/aws/lambda/${local.name}"

  creator = "terraform"

  tags = merge(
    var.tags,
    {
      Name                                      = local.name
      "${var.organization}:billing:product"     = var.product
      "${var.organization}:billing:environment" = var.environment
      creator                                   = local.creator
      repo                                      = var.repo
    }
  )
}
