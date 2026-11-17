#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_bin="${GODOT_BIN:-godot}"
project_path="$repo_root/ninja-matematica"

run_test() {
  local test_path="$1"
  echo "==> $test_path"
  timeout 60s "$godot_bin" --headless --path "$project_path" --script "res://$test_path"
}

echo "==> Importing Godot project"
timeout 180s "$godot_bin" --headless --path "$project_path" --import --quit

run_test tests/keyboard_test.gd
run_test tests/accessibility_flow.gd
run_test tests/trophies_test.gd
