output "arn" {
  value = module.lambda.arn
}

output "name" {
  value = module.lambda.name
}

output "invoke_arn" {
  value = module.lambda.invoke_arn
}

output "qualified_arn" {
  value = module.lambda.qualified_arn
}

output "ecr_repo_url" {
  value = module.ecr.repo_url
}
