terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [
        aws.us_east_1
      ]
    }
  }
}
