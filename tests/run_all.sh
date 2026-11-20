#!/usr/bin/env bash
# Runs every tests/*_test.gd headless; stops on the first failure.
cd "$(dirname "$0")/.."
G="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
for t in tests/*_test.gd; do
	name=$(basename "$t")
	out=$("$G" --headless --path . --script "res://tests/$name" 2>&1)
	code=$?
	echo "$out" | grep -E "^(PASS|FAIL) |_test: |SCRIPT ERROR|Parse Error|ERROR: Failed"
	if [ $code -ne 0 ] || echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then
		echo "FAILED: $name"
		exit 1
	fi
done
echo "ALL PASSED"
