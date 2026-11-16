# Packet: REPLY 22 (buy row, line rule, A2, Greed fix, live-table check, app icon)
**Local only, not pushed.** Suite: all pass. Text audit: 33/33 clean at se and std.
**1. Buy row** (c6a5f23, `buy.png`): on its own plate on the page under the track; nothing on the window band. Gain strip: buying shows no dice and no gain, so nothing meets it. End plate: a different moment, own spot. Buttons 128 px = 44 pt at SE. Still on the window band: the other choice rows (ability, targets).
**2. Line rule** (9f59eb8): every line holds `Tuning.LINE_MIN` 3.5 s (real seconds; before, bots' lines ran at bot pace). A line arriving meanwhile is dropped; his call, final round, mark and end wait. Other Master lines: one a round, the idle line included. 120 bot turns at 1x:
| seats | lines shown | dropped | waited | cut short | bot turn avg (was) |
|---|---|---|---|---|---|
| 4 | 154 | 33 (18% of arrivals) | 47 | 0 | 4.6 s (4.0) |
| 7 | 97 | 17 (15%) | 20 | 0 | 4.0 s (4.1) |
The waits are mostly his mark: it comes every round and waits behind a Sin's line. Lines that explain a power and can now drop: his "One mark. 3 and it claims." and his claim lines.
**3. A2** (ec754f9, `sheet.png` std, `sheet_se.png`; each pair before, after: rival, Greed's power on the stake, spent seal, a Sin's line). The rival's stake sits where mine does, in its colour, "<Sin>'s turn" (44 px) over it. Its Strikes snuff my candles (undimmed). Its seal: a flat disc in my seal's slot, never live, blazing as it fires. My seal is hidden. Bank, Throw and my marks dim. The rival plate is gone. Every Sin's line (rival or reacting) sits on the Master's plate spot: blackletter 60 px in its colour (lightened for 4.5:1), its sigil at the left. At SE the stake stands above Bank, as mine does. Seen: Greed's stake ring crosses the foot of "Greed's turn"; where the plate runs past the hood its black end meets the black wall, so the sigil looks off the plate.
**4. Greed** (ddfc03c): a bust after Cash Out keeps half of only the face points still in the stake. TableDesign §0 lists what a bust keeps under each power (Hubris included). Nothing else changed.
**5. Live table** (`sim/live_table.gd`, core/game.gd `play()`, the app's options, chooser(5) rivals, a Gambler seat; 2000 games, 4 seats). The Gambler is approximated as chooser(6, throw on to 1 Strike left, never banks early): it busts less than the sim's gambler.
| | leader 300+/400+/500+/600+ clear after round 3 | busts per turn |
|---|---|---|
| live table | 12.9 / 5.2 / 2.3 / 1.1 % | rivals 0.401, Gambler seat 0.431 |
| sim, plain table | 12.3 / 5.3 / 2.0 / 1.0 % | plain 0.428 |
| sim, mixed table | 13.1 / 5.4 / 2.8 / 1.1 % | gambler 0.667 |
Rounds 5.39 live, 5.36 sim. 200 games gave 13.5 / 7.0 / 3.5 / 2.0 (noise at that size).
**6. App icon** (`icons/`: six 1024 JPEGs, opaque, square; `icons/sheet.png`: 300 px views, then 60 px on dark and light grey). Not wired anywhere. Facts: 3 and 4 have white rounded corners baked in; 1, 2 and 6 show extra pips on side or top faces (1 has red pips on top). 72 credits used, 434 left.

**Questions**
1. Should "One mark. 3 and it claims." and the claim lines wait like the call? Rec: yes. They teach the chain's cost.
2. His mark's wait adds 0.6 s to a bot turn at 4 seats (none at 7). Keep it? Rec: keep it and judge on device.
3. Greed's ring over "Greed's turn": hide the label for the 0.7 s the ring shows? Rec: yes.
