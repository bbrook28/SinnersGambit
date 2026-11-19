#!/usr/bin/env bash
# Checks Docs/review/latest/packet.md before it is committed (REPLY 36): 30 lines or fewer; no placeholder left in
# (an ALL_CAPS_TOKEN outside backticks, TODO, TBD, XXX, "<...>"); a "**Suite:**" line, if any, gives counts;
# every file it names in backticks without a folder (sheet.png, clip.mp4, proposal.md...) exists in latest/.
# bash tools/packet_check.sh   (exit 1 on any fault)
cd "$(dirname "$0")/.."
P=Docs/review/latest/packet.md
fail=0
n=$(wc -l < "$P")
[ "$n" -le 30 ] || { echo "FAULT: $n lines (30 or fewer)"; fail=1; }
plain=$(sed -E 's/`[^`]*`//g' "$P")
hits=$(printf '%s\n' "$plain" | grep -nE '\b[A-Z]{2,}_[A-Z_]{2,}\b|\bTODO\b|\bTBD\b|\bXXX\b|<[a-z][^>]*>')
[ -z "$hits" ] || { echo "FAULT: placeholder left in:"; echo "$hits"; fail=1; }
suite=$(grep -E '^\*\*Suite:\*\*' "$P")
if [ -n "$suite" ] && ! printf '%s' "$suite" | grep -qE '[0-9]+ of [0-9]+'; then
	echo "FAULT: the Suite line gives no 'N of M' count"; fail=1
fi
for f in $(grep -oE '`[A-Za-z0-9_.-]+\.(png|mp4|md|txt|json)`' "$P" | tr -d '`' | sort -u); do
	[ "$f" = packet.md ] && continue
	[ -e "Docs/review/latest/$f" ] || { echo "FAULT: names $f, not in Docs/review/latest/"; fail=1; }
done
[ $fail -eq 0 ] && echo "PACKET OK ($n lines)"
exit $fail
