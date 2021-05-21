terraform {
  required_version = "0.12.31"
  backend "s3" {
  }
}

provider "aws" {
  region              = var.aws_region
  version             = "3.34.0"
  allowed_account_ids = [var.aws_account_id]
}

locals {
  source_guid = var.repo_name

  tags = {
    "source-guid"  = local.source_guid
    "env-name"     = var.env_name
    "subsys-name"  = var.subsys_name
    "service-name" = var.service_name
    "team"         = var.team_name
  }
}

