#
# File: common.bash
#
# Common bash routines.
#

# Script directory:
_sdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# debug "msg"
# Write a debug message to stderr.
debug()
{
  if [ "$VERBOSE" == "true" ]; then
    echo "DEBUG: $1" >&2
  fi
}

# err "msg"
# Write and error message to stderr.
err()
{
  echo "ERROR: $1" >&2
}

if [[ "$OSTYPE" == "linux-gnu" ]]; then
  export GVM_ARCH="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  export GVM_ARCH="darwin"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
  export GVM_ARCH="freebsd"
else
  err "Unknown OS"
  exit 1
fi

# get_go_version
# Read the project's Go version and return it in the GO_VERSION variable.
# On failure it will exit.
get_go_version() {
  GO_VERSION=$(cat "${_sdir}/../.go-version")
  if [ -z "$GO_VERSION" ]; then
    err "Failed to detect the project's Go version"
    exit 1
  fi
}

jenkins_setup() {
  : "${HOME:?Need to set HOME to a non-empty value.}"
  : "${WORKSPACE:?Need to set WORKSPACE to a non-empty value.}"

  if [ -z ${GO_VERSION:-} ]; then
    get_go_version
  fi
  
  # Setup Go.
  export GOPATH=${WORKSPACE}
  export PATH=${GOPATH}/bin:${PATH}
  
  curl -sL -o ${WORKSPACE}/bin/gvm https://github.com/andrewkroh/gvm/releases/download/v0.1.0/gvm-${GVM_ARCH}-amd64
  chmod +x ${WORKSPACE}/bin/gvm
  eval "$(gvm ${GO_VERSION})"
  go version

  # Workaround for Python virtualenv path being too long.
  export TEMP_PYTHON_ENV=$(mktemp -d)
  export PYTHON_ENV="${TEMP_PYTHON_ENV}/python-env"

  # Write cached magefile binaries to workspace to ensure
  # each run starts from a clean slate.
  export MAGEFILE_CACHE="${WORKSPACE}/.magefile"
}

docker_setup() {
  OS="$(uname)"
  case $OS in
    'Darwin')
      # Start the docker machine VM (ignore error if it's already running).
      docker-machine start default || true
      eval $(docker-machine env default)
      ;;
  esac
}
