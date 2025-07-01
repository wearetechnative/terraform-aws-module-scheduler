provider "aws" {
  region              = "eu-central-1"
  allowed_account_ids = [var.aws_account_id]

  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/landing_zone_playground"
    session_name = "terraform_management_account"
  }

  default_tags {
    tags = {
      Company     = "TechnativeBV"
      IaC_Project = var.project
      Git_URL     = var.git_url
    }
  }
}
