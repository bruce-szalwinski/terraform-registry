#!/usr/bin/env bash

export SUBSYS_NAME="${SUBSYS_NAME:-ss-deploy}"
export DISCO_TEAM="${DISCO_TEAM:-apollo}"
export DISCO_SERVICE_NAME="${DISCO_SERVICE_NAME:-pierus}"

# Whether or not to run terraform.  By default, it runs if there is a terraform directory.  Set this to the empty string to skip.
export DO_TERRAFORM="${DO_TERRAFORM:-$(if [ -d 'terraform' ]; then echo -n 1; else echo ""; fi)}"
export TERRAFORM_IMAGE_TAG="0.12.31"


# Whether or not to run consul config.  By default, it runs if there is a config directory.  Set this to the empty string to skip.
export DO_CONSUL_CONFIG="${DO_CONSUL_CONFIG:-$(if [ -d 'config' ]; then echo -n 1; else echo ""; fi)}"
# the list of configs to run prior to your env config locally
export CONSUL_CONFIG_LIST="default.yaml"

# Whether or not to run the pre-deploy step.  By default, it runs if there is a cloudformation directory.  Set this to the empty string to skip.
export DO_PRE_DEPLOY="${DO_PRE_DEPLOY:-$(if [ -d 'cloudformation' ]; then echo -n 1; else echo ""; fi)}"
export PRE_DEPLOY_LIST="default.yaml"

# Whether or not to run the cloudformation step.  By default, it runs if there is a
# cloudformation directory.  Set this to the empty string to skip.
export DO_CLOUDFORMATION="${DO_CLOUDFORMATION:-$(if [ -d 'cloudformation' ]; then echo -n 1; else echo ""; fi)}"

# Disable unused portions of pipeline-local
export MAVEN_FUNCTIONS_ENABLED=0
export DOTNET_FUNCTIONS_ENABLED=0
