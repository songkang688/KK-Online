#!/usr/bin/env bash
# KK Online — incremental zip for UPMA merge (paths relative to site root)
# Usage:
#   cd /workspace/blog-site
#   bash /path/to/make-upma-zip.sh /workspace/out.zip projects/foo.html demos/bar.html
# Or with multiple files/dirs as remaining args.
set -euo pipefail

OUT="${1:-}"
shift || true

if [[ -z "$OUT" || "$#" -lt 1 ]]; then
  echo "Usage: $0 <out.zip> <rel-path> [rel-path...]" >&2
  echo "Run from the static site root so paths inside the zip match the site." >&2
  exit 2
fi

# refuse obvious secrets
for p in "$@"; do
  case "$p" in
    *.env|*.pem|*.key|*secret*|*token*)
      echo "Refusing path that looks like a secret: $p" >&2
      exit 3
      ;;
  esac
done

rm -f "$OUT"
zip -r "$OUT" "$@"
echo "Wrote $OUT"
unzip -l "$OUT"
