# Art direction (agreed with Ben 2026-11-13)

**One line:** a cursed medieval prayer book that is also a dice game. Gothic illuminated manuscript meets stained glass, HD painted, lit by a single candle.

## Palette
- Base is candlelit black: warm, never pure #000, with a vignette so the screen edges fall into darkness.
- Deep reds (oxblood, wax-seal crimson) carry UI frames and danger.
- Gold leaf is reserved for what matters: numbers, scores, multipliers. If it's gold, the player should be reading it.
- Saturated jewel colour appears only in stained glass, so each Sin's panel is the brightest thing on screen.
- Bone/ivory for dice and parchment text.

## Motifs
- Each Sin gets its own stained-glass panel: thick black leading, flat jewel-tone panes, one dominant colour per Sin, glowing as if backlit.
- UI panels are manuscript pages: illuminated drop caps, marginalia, vine-and-thorn borders, wax seals for buttons.
- Dice are carved bone: slightly yellowed, pips drilled and inked, chipped corners.
- Numbers are blackletter-flavoured but chunky and legible at a glance. Readability beats authenticity.

## Light and motion
- Everything flickers faintly like candlelight; nothing is perfectly still.
- Gold glints and shimmers on score tick-ups; glass panels flare when their Sin triggers.
- Big moments crack the leading, drip wax, scatter embers.

## Borrow Balatro's principles, not its look
- Borrow: big readable numbers, juicy score tick-ups, screen shake, every roll animated and loud.
- Don't copy: no felt table, no swirling CRT background, no joker cards.

## Tech constraints
- HD painted, not pixel art (decided 2026-11-13). Smooth filtering; no integer-scale rule.
- 2D game.
- In the juice phase, add a small 3D dice tray in a SubViewport: physics dice steered to land on the faces core/ already rolled, so sim and game stay identical.

**Gut check for any asset:** would it look at home in the margin of a 13th-century psalter, and can you read the number from across the room?

# Depth and feel (phone-first)

The game is 2D but must never look flat. Treat the screen as a lit physical object: a book on a table under a candle.

## Depth
- Layer the scene: background, glass panels, page, dice, UI, particles. Each layer gets its own parallax, driven by the gyroscope (tilt the phone, the layers shift a few pixels).
- Light it for real: normal maps on dice, page and gold, lit by a flickering candle PointLight2D. Gold leaf gets a specular glint that moves with tilt.
- Stained glass casts coloured light onto the page and dice beneath it.
- Soft drop shadows under anything that floats; shadows lengthen as things lift.
- Dust motes and embers drift in front of everything.

## Touch
- Every touchable thing responds within one frame: press squashes it down, release springs it back.
- Dice are picked up, dragged and flung, with tilt and inertia while held. No tap-to-roll button as the main input.
- Haptics on every meaningful event: light tick per score count, medium thud per die landing, heavy on big multipliers.
- Motion uses springs, not linear tweens. Nothing snaps and nothing eases identically.

## Phone constraints
- Portrait, one-thumb play; all primary actions in the bottom third.
- Respect safe areas (notch, home indicator); touch targets 44pt minimum.
- 60fps floor on a 4-year-old phone, 120Hz where available.

**Gut check:** with the sound off, does a roll still feel heavy in your hand?

# The Sins are characters, not icons

Each Sin is a figure living in its stained-glass panel, drawn like a saint in a cathedral window, but wrong. Abilities are things the Sin *does*, never a stat popping up.

## Rules
- Idle: the figure breathes, blinks and watches the dice. Eyes follow the player's finger.
- Trigger: the Sin physically performs its ability. It reaches out of the leading, breaks the frame, and touches the dice or the score. The glass flares and throws its colour across the page.
- Reaction: Sins respond to play they didn't cause. They sulk at bad rolls, lean in on big ones, glance at each other.
- Voice: one short line of marginalia text per trigger, in character. No voice acting.
- Silhouette test: each Sin is recognisable from pose and colour alone at thumbnail size.

## Character sketches (alter as needed so they fit our mechanics)
- Pride: crowned, chin up, holds a mirror; never looks at the player. Polishes a die to gold.
- Greed: hunched, too many fingers; snatches dice and counts them back out.
- Wrath: cracked glass around clenched fists; smashes a die into a better face.
- Envy: peers sideways into neighbouring panels; copies what another Sin just did.
- Gluttony: mouth too wide for the frame; swallows a die and spits out more.
- Lust: half out of the panel already; pulls dice toward each other into pairs.
- Sloth: slumped, eyes half shut; acts a beat late, with a yawn, but hits hard.

