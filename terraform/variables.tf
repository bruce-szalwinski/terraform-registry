variable "ecr_create_repo" {
  default = false
}

variable "ecr_delegated_aws_account_ids" {
  type    = list(string)
  default = []
}

variable "repo_name" {
}

variable "aws_region" {
}

variable "aws_account_id" {
}

variable "service_discovery_private_locator" {
}

variable "service_discovery_public_locator" {
}

variable "env_name" {
}

variable "environment_shortname" {
  description = "Short name used for naming the lambda in AWS, i.e. dev, test, prod-us, prod-eu"
}

variable "subsys_name" {
}

variable "team_name" {
  default = "apollo"
}

variable "service_name" {
  default = "pierus"
}

variable "pivot_table_name" {
}

variable "cognito_pool_domain" {
  description = "Cognito user pool domain"
}

variable "okta_metadata_url" {
}

variable "jwt_algorithms" {
  default = "RS256"
}

variable "alb_security_policy" {
  default = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

# TODO: REMOVE
variable "instance_type" {
}

variable "disco_build_version" {}

variable "is_github_credential_manager" {
  type    = bool
  default = false
}

variable "github_auth_token_encrypted" {
  description = "Github api token associated with github_discoci"
  default     = ""
}

variable "github_webhook_token_encrypted" {
  description = "Github webhook token shared between Jenkins and Github for webhook creation"
  default     = ""
}

variable "kms_secrets_alias" {
  default     = "secrets"
  description = "alias of the kms secrets key"
}

variable "jenkins_webhook_uri" {
}

variable "hyacinth_url" {}

locals {
  env_service_name   = "${var.service_name}-${var.env_name}"
  service_image      = "939382136538.dkr.ecr.us-west-2.amazonaws.com/${var.repo_name}:${var.disco_build_version}"
  awslogs_group      = "/ecs/${var.subsys_name}/${local.env_service_name}"
  jwks_uri           = "https://cognito-idp.us-west-2.amazonaws.com/${aws_cognito_user_pool.pool.id}/.well-known/jwks.json"
  jwt_issuer         = "https://cognito-idp.us-west-2.amazonaws.com/${aws_cognito_user_pool.pool.id}/"
  auth_base_url      = "https://${var.cognito_pool_domain}.auth.us-west-2.amazoncognito.com"
  auth_client_id     = aws_cognito_user_pool_client.okta.id
  auth_client_secret = aws_cognito_user_pool_client.okta.client_secret
  ssm_parameter_path = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.env_name}/*"
}
