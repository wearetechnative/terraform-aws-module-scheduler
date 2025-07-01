terraform {
  backend "s3" {
    session_name = "TerraformStateUpdate"
    region       = "eu-central-1"
    key          = "schedulermodule/terraform.tf"
  }
}

terraform {
  required_version = "< 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.22.0"
    }
  }
}
