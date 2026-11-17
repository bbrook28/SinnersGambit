# Packet: REPLY 25 (one style; page and table for 120; art batch 2)
**Local only, not pushed.** Suite: all pass. Text audit: 35/35 clean at se and std. Gallery goldens not re-approved (every table fixture now differs: the page).
**1. ArtDirection** (b36c444): rule 6 is now one HD painted style matching the Sin art (soft shading, the frames' gold, warm light), and woodcut ink is gone. Rule 2: table pieces painted but simpler than the glass. Rule 1 allows the page's own parchment grain.
**2. For 120** (`sheet.png`: 119 against 120, decision and a rival's turn, std row over SE row):
- 1deb61e: the page is page.jpg. 2217772: table.jpg under it, from the page's top line down.
- cc21701: light text on the page sits on a soft ink shadow (alpha 0.85, reaching 35% past the text box): stake, totals, 1000, a rival's stake and turn, the gain, the call post.
- Measured against the page with the text hidden, 6 fixtures at both sizes: lowest 4.8:1 (the gain "+130" at SE). At a shadow alpha of 0.75, my stake went from 2.2 to 7.6 and "1000" from 5.7 to 10.0. At 0.85, with the old rival colour, Gluttony's stake went from 1.6 to 6.3. The final values are darker still and were not re-measured one by one. A rival's stake colour went from 0.3 to 0.4 lightened, so Wrath, Pride and Sloth reach 5:1 by calculation; only Gluttony was rendered.
- Seen: my stake's shadow reaches over Bank's top edge. The lit-seat wedge still falls on the page over the texture. Not built: a TestFlight build needs a push.
**4. Answers:** Q3 (9414583): a rival's window is backed by its own shape in solid black, so it dims by darkening only. Q4: the black wall stays. Q2 is applied in the mock (below).
**3. Art batch 2** (`pieces.png`: pieces beside the Lust window; `masters.png`: a Sin's line, before and the three Masters; `seals_candles.png`: both seal pairs, and a bust for snuffed candles). Every generation used the Lust HD window (1971f8f9) as its style reference. Drawn by `tools/art_mock.gd`, not wired. **96 credits used** (194 left).
- Master fit, as asked: the jaw sits 8 px above a two-line plate standing on the rival windows' tops. That leaves the head 171 px (std) and 67 px (SE) from the hood box's top. So the head does not fill the hood box: its widest row at mid-skull is 135 / 239 / 153 px (std) and 53 / 94 / 60 px (SE), against hood boxes 398 and 282 px. At SE the Master is small.
- Seals: no word on the wax. The wax is 178 px across, top of the 236 px box; the word sits under it, in the box, at 48 px blackletter (Bank gold, Throw light crimson, black outline). Their contrast is not measured.
- Candles: one piece cut in two, lit and snuffed, both 203 px wide in the source; each fitted to the blockout candle's 300 px of wax.
- The hood's top: 4 px under the safe line at both sizes, as in batch 1.
**5. SpriteCook ids of kept pieces:** page 56d071ca, table ebfa78e3 (wired). Masters: crown 7a248f02, fiddle cb2feec5, pipe d519cef2. Candles a3e8ded5 (both, one image). Bank: key 453b9d40, lock abbef6fa. Throw: dice a72f0f1c, hand e53bc26b.
Parked as before: bot turn 4.6 s; Feast question wording; end-of-game track bunching.

**Questions**
1. The hood box can't hold a full head with a two-line plate under it. Fix: let the plate stand over the rival windows' top edge (layout change). Rec: yes.
2. Which Master? Rec: Master 2 (fiddle); at the same jaw line its head is the widest of the three.
3. Which seals? Rec: key for Bank, dice for Throw.
4. Wire the candles for 121? Rec: yes, with the bust's snuffed state.
5. Push and build 120 once you've played 119? Rec: yes.
