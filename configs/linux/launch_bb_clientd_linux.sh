#!/bin/sh

set -eu

# Aspect is running this launch script as root without HOME env.
# Set a default value for the configuration to work.
export HOME="${HOME:-/buildbarn}"
mkdir -p ~

# Clean up stale FUSE mounts from previous invocations.
fusermount -u ~/bb_clientd || true

# Remove UNIX socket, so that builds will not attept to send gRPC traffic.
rm -f ~/.cache/bb_clientd/grpc

if [ "$1" = "start" ]; then
  # Create directories that are used by bb_clientd.
  mkdir -p \
      ~/.cache/bb_clientd/ac/persistent_state \
      ~/.cache/bb_clientd/cas/persistent_state \
      ~/.cache/bb_clientd/outputs \
      ~/bb_clientd

  # Discard logs of the previous invocation.
  rm -f ~/.cache/bb_clientd/log
  OS=$(uname) exec /usr/bin/bb_clientd /usr/lib/bb_clientd/bb_clientd.jsonnet
fi
