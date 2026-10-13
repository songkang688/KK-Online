#!/usr/bin/env bash
# KK Online — smoke public URL: GET / , optional /health , optional POST
# Usage:
#   bash smoke-http.sh https://example.up.railway.app
#   bash smoke-http.sh https://example.up.railway.app /api/dehighlight /path/to/sample.png
set -euo pipefail

BASE="${1:-}"
POST_PATH="${2:-}"
POST_FILE="${3:-}"

if [[ -z "$BASE" ]]; then
  echo "Usage: $0 <base-url> [post-path] [file-for-multipart]" >&2
  exit 2
fi

BASE="${BASE%/}"
fail=0

echo "== GET $BASE/ =="
code=$(curl -sS -o /tmp/kk-smoke-root.body -w "%{http_code}" --max-time 120 "$BASE/" || echo "000")
echo "HTTP $code"
if [[ "$code" != "200" && "$code" != "302" && "$code" != "301" ]]; then
  echo "FAIL: / expected 2xx/3xx" >&2
  fail=1
fi

echo "== GET $BASE/health =="
hcode=$(curl -sS -o /tmp/kk-smoke-health.body -w "%{http_code}" --max-time 60 "$BASE/health" || echo "000")
echo "HTTP $hcode"
if [[ "$hcode" == "200" ]]; then
  head -c 400 /tmp/kk-smoke-health.body; echo
elif [[ "$hcode" == "404" ]]; then
  echo "(no /health — skip)"
else
  echo "WARN: /health unexpected $hcode" >&2
fi

if [[ -n "$POST_PATH" ]]; then
  echo "== POST $BASE$POST_PATH =="
  if [[ -n "$POST_FILE" && -f "$POST_FILE" ]]; then
    pcode=$(curl -sS -o /tmp/kk-smoke-post.body -w "%{http_code}" --max-time 180 \
      -F "file=@${POST_FILE}" "$BASE$POST_PATH" || echo "000")
  else
    pcode=$(curl -sS -o /tmp/kk-smoke-post.body -w "%{http_code}" --max-time 180 \
      -X POST "$BASE$POST_PATH" || echo "000")
  fi
  echo "HTTP $pcode"
  ctype=$(file -b --mime-type /tmp/kk-smoke-post.body 2>/dev/null || true)
  echo "body mime: $ctype size: $(wc -c </tmp/kk-smoke-post.body)"
  if [[ "$pcode" != "200" ]]; then
    echo "FAIL: POST expected 200" >&2
    fail=1
  fi
fi

if [[ "$fail" -ne 0 ]]; then
  echo "SMOKE FAILED" >&2
  exit 1
fi
echo "SMOKE OK"
