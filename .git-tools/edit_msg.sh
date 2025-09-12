#!/usr/bin/env bash
set -euo pipefail
file="$1"
subject=$(head -n 1 "$file" | tr -d '\r')

append_trailers() {
  local tool="Codex"
  local model="o3-mini"
  local why="$1"
  # Avoid duplicating trailers if already present
  if ! grep -q '^Tool: ' "$file"; then
    printf '\nTool: %s\nModel: %s\nWhy: %s\n' "$tool" "$model" "$why" >> "$file"
  fi
}

case "$subject" in
  "docs: add codebase review 0.1"*)
    append_trailers "Document codebase review and align with playbook"
    ;;
  feat:\ transcript\ builder*|"feat: transcript builder + plain transcript view; improved parsing"*)
    append_trailers "Add transcript rendering and improve parsing and UI"
    ;;
  *)
    # Leave other messages unchanged
    ;;
esac

exit 0
