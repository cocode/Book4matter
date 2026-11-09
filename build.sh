#!/bin/bash

set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

./run.sh --rebuild
for book in web example novel docs; do
  ./run.sh all "$book" "$@"
done
