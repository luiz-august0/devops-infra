terraform {
  backend "s3" {
    bucket  = "terraform-state-devops-infra-841702866860-us-east-1-an"
    key     = "devops-infra/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}