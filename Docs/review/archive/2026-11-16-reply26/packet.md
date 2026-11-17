# Packet: REPLY 26 (seals and candles wired; large fiddle Master; type sheet; idle test; strings)
**Local only, not pushed.** Suite: all pass. Text audit: 35/35 clean at se and std. Gallery goldens not re-approved (every table fixture differs).
**2. Wired** (`sheet.png`: the code before and after, 4 fixtures, std and SE):
- 794e842 seals: painted wax (key, dice) at the top of the 236 px tap box, the word under it (blackletter 48, gold / light crimson, black outline). Pressed darkens the wax; dimmed states as before.
- 85dad1b candles: painted; snuffed is darkened with no glow; the next-to-go crimson band unchanged. Lit flames no longer change shape with the Strikes taken; only the glow shrinks.
- Seen: the bust blot still covers the first candle's top; a snuffed candle's smoke rises about 70 px above its box; the seal words still sit on the ink shadows (to go in the lettering pass).
**1. Master** (`master.png`: a Sin's line, his line, his call; std row over SE row). Mock only (`tools/art_mock.gd`); TableSpec records the plate change (4d102b5).
- His hood at mid-skull spans the hood box: piece 1015 px (std), 727 px (SE). The hood's top is 2 px under the safe line at both sizes.
- The plate's top sits 8 px under his jaw and is drawn over the windows. It covers the rival windows' tops by 33 to 70 px (std) and 33 to 92 px (SE); the call's plate is the deepest.
- Seen: the fiddle, bow and hands fall behind the rival windows; the bow hand reaches the screen's right edge; in his call the blockout's raised arm and hand still show (the piece has no call pose).
**3. Type sheet** (`type.png`, nothing wired): dark ink on the page, no shadows. Lines and questions sit on a painted plate (new, 12 credits). The faces are Pirata One (blackletter) and IM Fell English (plain, numerals too); Cinzel is dropped.
- Measured against what is behind each sample with the text hidden; std and SE agree. Lowest: median 5.2:1, worst 5% 4.7:1 (Sloth's turn on the page; Lust on a plate).
- Page: stake, totals, goal 12-13:1; Bank 11.6, Throw 5.9; crimson loss and post 6.0; each Sin's turn colour darkened to 5.2-5.8. Plates: the Master's line 11.8; Sin colours lightened to 5.3-8.7; gold 9.2-9.7.
- Seen: IM Fell's numerals are old-style (the 3 in 230 drops below the line).
**4. Idle test** (`clip.mp4` 5 s on table_master std; `idle_strip.png`: the still, then 8 frames). One 8-frame loop: **20 credits**.
- Frames are 640 px; at std the Master shows at 1015 px, 1.6x up. Frame 0 differs from the still by a mean 5.7/255; the head bobs 14 px in the frame. The framing and design hold.
- Cost: a speaking motion or a mark/call gesture is 20 credits per 8-frame loop each (same engine). Not made.
**5. Strings** (`strings.md`): 567 lines from `tools/strings_export.gd`, grouped Master, each Sin, questions (file:line), labels, rulebook, log, tutorial. No wording changed.
**Credits:** 32 used (162 left). Kept ids: idle de061633, plate 8de13e46; seals 453b9d40, a72f0f1c; candles a3e8ded5; Master cb2feec5; page 56d071ca; table ebfa78e3.

**Questions**
1. Wire the fiddle Master at this size for 121, with the plate under his jaw? Rec: yes, his call shown by the plate alone until a call gesture exists.
2. Adopt the type sheet (dark ink on the page, painted plates, two faces, no shadows)? Rec: yes.
3. Idle: the generated loop, or the still moved in Godot (breath, sway)? Rec: Godot on the still (stays sharp at 1015 px); spend credits on the speak and call gestures (40).
4. Numerals in IM Fell's old-style figures? Rec: yes, to keep two faces.
