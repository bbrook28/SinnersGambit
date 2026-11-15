# table-blockout
**Changed:** the manuscript table as a flat blockout (`ui/table_blockout.gd`, six `table_*` fixtures). Five-colour palette plus the active Sin's glass, under the restraint rules; only the glass and the dice are art.
Wrath and Gluttony now use their flat portraits (`Tuning.LAYERS_PARKED`). Wrath's arms are parked beside the pinky. The rejected concepts are archived.
**Text audit:** table fixtures clean at se, std and max (6 of 6 each). Offer card: no clipped-text or safe-area flags at the three sizes. Tests pass: ui_autoplay, table, replay, tutorial, terms, lines, glass 75.
**Changed fixtures:** new: table_decision/rival/bust at 4 and 7 seats, 3 sizes (`sheet.png`, se/std/max rows, no goldens yet). Changed by the flat fallback: offer_wrath, offer_gluttony, accept_gluttony, refuse_gluttony. Pairs for the other five: `layers_vs_flat/<sin>.png`, layered left and flat right, full size.

**Pieces to paint (style reference in brackets)**
1. Dark windows: near-black glass with only the eyes or one highlight lit, x7 [`runtime/sins/<sin>.png`]
2. Track figures: one woodcut-ink climber per Sin, x7 [`runtime/marginalia/skeleton.png` line]
3. Jester: at rest, at a bust, at a big Bank [`runtime/marginalia/jester.png`]
4. Skeleton: tending and snuffing a candle [`runtime/marginalia/skeleton.png`]
5. Strike candles: lit, and snuffed with a crimson cap, flat ink [`ui/candle.png` shape, skeleton line]
6. Risk flame: calm, restless, guttering [same as 5]
7. Bank and Throw seals, flat wax in ink line [`runtime/seals/e_bank.png`, `e_throw.png`]
8. Gold tally marks; gold leaf on a scoring die [`runtime/seals/n1.png` gold leaf]
9. Strike pip bleeding red ink [`runtime/dice/1.png`]
10. Ink blot with drops [skeleton line]
11. Goal mark at the top of the track [`runtime/marginalia/pennant.png`]

**Questions**
1. Which of the other five layered portraits fall back to flat? Recommendation: any you have doubts about. The flat one is always clean.
2. On a rival's turn, my candles stay lit and the rival's Strikes show as crimson ticks under its window. Recommendation: keep it that way.
3. At a bust the blot covers the tallies but leaves the lost points showing beneath. Recommendation: hold that figure for a beat, then let the blot take it.
4. The palette has no bronze, so Bank is gold leaf here, not bronze. Recommendation: gold, since points are gold and Bank keeps them.
5. Gold on parchment alone is about 1.2:1, so the points numeral and the tallies carry an ink edge. Recommendation: keep the edge.
6. Scoring and Strike dice are marked by gold and crimson bars under them for now. Recommendation: paint the leaf and the red pip onto the dice themselves (items 8-9).
