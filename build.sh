#!/usr/bin/env bash

if [ -n "${DEBUG:-}" ]; then
    set -x
fi
set -eu

export BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
export PIPELINE_SCRIPTS_DIR="${PIPELINE_SCRIPTS_DIR:-$BASE_DIR/.build}"

if ! [ -d "${PIPELINE_SCRIPTS_DIR}" ]; then
    git clone git@github.com:csdisco/pipeline-local.git "${PIPELINE_SCRIPTS_DIR}"
fi

source "${BASE_DIR}/build-env.sh"
source "${PIPELINE_SCRIPTS_DIR}/build-functions.sh"

#####
## Your build logic goes _below_ this line.
#####

export DOCKER_BUILDKIT=1
export LINT_PYTHON="${LINT_PYTHON:-true}"
export BLACK_FLAGS="${BLACK_FLAGS:---check --diff}"

pre-pipeline() {
  clean
  lint
  docker-build
  unit-test "$@"
  docker-push
}

clean() {
    find . -type d -name "${BUILD_DIR}" -exec rm -Rvf {} +
    find . -type d -name "${DIST_DIR}" -exec rm -Rvf {} +
}

clean_pyc() {
    set +e
    find . -name "__pycache__" -exec rm -rf {} \; >& /dev/null
    find . -name "*.pyc" -exec rm -f {} \; >& /dev/null
    set -e
}

build-image() {
    logTarget "BEGIN: building the $1 stage of $2"
    mkdir -p "${BUILD_DIR}"
    _artifactory_secret

    docker build --file "$(_dockerfile)" \
        --secret id=artifactory,src="${ARTIFACTORY_SECRET_FILE}" \
        --target "$1" \
        -t "$2" .
    logTarget "END: building the $1 stage of $2"
}

lint-python() {
    build-image "testing" "$(_testing_docker_image)"

    logTarget "BEGIN: lint-python() running ./lint-python.sh inside $(_testing_docker_image)"
    docker run \
        --rm \
        --workdir=/app \
        --env=DEBUG \
        --entrypoint="/app/lint-python.sh" \
        "$(_testing_docker_image)" \
        "${@:-}" \
        "src/ tests/"
    logTarget "END: lint-python() running ./lint-python.sh inside $(_testing_docker_image)"
}

lint() {

    if [ "$LINT_PYTHON" = true ]; then
        lint-python "$BLACK_FLAGS"
    fi

    logTarget "BEGIN: lint() linting terraform code"
    rm -rf terraform/.terraform
    terraform fmt -check="${TERRAFORM_FORMAT_CHECK:-false}" -diff=true
    logTarget "END: lint() linting terraform code"
}


_unit-test() {

    build-image "testing" "$(_testing_docker_image)"

    logTarget "BEGIN: unit-test() running ./unit-test.sh inside $(_testing_docker_image)"
    docker run \
        --rm \
        --workdir=/app \
        --volume="${PWD}":/unit-test \
        --env=DEBUG \
        --env=JWKS_URI="https://cognito-idp.us-west-2.amazonaws.com/us-west-2_X2EDwDV1q/.well-known/jwks.json" \
        --env=OAUTH2_SERVER_URI="https://pierus-dev.auth.us-west-2.amazoncognito.com" \
        "$(_testing_docker_image)" \
         "--junitxml=/unit-test/build/reports/UnitTests.xml" \
         ${@:-}
    logTarget "END: unit-test() running ./unit-test.sh inside $(_testing_docker_image)"
}

unit-test() {
  _unit-test --cov-report=term-missing --cov=src --cov=tests --cov-fail-under=85
}

docker-build() {
    mkdir -p "${BUILD_DIR}"
    export DOCKER_BUILDKIT=1
    _artifactory_secret

    img="pierus"
    docker build \
        --file=Dockerfile \
        --secret id=artifactory,src="${ARTIFACTORY_SECRET_FILE}" \
        --force-rm \
        --iidfile="${BUILD_DIR}/$(_project_name)-${img}.docker_id" \
        --label=disco.subsys_name="${SUBSYS_NAME}" \
        --label=disco.service_name="$(_git_repo_name)" \
        --label=disco.component="${img}" \
        --target "runner" \
        --tag="$(_docker_image_tag)" \
        .
}

docker-build-client() {
    export PYTHON_SRC_DIR="${PYTHON_SRC_DIR:-/app/src}"

    build-image "client" "$(_client_docker_image)"
    docker run \
        --rm \
        --env=DEBUG \
        --env=BASE_DIR \
        --env=DIST_DIR \
        --env=BUILD_DIR \
        --env=VERSION="$(_version)" \
        --env=PYTHON_SRC_DIR \
        --volume="${PWD}":/dist \
        "$(_client_docker_image)"
}

_docker-network-name() {
  echo "pierus-${BRANCH_NAME:-local}-${BUILD_ID:-1}"
}

docker-compose() {
    ecr-login
    export WITH_RUN_BANNERS=0
    export VERSION=$(./build.sh _version)
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    export NETWORK_NAME="$(_docker-network-name)"

    command docker-compose "${@:-}"
}

docker-push() {
    ecr-login
    docker push "$(_docker_image_tag)"
}

run() {

    build-image "runner" "$(_runner_docker_image)"

    logTarget "BEGIN: run() running ./run.sh inside $(_build_docker_image)"
    echo ""
    # TODO: Handle custom ports xxx:5000
    docker run \
        -it \
        --rm \
        -v "${HOME}/.aws:/root/.aws" \
        --env=DEBUG \
        --env=PIVOT_TABLE_NAME \
        --env=PIVOT_TABLE_REGION \
        --env-file=<(env | grep -E '^AWS_') \
        -p 8080:8080 \
        "$(_runner_docker_image)" \
        ${@:-}
    echo ""
    logTarget "END: run() running ./run.sh inside $(_build_docker_image)"
}


#####
## Your build logic goes _above_ this line.
#####
_run "${@:-}"
