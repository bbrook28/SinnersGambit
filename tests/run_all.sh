#!/usr/bin/env bash
# The test suite, in order. The load check runs first and stops everything if any script or scene
# fails to parse or load. glass_check needs a window; the rest run headless.
# bash tests/run_all.sh   (GODOT=<path to the Godot console exe>, default: the WinGet install)
cd "$(dirname "$0")/.."
G="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
mkdir -p build
if ! "$G" --headless --path . --script res://tests/load_check.gd > build/t_load_check.log 2>&1; then
	grep "LOAD CHECK" build/t_load_check.log
	echo "STOPPED: fix the load errors first"
	exit 1
fi
grep "LOAD CHECK" build/t_load_check.log
fail=0
run() {  # name, then extra args
	local t=$1; shift
	if timeout 600 "$G" "$@" --path . --script "res://tests/$t.gd" > "build/t_$t.log" 2>&1 && ! grep -q "SCRIPT ERROR" "build/t_$t.log"; then
		echo "ok   $t: $(grep -iE 'pass' "build/t_$t.log" | tail -1)"
	else
		echo "FAIL $t (build/t_$t.log)"; fail=1
	fi
}
for t in ui_autoplay table_check replay_check tutorial_check terms_check lines_check; do run $t --headless; done
if timeout 600 "$G" --headless --path . --script res://tests/table_play_check.gd -- --table > build/t_table_play_check.log 2>&1 && grep -q "TABLE PLAY PASSED" build/t_table_play_check.log; then
	echo "ok   table_play_check: $(grep 'PASSED' build/t_table_play_check.log)"
else
	echo "FAIL table_play_check (build/t_table_play_check.log)"; fail=1
fi
run glass_check
exit $fail
