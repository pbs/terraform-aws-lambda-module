# terraform {
#   backend "s3" {
#     bucket         = "my-bucket-tfstate"
#     key            = "example-terraform-aws-lambda-app-config"
#     profile        = "my-profile"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-lock"
#   }
# }