**Gut check:** could a player describe each Sin's personality after one run without reading any ability text?

# Tooling (sessions should use these)

- **SpriteCook plugin (installed):** use it for all sprite, UI-kit and animation generation instead of hand-drawing placeholder art.
  - Load `spritecook-workflow-essentials` first, then only the one skill the task needs (`generate-sprites`, `build-ui-kits`, `animate-assets`, `use-assets-in-godot`).
  - Paste the Art direction and Sins sections into every prompt, and reuse earlier approved assets as style references so everything stays one set.
  - Generation costs credits: say what you're about to generate and how many variants before doing it.
- **Godot VFX skills (`thedivergentai/gd-agentic-skills`: `particles`, `shaders-basics`):** if installed, load the matching one before writing any particle system or `.gdshader`.
- **Godot MCP (`@coding-solo/godot-mcp`):** if connected, run the scene after any visual change and check the result on screen before calling it done. One screenshot per check, smallest size that shows the effect.
- If a tool above is missing, say so in one line and carry on without it.

# App icon

- One subject, readable at 60px: a single bone die in front of a stained-glass panel, gold edge glint, candlelit black around it. No text, no logo.
- Generate with SpriteCook using approved in-game assets as the style reference, so the icon matches the game.
- Deliver one 1024x1024 master PNG: square, opaque, no rounded corners (iOS applies the mask), key detail kept inside the centre 80%.
- Produce the smaller sizes by script from the master, then check the 60px version still reads.

# iPhone layout (portrait only)

**Canvas**
- Design at 393x852pt (mock up at 1179x2556px). iPhones are about 9:19.5, taller and narrower than a 9:16 mockup.
- Safe areas: keep the top 59pt (Dynamic Island) and bottom 34pt (home indicator) free of text and controls. Background art bleeds under both.
- Must also hold up at 430pt wide (Pro Max) by scaling the dice stage, not by stretching the UI.

**Three zones, top to bottom**
1. Glance zone (top 25%): the seven Sin windows. Look-only; nothing here needs a tap during a turn. Tap-and-hold a Sin for its detail card.
2. Stage (middle 45%): dice and the turn score. Dice at least 64pt each; the score is the largest text on screen (56pt or more).
3. Thumb zone (bottom 30%): Roll and Bank, each 88pt or larger, Roll under the right thumb. Secondary seals 44pt minimum with a label.

**Text**
- Nothing below 13pt. Blackletter for numbers and headings only; sentences in a plain serif.
- Bright gold for numbers only; frames and filigree drop to dull brass.

**Touch and gestures**
- Drag dice anywhere in the stage; no gestures starting from the screen edges (they clash with iOS back and home swipes).
- Haptic on every roll, landing, strike and bank.
- Every action reachable one-handed; no two-finger gestures.

**iOS behaviour**
- 120Hz on ProMotion phones, 60fps floor elsewhere and in Low Power Mode.
- Save mid-turn on every state change; resume exactly where you left off after a call or app switch.
- Obey the silent switch; the game is fully playable muted.
- Respect Reduce Motion: swap screen shake and parallax for fades.
- A full turn takes under 30 seconds; a session works in a 2-minute gap.

**Gut check:** can you play a whole turn on the bus, one-handed, muted, in sunlight?

# Approved art (look pass step 2, 2026-11-13)
- Sin windows: `assets/art/sins/raw/<sin>_glass_raw.png` (SpriteCook, Pride window as style anchor). Read with a hard alpha cut at 0.6.
- UI kit (concept 1b, brass ornament, gold only on numbers): `assets/art/ui/*.png`; concepts and sheets in `assets/art/ui/raw/`. Names, asset IDs and sha12 in `assets/art/ui/ids.txt`; 9-slice borders listed in the SpriteCook kit manifest (kit f0bc80a6-d0b5-46dc-87f8-b08a90b687c1).
- SpriteCook gotchas: generate with pixel=false (HD painted). If pixel=true was used, it shrinks output to ~34px; fetch `raw_url` via `check_job_status(verbose=true)` for the 1024px source. Each style reference costs +8 credits. UI-kit concepts cost ~30 each.
