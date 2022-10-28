terraform {
  required_version = ">= 1.3.1"
  required_providers {
    # tflint-ignore: terraform_unused_required_providers
    aws = {
      version = ">= 4.37.0"
    }
  }
}
