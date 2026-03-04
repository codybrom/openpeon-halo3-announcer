#!/usr/bin/env bash
# Compute sha256 hashes for all sound files and update openpeon.json
# Run this after placing .wav files in the sounds/ directory

set -euo pipefail
cd "$(dirname "$0")"

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

tmp=$(mktemp)
cp openpeon.json "$tmp"

for mp3 in sounds/**/*.mp3 sounds/*.mp3; do
  [ -f "$mp3" ] || continue
  hash=$(shasum -a 256 "$mp3" | awk '{print $1}')
  # Update the sha256 field for this file in the JSON
  jq --arg file "$mp3" --arg hash "$hash" '
    .categories |= with_entries(
      .value.sounds |= map(
        if .file == $file then .sha256 = $hash else . end
      )
    )
  ' "$tmp" > "${tmp}.new" && mv "${tmp}.new" "$tmp"
  echo "$mp3 -> $hash"
done

mv "$tmp" openpeon.json
echo "Done! openpeon.json updated with sha256 hashes."
