# Main screen visual audit (mockup v2, 2026-11-13)

Ben's audit of UI kit concept 1b (`assets/art/ui/raw/concept_1b.png`). Note: it judges the concept's own Sin busts; the game uses the seven approved windows in `assets/art/sins/raw/`.

Style decision: HD painted, not pixel art. (Applied to ArtDirection.md.)

## Fix first
1. The parchment panel is the brightest mass on screen and pulls the eye off the dice and score. Darken and age it.
2. Roll and Bank look identical. Give the primary action its own weight or wax colour.
3. Strikes use the same red wax seal as buttons, so they look tappable. Use a different object.
4. Redo on the iPhone canvas (1179x2556) with safe areas clear.
5. Fix the eight-pip die before this becomes a reference image.

## Hierarchy and composition
- Squint test order is currently: parchment, candle, Sin row, score, dice. It should be score, dice, Roll, Sin row.
- The "Your turn" banner is still the second-loudest element; shrink it or fold it into the Pride card.
- The active-player glow from v1 is gone. Restore it on the Pride window.
- Bank and Roll sit off-centre because the small seals crowd the right; rebalance the row.
- Imp and skeleton marginalia are charming but squeeze the buttons. Push them smaller and fainter.

## Colour and light
- Red is overloaded: banner, all seals, strike marker and Wrath. Keep red for actions only.
- The player's colour (purple) stops at the card. Carry it into the stage as an accent so the screen feels like Pride's turn.
- The candle is the only light source but nothing is lit by it. Light dice and frames from the right, with shadows falling left.
- Greed's yellow sits too close to both Gluttony's orange and the gold numbers.
- Bright gold on numbers only; this is nearly right now, keep it.

## Depth and materials
- The dice stage is a flat dark rectangle. Give it a material (worn leather, slate, wood), an inner shadow and real dice shadows.
- Four different frame styles are in use (pipe, banner, torn parchment, scroll). Cut to two.
- The mockup is one flat painting. For parallax and lighting, every element needs to be produced as its own layer: background still life, frames, dice, seals, Sin windows.

## Type and icons
- Blackletter for numbers and headings works. "Gluttony" is cramped in its panel; tighten the face or widen the plate.
- Log text, dice counts and "unlocks at 500" are under 13pt.
- Label the Strikes row.
- Sins are told apart by colour alone. Give each a sigil for the log and small sizes.

## Characters
- Gluttony, Envy and Lust pass the silhouette test; use them as the bar.
- Greed and Wrath are both front-facing bald men. Give Greed a hunched, grasping pose.

## Phone fit
- Fine filigree and leading lines will turn to noise at phone size. Simplify ornament into fewer, bigger shapes.
- Dark, low-contrast UI washes out in daylight. Check the score, dice pips and button labels at full sun brightness.
- Secondary seals and Fast Bots are under 44pt; Fast Bots sits on the home-indicator corner.
- Keep all text live, not painted into the art.

## v3 board audit (Ben, 2026-11-13, on commit 21ca13b)

Fix first
1. Dice are flat placeholders (white vector squares, red dots), small in an empty stage. Need bone dice, ~2x size, shadows on the leather.
2. Numeral font unreadable: blackletter 0 is a hollow rectangle ("+0" reads "+D", "20" as "2D"); "This turn o" uses a different, letter-like zero. All numbers in one clear display serif in gold; blackletter for words only.
3. Sin windows went dark: lost the backlit glow, murkier than the UI. Greed went grey and lost its colour. Dim inactive Sins slightly; they should still be the most saturated things on screen.
4. Depth gone: no candle, still life or directional light from the mockup; plain brown gradient; score is flat yellow with no gold-leaf shading.

Then
- Bottom panel: three lines of small low-contrast text; "or throw fewer" nearly invisible; first line runs into the right marginalia.
- Log scroll is a big bright bar for one short string: shrink or darken.
- "You" plate is red while your Sin is purple: match the banner.
- Blackletter capitals unreadable at plate size ("Lust" -> "Iust", "Greed" -> "6reed").
- Dice state shown by a red outline (flat-UI idiom): show it in-world, raised and lit vs sunk and shadowed.
- Bank, Roll and the 1/2 seals float far apart; small seals borderline for touch. Tighten into one cluster.
- Drop-cap "Y" detached from "our turn", reads as two words.
