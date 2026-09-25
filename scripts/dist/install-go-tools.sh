#!/usr/bin/env bash
# Installs development tools for Go on Linux.
# bash <(curl -s https://raw.githubusercontent.com/photoprism/photoprism/develop/scripts/dist/install-go-tools.sh)
PATH="/usr/local/sbin:/usr/sbin:/sbin:/usr/local/bin:/usr/bin:/bin:/scripts:/usr/local/go/bin:/go/bin:$PATH"
# Abort if not executed as root.
if [[ $(id -u) != "0" ]]; then
  echo "Usage: run ${0##*/} as root" 1>&2
  exit 1
fi
if ! command -v go &> /dev/null
then
    echo "Go must be installed to run this."
    exit 1
fi
# Determine target architecture.
if [[ $PHOTOPRISM_ARCH ]]; then
  SYSTEM_ARCH=$PHOTOPRISM_ARCH
else
  SYSTEM_ARCH=$(uname -m)
fi
DESTARCH=${BUILD_ARCH:-$SYSTEM_ARCH}
if [ -d "/go" ]; then
  GOPATH="/go"
elif [[ -z $GOPATH ]]; then
  GOPATH=$(go env GOPATH)
fi
set -e
mkdir -p "$GOPATH/src"
# go_install retries "go install" up to 3 times on transient failures.
go_install() {
  local retries=3
  local delay=2
  local attempt=1
  while true; do
    echo "  -> go install $* (attempt ${attempt}/${retries})"
    if GOBIN="/usr/local/bin" go install "$@"; then
      return 0
    fi
    if (( attempt >= retries )); then
      echo "  -> failed to install $* after ${retries} attempts" 1>&2
      return 1
    fi
    echo "  -> retrying in ${delay}s..."
    sleep "$delay"
    (( attempt++ ))
  done
}
# Install remaining tools in "/usr/local/bin".
case $DESTARCH in
  arm | ARM | aarch | armv7l | armhf)
    echo "Installing Go tools for ${DESTARCH^^} in /usr/local/bin..."
    go_install golang.org/x/tools/cmd/goimports@latest
    go_install github.com/psampaz/go-mod-outdated@latest
    go_install github.com/kyoh86/richgo@latest
    go_install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest
    ;;
  *)
    echo "Installing Go tools for ${DESTARCH^^} in /usr/local/bin..."
    go_install golang.org/x/tools/cmd/goimports@latest
    go_install golang.org/x/tools/cmd/godoc@latest
    go_install golang.org/x/tools/gopls@latest
    go_install github.com/psampaz/go-mod-outdated@latest
    go_install github.com/mikefarah/yq/v4@latest
    go_install github.com/kyoh86/richgo@latest
    go_install github.com/muesli/duf@latest
    go_install github.com/go-delve/delve/cmd/dlv@latest
    go_install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest
    go_install github.com/google/go-licenses@latest
    go_install github.com/swaggo/swag/cmd/swag@latest
    go_install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
    go_install github.com/mgechev/revive@latest
    ;;
esac
chmod -R a+rwX "$GOPATH"
echo "Done."
