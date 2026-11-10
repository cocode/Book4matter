#!/usr/bin/env bash
# Publish the committed source to Docker Hub for both supported architectures.
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
revision=$(git rev-parse --verify 'HEAD^{commit}')
changes=$(git status --porcelain=v1 --untracked-files=no)
if [[ -n "$changes" ]]; then
  printf 'Publish stopped. Commit or stash these changes first:\n%s\n' "$changes" >&2
  exit 1
fi

# Finish creating the context before starting the push. Only committed files
# are included, even if the working tree changes during the build.
archive=$(mktemp "${TMPDIR:-/tmp}/book4matter-release.XXXXXXXX")
trap 'rm -f -- "$archive"' EXIT
git archive --format=tar "$revision" > "$archive"

image=book4matter/book4matter
docker buildx build \
  --no-cache \
  --platform linux/amd64,linux/arm64 \
  --tag "$image:$revision" \
  --tag "$image:latest" \
  --label "org.opencontainers.image.revision=$revision" \
  --push - < "$archive"
