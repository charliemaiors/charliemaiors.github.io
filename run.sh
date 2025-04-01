#!/usr/bin/env bash
set -euo pipefail

MEDIUM_USER_NAME="charliemaiors"
DOCKER_CONTAINER_NAME="ruby-$(cat .ruby-version)"
DOCKER_IMAGE_NAME="ruby:$(cat .ruby-version)"

_import_from_medium(){
  bundle exec jekyll import medium --username "${MEDIUM_USER_NAME}" --canonical_link true
}

_commit_as_github_action(){
  git add .
  if ! (git diff --staged --quiet --exit-code); then
      git config --global user.name "GitHub Actions"
      git commit -m 'Import blogs from medium'
  fi
}

_serve(){
  bundle install
  bundle exec jekyll serve -o --livereload --host 0.0.0.0 "$@"
}

_serve_using_docker() {
  docker run --rm -d -p 4000:4000 -p 35729:35729 -v "$PWD":/usr/src/app -w /usr/src/app --name "${DOCKER_CONTAINER_NAME}" "${DOCKER_IMAGE_NAME}" ./run.sh serve "$@"
  docker logs "ruby-$(cat .ruby-version)" -f
}

_develop_using_docker() {
  docker run --rm -d -p 4000:4000 -p 35729:35729 -v "$PWD":/usr/src/app -w /usr/src/app --name "${DOCKER_CONTAINER_NAME}" "${DOCKER_IMAGE_NAME}" sleep infinity
  docker exec -it "${DOCKER_CONTAINER_NAME}" /bin/bash
}

_usage() {
    cat <<EOF
Usage: $0 command

commands:
  import-from-medium            Import posts from Medium using RSS feed
  commit-as-github-action       Commit the changes as GitHub action user. This will be used only in workflow
  serve                         Run development server
  serve-using-docker            Use docker to run development server
  develop-using-docker          Use docker for development
EOF
  exit 1
}

CMD=${1:-}
shift || true
case ${CMD} in
  import-from-medium) _import_from_medium ;;
  commit-as-github-action) _commit_as_github_action ;;
  serve) _serve "$@" ;;
  serve-using-docker) _serve_using_docker "$@" ;;
  develop-using-docker) _develop_using_docker ;;
  *) _usage ;;
esac