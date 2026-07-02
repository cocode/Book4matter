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

# Mount the whole tree at /work READ-ONLY, then make writable only the *target
# book's* writable subdirs -- so the container can never mutate the book sources
# (or anything outside the book being built). The target book dir is taken from
# the arguments: the last argument that is an existing directory, defaulting to
# "." (run from inside the book). This is why both forms work and each exposes
# exactly one book's out/:
#     ./run.sh print docs/          # from the repo root
#     (cd docs && ../run.sh print)  # from inside the book
# The subcommand is args[0]; skip it so a CWD subdir that happens to share a name
# with a subcommand (a "print" folder, say) can't be mistaken for the book.
# (mkdir -p first so the bind mounts are owned by the user, not created
# root-owned by Docker.)
args=("$@")
bookdir="."
for ((idx = 1; idx < ${#args[@]}; idx++)); do
  a="${args[idx]}"
  if [[ "$a" != -* && -d "$a" ]]; then bookdir="${a%/}"; fi
done
# Path prefix into the book dir ("" when building from inside it).
if [[ "$bookdir" == "." ]]; then bd=""; else bd="$bookdir/"; fi

cmd="${1:-}"
if [[ "$cmd" == "import" ]]; then
  # import generates chapter markdown into <book>/chapters and extracts the
  # docx's images into <book>/media; it writes nothing else (its scratch
  # markdown goes to a temp file outside the tree). So mount the tree read-only
  # with read/write on just those two dirs.
  mkdir -p "$PWD/${bd}chapters" "$PWD/${bd}media"
  mounts=(-v "$PWD:/work:ro"
          -v "$PWD/${bd}chapters:/work/${bd}chapters"
          -v "$PWD/${bd}media:/work/${bd}media")
else
  # Build commands (print/pdf/epub/html) only ever write to <book>/out.
  mkdir -p "$PWD/${bd}out"
  mounts=(-v "$PWD:/work:ro" -v "$PWD/${bd}out:/work/${bd}out")
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
