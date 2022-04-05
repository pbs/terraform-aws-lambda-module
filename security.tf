data "aws_iam_policy_document" "default_policy_document" {
  count = var.policy_json != null ? 0 : 1
  statement {
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
    ]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.log_group_name}"]
  }

  statement {
    actions = [
      "kms:Decrypt",
      "ssm:GetParameter",
      "ssm:GetParametersByPath",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_path}",
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_path}/*"
    ]
  }
}

module "default_role" {
  count  = var.role_arn != null ? 0 : 1
  source = "github.com/pbs/terraform-aws-iam-role-module?ref=0.1.0"

  name = local.name

  policy_json = local.policy_json

  use_prefix               = var.use_prefix
  permissions_boundary_arn = var.permissions_boundary_arn

  aws_services = ["lambda", "edgelambda"]

  environment  = var.environment
  product      = var.product
  repo         = var.repo
  organization = var.organization
}

resource "aws_security_group" "sg" {
  count       = local.create_security_group ? 1 : 0
  description = "Controls access to the ${local.name} lambda function"

  vpc_id      = local.vpc_id
  name_prefix = "${local.name}-sg-"

  tags = merge(
    local.tags,
    { Name = "${local.name} SG" },
  )
}
