#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FILE="$ROOT/assets/how-to-make-your-own-ai.mp4"
TAG="readme-video"
ASSET_NAME="how-to-make-your-own-ai.mp4"
REPO="${GITHUB_REPOSITORY:-KutuGondrong/ai-template-teristimewa}"
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

if [ ! -f "$FILE" ]; then
  echo "Missing video: $FILE"
  exit 1
fi

if [ -z "$TOKEN" ] && command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1 || \
      gh release create "$TAG" --repo "$REPO" --title "README video" --notes "Tutorial video for README embed."
    gh release upload "$TAG" "$FILE" --repo "$REPO" --clobber
    echo
    echo "Uploaded. README video URL:"
    echo "  https://github.com/${REPO}/releases/download/${TAG}/${ASSET_NAME}"
    exit 0
  fi
fi

if [ -z "$TOKEN" ]; then
  echo "GitHub README only plays video from GitHub-hosted URLs (not repo paths)."
  echo
  echo "Option A — no token (easiest):"
  echo "  1. Open https://github.com/${REPO}/edit/main/README.md"
  echo "  2. Delete the old <video> block"
  echo "  3. Drag $FILE into the editor"
  echo "  4. Wait for upload, then Commit"
  echo
  echo "Option B — this script:"
  echo "  export GITHUB_TOKEN=ghp_...   # PAT with repo scope"
  echo "  ./scripts/publish-readme-video.sh"
  exit 1
fi

api() {
  curl -fsSL \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$@"
}

release_json="$(api "https://api.github.com/repos/${REPO}/releases/tags/${TAG}" 2>/dev/null || true)"
if [ -z "$release_json" ] || echo "$release_json" | grep -q '"message": "Not Found"'; then
  release_json="$(api -X POST "https://api.github.com/repos/${REPO}/releases" \
    -d "{\"tag_name\":\"${TAG}\",\"name\":\"README video\",\"body\":\"Tutorial video for README embed.\"}")"
fi

release_id="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])' <<<"$release_json")"
upload_url="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["upload_url"].split("{")[0])' <<<"$release_json")"

asset_json="$(api -X POST \
  -H "Content-Type: video/mp4" \
  --data-binary @"$FILE" \
  "${upload_url}?name=${ASSET_NAME}")"

asset_url="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["browser_download_url"])' <<<"$asset_json")"

echo "Uploaded: $asset_url"
echo
echo "Put this in README.md and README.id.md:"
echo "  <video controls width=\"100%\" src=\"${asset_url}\"></video>"
