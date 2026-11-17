# Packet: REPLY 33 (plate fixes, Wrath wired, Master ring gap, Greed B redo, frame composite)
**Local only, not pushed. 0 credits (126 left).** Suite: all pass (load check, then 9 tests). Text audit: 35/35 clean at se and std. Lock: OK at std and SE.
**33.2 Wrath** (f0400b4; `wrath_edges.png`: 2x crops of both frame edges, before and after cleanup).
- `wrath.png` itself is edited: the glass moved up 56 px, no scaling, at every size (active, rival, lancet).
- Leftovers' cause was that the frame split took any gold near the edge, including his arm's highlights. Now it takes only gold joined to the rim, plus the lead along its inner edge.
- Script: `tools/wrath_glass_shift.py`. The icon does not use Wrath.
**33.1 Sin plates** (ad3b602; `sin_plates.png` = the 16 cases from the real build, after Wrath).
- A rival's plate stays on its own side of the active window. It starts at its own window's edge away from the active window and grows over the other rivals. Greed (std_5, se_5) now starts at 444, 18 px past Lust's window. Every plate keeps 18 layout px from the screen edges (12 px at SE).
- Track clearance is unchanged: the plate foot is at y 892, the first label at 936 (std). No plate touches the Master's mask box.
- Faces at SE, 2 lines: Wrath (se_6) clear, the plate's top 7 px below his chin. Gluttony (se_8): the plate covers the bottom ~15 px of his chin and the die at his mouth. Not fixed, as asked.
**33.3 Master mark at std** (6ecf94a). "Gluttony leads. No chain." does not fit on one line 12 px short of the ring: it would need 39 px more room (the active window bounds the left side). Following item 3, it stays on one line and still reaches 27 px into the ring's box. At SE the one-line plate already covers the ring. The gap does apply to a mark whose line fits.
**33.4 Greed B redo** (`greed_dice.png`: before | B redo at active, rival and lancet size, plus a 5x zoom; not wired).
- Each die is outlined by hand. The cause: colour alone cannot tell a shaded die face from his skin, which is what put flecks on his hand.
- Faces are three flat steps of amber and gold, with a dark lead rim round each die and a thinner line between faces.
- Pips stay on the front four dice. Some of their pips are lost too. The die behind his lower hand is still muddled.
**33.5 Frame composite** (`frame.png`: today | try 2 | composite | composite with the SE lock boxes; `composite_750.png`; a mock, not wired).
- From try 2: the page, border, dice, rose seal, Bank, Throw and candles. From the build, unmoved: everything above the page, the track, the stake and the seal words.
- New by script (PIL here; Godot when wired): a soft elliptical window light and a stone arch round the Master's head box.
- Not exactly in its lock box:
  - The rose seal's wax is about 8 px wider than its box on each side. "1000" runs under try 2's border; the border is ~26 px wide inside the page box.
  - The arch is drawn over his crown of roses, and its legs stop at the rival tops.
- Try 2's baked hard light still shows faintly along its old right edge and on the page's top border.
- Medallion quote: one sheet of seven painted tokens plus a brass pointer, transparent, 2K: 22 credits (GPT 2.5 Flare). Not generated.
**33.6** Menus and tracery on hold; the table-size control stays.

**Questions**
1. Gluttony's chin at SE (se_8, ~15 px under his plate): crop his glass up like Wrath's, or let the plate stand? Rec: let it stand; his eyes and open mouth still show.
2. Std mark line: accept it reaching into the ring, or shorten the line? Rec: accept.
3. Make the medallion sheet (22 credits)? Rec: yes, after you approve the composite.
4. Greed B: wire it as it is? Rec: no, one more pass on the front pips and the die behind his hand.
