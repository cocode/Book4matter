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

# Mount the current directory at /work. The build commands (print/pdf/epub/html)
# only ever write to out/, so mount the book sources READ-ONLY and give read/write
# to out/ alone -- the container cannot mutate the book sources. `import` is the
# exception: it writes generated chapter markdown back into chapters/, so it gets
# the book dir read-write. (out/ must exist on the host before it's mounted, or
# the bind would create it root-owned; mkdir -p makes it with the user's owner.)
cmd="${1:-}"
if [[ "$cmd" == "import" ]]; then
  # import generates chapter markdown into chapters/ and extracts the docx's
  # images into media/; it writes nothing else (its scratch markdown goes to a
  # temp file outside the tree). So mount the book read-only with read/write on
  # just those two dirs.
  mkdir -p "$PWD/chapters" "$PWD/media"
  mounts=(-v "$PWD:/work:ro" -v "$PWD/chapters:/work/chapters" -v "$PWD/media:/work/media")
else
  mkdir -p "$PWD/out"
  mounts=(-v "$PWD:/work:ro" -v "$PWD/out:/work/out")
fi

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
