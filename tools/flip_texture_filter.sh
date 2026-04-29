#!/usr/bin/env bash
# Flip every Sprite2D node's texture_filter override in scenes/ between
# Nearest (0, correct for pixel art) and Linear (1, correct for SVG smoothing).
#
# Default behavior (no args): switch to Nearest. Run *after* you swap real
# pixel art in, before you commit.
#
# To go back to Linear (e.g. while editing placeholder SVGs): pass --linear.

set -euo pipefail

mode="nearest"
if [[ "${1:-}" == "--linear" ]]; then
  mode="linear"
fi

if [[ "$mode" == "nearest" ]]; then
  from="texture_filter = 1"
  to="texture_filter = 0"
  echo "Flipping all Sprite2D texture_filter overrides to Nearest (pixel-art mode)…"
else
  from="texture_filter = 0"
  to="texture_filter = 1"
  echo "Flipping all Sprite2D texture_filter overrides to Linear (SVG-smoothing mode)…"
fi

count=0
while read -r f; do
  if grep -q "^$from$" "$f" 2>/dev/null; then
    sed -i "s|^$from$|$to|g" "$f"
    count=$((count + 1))
    echo "  $f"
  fi
done < <(find scenes -name '*.tscn')

echo "Done. Updated $count scene file(s)."
echo "Remember: Godot's project default is texture_filter=$([[ "$mode" == "nearest" ]] && echo 0 || echo 1), so any new Sprite2D you add will pick that up automatically."
