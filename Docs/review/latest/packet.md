# Packet: REPLY 20 confirm (rival plate, top row; nothing built)
REPLY 19's two questions are still open; nothing from 19 or 20 is built.

**Why it runs off:** the plate is 566 px wide (stake 270 + 3 marks + the 110 px seal + pads), but its clamp keeps only 400 px from the page's right edge (`table_blockout.gd` ~305). The seal was added beside the marks later and the clamp wasn't widened. At 7 seats, windows 5 and 6 overflow; at 4 seats, window 3 cuts the seal. The spoken line uses the same spot (`sr.end.y - 130`), so the two always collide on a rival's own line.

**Your lines:**
- Touches: correct. Add the stake ring when a rival's power takes the stake (Cash Out, Hubris), which is placed off the plate. Add the candle flash and bust shake in `table_play._animate` (skipped on rivals' turns today). Add fixtures `table_rival_4/7`, `table_rival_seal_*`, `table_power_rival`, `table_speech`, and TableSpec.
- Could break: correction: neither option touches REPLY 16's windows (both move off the row onto the page). The track at 7 seats: B's strip sits just under my marker's number (close at SE). The mark arm: not touched (both are below the row).
- Missed: in A, the page's candles and seal would show the rival's on their turn, not mine. Whose Strikes they are must read from colour and the name tag.

**Shots now** (each window active, 4 and 7 seats, a line from the active Sin): `now_4_std/se`, `now_7a_std/se` (windows 1-3), `now_7b_std/se` (4-6).
**Mockups** (flat, over a shot with the plate removed): `sheet.png` (std: 7 seats window 5, 4 seats window 3: now, A, B), `sheet_se.png` (7 seats windows 1 and 5).
- **A, the rival plays on my page:** its stake where mine sits (in its colour, "Pride's turn" above), its Strikes on the candles, its seal in my seal's place. The spoken line goes in the gap between the track and the dice, for every speaker.
- **B, a strip under the track:** stake, 3 marks and seal on an ink strip between my marker and the dice, under the active window, clamped on screen. The spoken line goes on the Master's plate spot (robe, above the rivals' tops; his and a Sin's line already clear each other). My candles and seal stay mine.

**What I see:** in A at SE, the stake's "180" sits on the top edge of the dimmed Bank button. In B at SE, the strip's top is about 10 px under my marker's "340", and the line's plate overlaps the hood's lower edge when window 1 is active.

**Questions**
1. A or B? Rec: A. Whoever throws owns the page, so there's one place to look for stake, Strikes and seal, and it needs no new space.
2. A line from a Sin that isn't throwing (a reaction): same spot, with that Sin's sigil beside it? Rec: yes. Colour alone won't tell 7 seats apart.
