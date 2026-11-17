# Packet: REPLY 28-30 (Master fixes, numerals, Sin plates, menus, motion list, frame and tracery quotes)
**Local only, not pushed. 0 credits spent (162 left).** Suite: all pass (load check, then 9 tests). Text audit: 35/35 clean at se and std. Lock: the nine locked states keep their window boxes (std and SE). Page sheet (28.2) dropped per REPLY 29.
**28.3 Numerals** (ee55d18, 0790712; `sheet.png`: Pirata before over Cinzel after). The audit then caught my own fault: the choice number sat 6 px under its word (12.5-13.1 pt). Now no table text goes under 15 pt on the smallest phone (MIN_TEXT 44 px); a number is the same size as its word.
**28.4 Master** (a9a4c83; `master.png`). Mark and offer have no arm: plate and gold ring only. His plate over the rival tops: mark 82 std; **103 at SE**. His words can't step down there without going under 15 pt (Q1). At SE his skull sits under his own mark and offer plate.
**28.5** (30bdbf5, b65e6b1): a rival's stake is in ink; only "<Sin>'s turn" is coloured. "Buy dice?" drops 9 px inside its plate, off the gold border; the row keeps its height. A two-line question stays where it was (dropping it touched the buttons).
**28.6 Jaw** (cd205aa; `master.png` right): only the jaw's connected piece is kept; the chin rest's sliver and the flecks are gone. Size and hinge are unchanged.
**28.1 Sin plates** (9359854; `sin_plates.png`, mock `tools/sin_plate_mock.gd`, not wired). Recorded in TableSpec as exception 2, "sheeted, not wired". No Master plate while a Sin speaks. The border is the plate's gold recoloured to the Sin's colour.
- Active Sin: across the foot of its window, at the window's width (385 std, 276 SE). A long line wraps to 3 lines at std and **5 at SE**, covering the face; "underpriced" splits from its comma.
- Rival Sin: hung over its window, notch down. It is wider than its window (282-618 px) and sits over the band above. At std it covers the Master's jaw. At SE his face shows; the plate covers part of his crown of roses. At std the long line leaves "4." alone on a line.
**28.7 / 30.2 Motion**: `animations.md` lists the table (18 items) and the Sin selection screen (8). Not animated: candle flames, window light, track tokens (they jump), the plates.
**28.8 Menus** (`menus.png`, 18 screens, before and after; mock `tools/menu_restyle_mock.gd`, not wired).
- Painted page or plate in place of flat panels; buttons on the plate in gold Pirata; a selected toggle is the plate dyed crimson; text in IM Fell, ink on light and bone on dark.
- Screens with no flat panels (title, Sin select, offer) barely change. The Chronicle's plate stretches its wood grain full height. The accept, refuse, claim, score and end overlays are the old board's.
**29 Target frame**: not made; waiting for your word.
- Plan: Nano Banana 2.1 at 2K 9:16, built on today's std table screenshot, with the kept windows, seals and candles as references. 18 credits each; 2 tries = 36. Cut to 750x1334.
- Touches nothing in the build; files go in `Docs/review/latest/` only.
- To be restyled: the page (with frame), track, tokens, pointer, dice, window light, a third seal and the top band. I will overlay the lock boxes on the result and list every element that moved.
**30 Sin selection window** (`sin_window.png`: none lit, Lust lit top tier, Sloth lit bottom tier; mock `tools/sin_window_mock.gd`, placeholder tracery, 0 credits).
- Lancets 4 over 3, 231x463 layout px = 160x321 px at 750 wide. Each kept window is cropped from the top to 2.0:1 (they are 3.4:1), so every Sin loses the lower ~40% of its window and the bottom of its own frame.
- Unlit and lit are one shader. The plate shows the power only; the seal is the Throw art as a stand-in.
- Tracery quote: GPT 2.5 Flare 2K, transparent, the target frame as reference: 22 credits each, 2 tries = 44. Touches nothing now; wired later it touches the selection scene and its input only.

**Questions**
1. SE mark plate is 103 px over the rivals, not 92, because of the 15 pt floor: accept it, shorten that line, or tighten line spacing (91 px, letters near the gold border)? Rec: shorten that line.
2. Make the target frame: 2 tries, 36 credits? Rec: yes.
3. Make the tracery after the frame is approved: 2 tries, 44 credits? Rec: yes, after Q2.
4. A Sin's line over 2 lines on its own window (SE): show it on a plate hung from the window top, like a rival's? Rec: yes.
5. Wire the Sin plates as sheeted, with Q4? Rec: yes.
