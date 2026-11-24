#!/usr/bin/env bash
# Imports the project, then runs every tests/*_test.gd headless; stops on the first failure.
# GODOT=<path to the Godot 4.7.2 binary> overrides the Windows path below (CI sets it).
# TEST_TIMEOUT=<seconds> for each test (default 300); a test that runs longer fails as TIMED OUT.
cd "$(dirname "$0")/.."
G="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
LIMIT="${TEST_TIMEOUT:-300}"
# macOS has no timeout unless coreutils is installed (gtimeout); with neither, the tests run without a limit.
T=""
if command -v timeout >/dev/null 2>&1; then T="timeout $LIMIT"; elif command -v gtimeout >/dev/null 2>&1; then T="gtimeout $LIMIT"; fi
# A fresh checkout has no .godot/: without an import the preloaded art fails to load.
$T "$G" --headless --path . --import >/dev/null 2>&1
code=$?
if [ $code -ne 0 ]; then
	echo "FAILED: import (exit $code)"
	exit 1
fi
for t in tests/*_test.gd; do
	name=$(basename "$t")
	out=$($T "$G" --headless --path . --script "res://tests/$name" 2>&1)
	code=$?
	echo "$out" | grep -E "^(PASS|FAIL) |_test: |SCRIPT ERROR|Parse Error|ERROR: Failed"
	if [ $code -eq 124 ]; then
		echo "TIMED OUT: $name (over $LIMIT s)"
		exit 1
	fi
	if [ $code -ne 0 ] || echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then
		echo "FAILED: $name"
		exit 1
	fi
done
echo "ALL PASSED"
