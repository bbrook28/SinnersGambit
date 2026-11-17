# Art direction (owner of every art rule; Ben, 2026-11-13, table direction 2026-11-15)

**One line:** a cursed medieval prayer book that is also a dice game. Gothic illuminated manuscript meets stained glass, HD painted, lit by a single candle.
How the table is laid out and behaves as built: `Docs/TableSpec.md`.

## Table direction and restraint (Ben, 2026-11-15): overrides everything below
**Direction.** Played on an open page of the illuminated manuscript, by one candle, beneath the Sins' stained-glass windows. Everything is ink, parchment, wax, glass, bone or candlelight; no coins, gems, gilded frames or neon glow.
1. Turn: the active Sin's window lights and its colour falls across the page and dice; the others are dark glass.
2. Stake: one gold numeral above Bank that grows with the stake; a bust blots it with spilled ink.
3. Standing: a track across the page under the windows, one sigil marker per Sin, goal at the end.
4. Risk: my three Strike candles on the near edge, their flames steady, restless or guttering; the skeleton snuffs one per Strike, the jester reacts to busts and big Banks (neither drawn yet).
5. Dice: plain ivory, inked pips; a scoring die takes gold leaf, a Strike's pip bleeds red ink, a dead die stays plain; one lit thing at a time.
6. Decision: Bank and Throw seals on the near edge, under my thumbs.

**Restraint.**
1. At least two-thirds of the screen is darkness or plain parchment; no ornament on surfaces (no floral or vine borders, drop caps, gilded frames, texture behind text; the page's own parchment grain is allowed, REPLY 25).
2. Only the Sins' glass and the dice carry rich detail; table pieces (page, table, candles, seals, the Master) are painted but simpler than the glass, so the windows stay the richest thing on screen.
3. Palette of five: black, parchment, bone, crimson, gold leaf, plus exactly one Sin's glass colour, the active one; inactive windows near-black with only the eyes or one highlight lit.
4. Information large, plain, colour-coded: points always gold, Strikes always crimson; big numerals, short labels, space around them.
5. Few objects, each used in play: page, dice, three candles, two seals, windows, jester, skeleton.
6. One style across the game (Ben, REPLY 25, 2026-11-16): every piece HD painted to match the Sin art, with soft shading, the window frames' gold and the same warm light. Woodcut ink is dropped. No gloss, no glow beyond candlelight and light through glass.
7. Blockout in flat shapes in this palette first.

## Palette
- Base is candlelit black: warm, never pure #000, with a vignette so the screen edges fall into darkness.
- Crimson (oxblood, wax-seal) carries Strikes and danger.
- Gold leaf is reserved for what matters: points and scores. If it's gold, the player should be reading it.
- Saturated jewel colour appears only in stained glass, so the active Sin's window is the brightest thing on screen.
- Bone/ivory for dice and parchment text.

## Motifs
- Each Sin has its own stained-glass window: thick black leading, flat jewel-tone panes, one dominant colour per Sin, lit as if from behind.
- Buttons are wax seals.
- Dice are carved bone: slightly yellowed, pips drilled and inked.

## Type (Ben, 2026-11-14)
- Five sizes only in `ui/tuning.gd` (display, title, body, label, caption), 15 pt minimum on device (`tools/ui_audit.gd` MIN_FONT_PT); every label on one.
- Blackletter (Pirata One) for words at display and title size only, never under 28 pt and never for numbers; serif (IM Fell English) for the rest; numerals are Cinzel Bold (`ui/style.gd`). No other fonts in the play field.
- Letter spacing through FontVariation: blackletter +4%, small-caps labels +8%; body line height 1.3. Soft dark outline or shadow on text over art, contrast checked on the brightest and darkest backgrounds.
- Values large and bright, their labels small and muted; one emphasis per screen. One colour each for Strike, Bank, Bust and every Sin's name, everywhere.
- Text motion (manuscript; no wobble, wave, bounce or rainbow): Sin lines and offers are written on left to right with a wet edge that dries, at speaking pace; Sins differ only in ink colour and pace (Wrath fast, Sloth slow). Emphasis is one word in red ink or gold leaf. Numbers settle like a stamp (short press-in, faint gold glint); counting up is fine, shaking isn't. Text leaves by fading like drying ink. Bust, claim and win only: the lettering may flare with candlelight or bleed red once. Reduce Motion shows text at once.

## Light, motion and effects
- The candle flickers faintly; glass flares when its Sin speaks, offers or acts.
- Every effect has anticipation, impact and settle; nothing just appears. Effects scale with the event; small scores stay small.
- Nothing may hide the dice faces or the score for more than 0.3 s.
- Motion uses springs, not linear tweens; press squashes, release springs back, within one frame.
- Reduce Motion swaps shake, flashes, tilt and parallax for fades.
- Borrow Balatro's principles, not its look: big readable numbers, juicy tick-ups, every throw animated and loud. No felt table, no CRT background, no cards.

## Depth (Phase 9, `Docs/UXPlan.md`)
The game is 2D but must not look flat: a book on a table under a candle. Layers with a little parallax from device tilt; one flickering candle light; the active window's colour cast on page and dice; soft shadows under anything that lifts.

## The Sins are characters, not icons
Each Sin is a figure in its window, drawn like a saint in a cathedral window, but wrong. Abilities are things the Sin does, never a stat popping up.
- Idle: the figure breathes and watches the dice. Trigger: it acts its ability and the glass flares. Reaction: Sins respond to play they didn't cause.
- Voice: one short spoken line (`Docs/TableDesign.md` §3). No voice acting.
- Silhouette test: each Sin is recognisable from pose and colour alone at thumbnail size.
- Sketches: Pride crowned, holds a mirror, never looks at the player. Greed hunched, counts coins. Wrath clenched fists, cracked glass. Envy peers sideways, a serpent. Gluttony a mouth too wide, a goblet. Lust half out of the window, dice in hand. Sloth slumped, eyes half shut, a guttering flame.

## Phone
- Portrait, one-thumb play; primary actions in the bottom third; no gestures from screen edges, no two-finger gestures.
- Safe areas free of text and controls (art bleeds under them); touch targets 44 pt minimum.
- Haptics on throw, landing, Strike and Bank. Obey the silent switch; fully playable muted.
- 60 fps floor on the oldest supported iPhone, 120 Hz where available.
- Save on every state change and resume exactly after a call or app switch; a session works in a 2-minute gap.

## Generating art (SpriteCook)
- Load `spritecook-workflow-essentials` first, then only the one skill the task needs. Generate with pixel=false (HD painted). Reuse approved assets as style references (+8 credits each).
- Say what you'll generate and how many variants first; state the cost before any batch over 50 credits.
- Check hands, eyes and teeth on every generated portrait before showing it; regenerate failures.
- Approved sources: Sin windows `assets/art/sins/raw/<sin>_glass_raw.png` (hard alpha cut at 0.6); portraits and layers in `assets/art/sins/portrait_raw/`, baked by `tools/bake_art.gd` and `tools/bake_layers.gd`.
- App icon: one bone die before a stained-glass window, readable at 60 px, no text; one 1024 px opaque square master, smaller sizes by script.

**Gut check:** would it look at home on a 13th-century psalter page, and can you read the number from across the room?
