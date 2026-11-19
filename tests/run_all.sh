#!/usr/bin/env bash
# The test suite, in order. The load check runs first and stops everything if any script or scene
# fails to parse or load. glass_check needs a window; the rest run headless.
# bash tests/run_all.sh   (GODOT=<path to the Godot console exe>, default: the WinGet install)
cd "$(dirname "$0")/.."
G="${GODOT:-$LOCALAPPDATA/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe}"
mkdir -p build
# REPLY 36: a finished match deletes the Continue save even in tests, so keep the real one aside and put it back
# however the suite ends (the game itself is unchanged)
U="${APPDATA:-$HOME/.local/share}/Godot/app_userdata/Sinners' Gambit"
if [ -f "$U/save.json" ]; then
	cp "$U/save.json" build/continue_save.json
	trap 'cp build/continue_save.json "$U/save.json" && echo "Continue save restored"' EXIT
fi
if ! "$G" --headless --path . --script res://tests/load_check.gd > build/t_load_check.log 2>&1; then
	grep "LOAD CHECK" build/t_load_check.log
	echo "STOPPED: fix the load errors first"
	exit 1
fi
grep "LOAD CHECK" build/t_load_check.log
fail=0
run() {  # name, then extra args
	local t=$1; shift
	if timeout 600 "$G" "$@" --path . --script "res://tests/$t.gd" > "build/t_$t.log" 2>&1 && ! grep -qE "SCRIPT ERROR|FAILED" "build/t_$t.log"; then
		echo "ok   $t: $(grep -iE 'pass' "build/t_$t.log" | tail -1)"
	else
		echo "FAIL $t (build/t_$t.log)"; fail=1
	fi
}
for t in ui_autoplay table_check v5_check replay_check tutorial_check terms_check lines_check save_check; do run $t --headless; done
if timeout 600 "$G" --headless --path . --script res://tests/table_play_check.gd -- --table > build/t_table_play_check.log 2>&1 && grep -q "TABLE PLAY PASSED" build/t_table_play_check.log && ! grep -qE "SCRIPT ERROR|FAILED" build/t_table_play_check.log; then
	echo "ok   table_play_check: $(grep 'PASSED' build/t_table_play_check.log)"
else
	echo "FAIL table_play_check (build/t_table_play_check.log)"; fail=1
fi
# REPLY 35: the table's pace, taps that finish one beat only, and Continue's pace once caught up
run_table() {  # name, then the PASSED word
	local t=$1
	if timeout 600 "$G" --headless --path . --script "res://tests/$t.gd" -- --table > "build/t_$t.log" 2>&1 && grep -q "$2" "build/t_$t.log" && ! grep -qE "SCRIPT ERROR|FAILED" "build/t_$t.log"; then
		echo "ok   $t: $(grep -E 'pace at|decision|PASSED' "build/t_$t.log" | tail -2 | head -1)"
	else
		echo "FAIL $t (build/t_$t.log)"; fail=1
	fi
}
run_table table_pace_check "TABLE PACE PASSED"
run_table table_tap_check "TABLE TAP PASSED"
run_table resume_pace_check "RESUME PACE PASSED"
run table_tap_check --headless  # off the table, a double tap still skips to my decision
run glass_check
exit $fail
