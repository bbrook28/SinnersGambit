# Packet: REPLY 31 (target frame, SE Master plate, Sin plates, selection window, tracery plan)
**Local only, not pushed. 18 credits spent (144 left).** Suite: all pass (load check, then 9 tests). Text audit: 35/35 clean at se and std. Lock: OK at std and SE. Wired this round: item 2 only.
**31.1 Target frame** (one try; `frame.png`: today | frame | frame with the lock boxes; `target_frame.png` at 750x1334). No lettering.
- Same boxes: windows, dice, Bank and Throw, my seal, the page.
- Moved or restyled: the top band is carved stone niches. The Master is the full fiddle piece (bow and fiddle), right of and higher than his head box. The page has a gilded carved border with a deckled page inside. The track tokens are darker medallions. The dead die is cracked. The ability seal is pink wax with a rose (its die badge kept). Stake and numbers are blank.
- Not as asked: the window light is still a hard-edged polygon; the coloured bars under the dice remain; the pointer is still a pill with a triangle; the snuffed candle is ivory, not dark.
**31.2 Master plate** (67ec6c5, b90ff4f; `master.png`).
- The cause was that his breath scaled about his foot, so at SE he drew 150 px low and his plate covered his skull. His position now takes that pivot back out, so he draws where his boxes say at every size.
- Wording: "{name} leads. No chain this round." is now "{name} leads. No chain." No other line was reworded.
- Plate over the rivals: 103 to 44 px at SE (one line); 82 px at std, unchanged, where it still wraps after "No".
**31.3 Sin plates** (`sin_plates.png`, 8 cases plus each seat's longest line, std and SE; `tools/sin_plate_mock.gd`; not wired). No plate touches his skull or jaw.
- Every plate is at its own window's foot. A rival's notch points up and its window brightens.
- At std every line fits on 1-2 lines at 60. At SE only Wrath's "You burned / past Lust. / Not me." takes 3 lines; the rest take 2 at 60.
- A rival's plate now sits over the top of the page's track. At std it spans y 878-1061 and covers the rival tokens and totals.
**31.4 Selection window** (`sin_window.png`: none lit, Lust lit, Sloth lit; `tools/sin_window_mock.gd`; not wired).
- Unlit is moonlit grey with a tint of each Sin. "Choose thy Sin" and the Table of 4 / 7 control are back. Tiers are 8 px apart. Lancets are 236x423 (164x294 at 750 wide).
- Crop: 1.79:1 of the 3.4:1 windows (was 2.0:1). Most of the height goes to the plate, which carries both abilities.
- Carried over: sheen and backlight, the Recommended tag on Sloth, epithet, play, and both abilities. Cannot show in a still: the breathing glow; the "plaque" sound and sting; keyboard; Reduce Motion. These are design only until it is wired. Dots and swipe are replaced by dragging across the lancets.
- Name contrast on the plate, raised to at least 4.5:1 where it fell short: Wrath 4.1 to 4.6, Lust 4.4 to 4.6, Pride 4.3 to 4.5, Sloth 4.3 to 4.6; the rest pass as they are.
**31.5 Tracery plan** (no credits):
- Generate one lancet module: canopy and side posts, transparent, made once. Code tiles it 4 + 3 at the exact lancet rects, so the holes line up by construction. A separate outer frame and base band go around it. The other way, fitting the lancets to one generated piece, means measuring holes that drift each try.
**31.6 Menus**: on hold until the frame. Pirata stays for the title wordmark and the screen headings. **31.7 VFX notes** (line fades, token motion, the Strike box): recorded for the VFX pass, not built.
**Touches / could break**: wired code touches only the Master's position and one line of `ui/rules_text.gd` (with its fixture). It could break his placement at other sizes, which the lock, the audit and the suite cover.

**Questions**
1. Second frame try (18 credits), fixing the four "not as asked" items? Rec: yes, after your look.
2. Plates: rival plates cover the track top. Accept that while a rival speaks? Rec: yes; the track is display only.
3. Selection crop 1.79:1: move the table-size control onto the heading row to gain about 100 px of lancet? Rec: yes.
4. Tracery as one repeated lancet module plus a frame? Rec: yes.
