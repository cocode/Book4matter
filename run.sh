#!/usr/bin/env bash
# Host wrapper: build the Docker image if needed, then run bf inside it with the
# current directory mounted at /work. Nothing is installed on the host.
set -euo pipefail

IMAGE="book4matter"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rebuild=0
if [[ "${1:-}" == "--rebuild" ]]; then rebuild=1; shift; fi

if [[ "$rebuild" == "1" ]] || ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "Building $IMAGE image..." >&2
  docker build -t "$IMAGE" "$HERE"
fi

# Always mount the current directory at /work (book sources and build output).
mounts=(-v "$PWD:/work")

# An input file passed as an argument may live outside the current directory
# (e.g. a .docx in ~/Documents). The container can only see mounted paths, so
# bind-mount the parent directory of any such file read-only at its real path,
# letting bf read it. Files already under $PWD are covered by the /work mount.
seen=":"
for arg in "$@"; do
  if [[ -f "$arg" ]]; then
    dir="$(cd "$(dirname "$arg")" && pwd)"
    case "$dir/" in
      "$PWD"/*) ;;  # already visible under /work
      *)
        if [[ "$seen" != *":$dir:"* ]]; then
          mounts+=(-v "$dir:$dir:ro")
          seen="$seen$dir:"
        fi
        ;;
    esac
  fi
done

exec docker run --rm "${mounts[@]}" -w /work "$IMAGE" "$@"
