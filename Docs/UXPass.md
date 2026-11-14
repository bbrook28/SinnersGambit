# UX / game-feel pass (plan, 2026-11-13)

Presentation and pacing only. No changes to `core/`, `sins/`, `ai/`, rules or balance.

## Why it feels instant today
- `main._process` calls `_refresh()` every frame from **live** game state, so scores, dice, Strikes and banners jump the moment the rules change them.
- The rules only pause in three places (`view.beat`: after a throw, after a bust, at the end of a turn: 0.8–1.2 s timers). Everything in between (bot decisions, rerolls, abilities, banking, buying, the Vig) happens in a single frame.
- The only feedback for most events is one line in the log strip, which the next line overwrites.

## Architecture (built first)
- **Action queue** (`ui/action_queue.gd`): every event becomes an action that plays its beat; actions run one after another. `view.beat()` (which `core/` already awaits) now waits for the queue to empty, so the rules can't get ahead of the screen. `show_prompt` is queued too, so your buttons only appear once everything before them has played.
- **Snapshots**: on every `say()` and `turn_started()` the UI copies the state it shows: scores, dice, Purgatory/tags, faces, turn points, Strikes and current player. The board draws the snapshot of the **last action played**, never the live state. The per-frame live `_refresh` goes away.
- **Event parser** (`ui/events.gd`): turns each log line (fixed formats in `core/game.gd` and `sins/*.gd`) into a typed event (kind, who, numbers), cross-checked against the snapshot diff. An unrecognised line falls back to a plain 0.25 s log beat, so a wording change in `core/` degrades gracefully instead of breaking. (Cleaner alternative: one `view.event(kind, data)` hook in `core/`. Not proposed, because `core/` is off-limits.)
- **Speed and skip**: one global speed (1x / 2x / 4x), set by the seal that replaces Fast and saved between sessions. Tapping the stage finishes the current beat instantly; tapping again skips to your next decision. Beats never shrink below 0.08 s, so even 4x stays readable.
- `sim/` and tests are unaffected (`view` is null there). `ui_autoplay` sets speed to max.

## Every event: now → proposed beat (durations at 1x)

| # | Event (source) | Now | Proposed beat | Time |
|---|---|---|---|---|
| 1 | Turn change (`turn_started`) | Banner text and window glow swap instantly | Old window dims, new one brightens with a scale pop and a light shaft onto the stage; the banner page-turns to the new Sin's colour and name. On your turn: "Your turn" holds a moment longer, with a medium haptic. | 0.6 (+0.3 yours) |
| 2 | Purgatory: Indulgence paid | Log only | "-N" pops off the plate, which counts down; the Purgatory tag breaks away | 0.5 |
| 3 | Purgatory: Redemption roll | Dice appear instantly | Dice tumble in (as #6), any 6 ignites, then a stamp: "Redeemed!" or "Still in Purgatory" | 0.5 + 0.4 |
| 4 | Before-turn ability (Pride's Hubris call) | Log, plus the new flare and note (can overlap other events) | Flare and note, queued in order. The bar ("must beat N") stays pinned on the stage for the turn. | 0.5 |
| 5 | Choose dice count, bot | Nothing (instant) | Banner: "Wrath is thinking…" with a varied pause, then "throws 4" | 0.4–0.7 + 0.3 |
| 5h | Choose dice count, you | Prompt appears the same frame | Prompt slides up only when the queue is empty; seals pop in one after another | 0.25 |
| 6 | Throw (`throws N: …`) | Dice appear instantly | Dice tumble in from the thrower's side, staggered 60 ms each; they land with a squash, a dust puff and the shadow snapping in; light shake scaled to the dice count | 0.45 + 0.06/die |
| 7 | Fury reroll (live or bounced) | Faces change instantly | Wrath flares, a red streak hits the targeted dice, they lift, spin and land showing new faces | 0.5 |
| 8 | Envy's Glance (adds a die), Lust's Whisper (swaps one) | Log and flare, but the die is already there | Flare, then a trail from that window to the die, which pops in (Envy) or flips (Lust) | 0.5 |
| 9 | Strikes counted | Nails update instantly | Each 1 or 2 flashes red in turn and a nail slams in, with a light haptic each. Sloth's Lazy Bones: the nail flies in and is shrugged off. | 0.25 per Strike |
| 10 | Bust | Log line; Purgatory tag appears | Third nail; all nails glow; the stage light gutters; the turn total burns to 0; "BUST" stamp; the window cracks; Purgatory tag; heavy haptic | 0.8 |
| 11 | Throw scored (`+N (turn …)`) | "This turn" number jumps | Scoring dice ignite one by one, each popping "+40/+50/+60" above it; the points fly to the turn total, which counts up and pulses | 0.1/die + 0.3 |
| 12 | Throw again or bank, bot | Nothing (instant) | "Wrath is thinking…", then either "throws again" (seal glow) or "banks" | 0.4–0.7 |
| 13 | Hubris pays off or fails | Log | Pays off: "x1.6" burns in on the total, which counts up. Fails: the total shatters to 0. | 0.6 |
| 14 | Binding Pact cut | Log | A slice splits off the turn total and flies to Lust's plate, which counts up "+N" | 0.5 |
| 15 | Bank | Plate score jumps | The turn total streaks as gold dust to the plate, which counts up with a "+N" popup and a pulse; medium haptic on yours | 0.6 |
| 16 | Win | Banner and prompt | Winner's window flares, the plate glows gold, the rest dim, then the prompt | 1.5 |
| 17 | Buy dice | Score and dice count jump | "-price" pops off the plate and it counts down; small dice drop onto the plate's dice count "+N" | 0.5 |
| 18 | The Vig (Greed) | Log and flare | Coins streak from the buyer's plate to Greed's; "+17 each" | 0.4 |
| 19 | Interest (Greed) | Log and flare | Flare, then "+N" on Greed's plate with a count-up | 0.4 |
| 20 | Gorge (Gluttony) | Log and flare | Folded into #17: the price shows struck through and replaced by 70 | (in #17) |
| 21 | Spark of Rage (after a bust) | Log and flare | After the bust beat: flare, then "+40" on Wrath's plate | 0.4 |
| 22 | Tier 2 attack (Fury / Pact / Drag) | Log | Attacker flares; a streak flies window to window; the target shudders; the status tag stamps onto its plate | 0.6 |
| 23 | Untouchable bounce (Pride) | Log | The streak hits Pride, a mirror flash, and it rebounds onto the attacker | 0.5 |
| 24 | Status tags (Dragged, Pact, II ready, Purgatory) | Plate text swaps instantly | Tag stamps in with a small pop, as part of the event that caused it | 0.25 |
| 25 | End of turn (`beat "end"`) | 1.0 s timer | Replaced by #1 | n/a |

## Input (rule 4)
- **Seals and plaques:** they press down on touch and spring back on release. A gloss ripple crosses the wax, with a light haptic.
- **Recommended move:** Roll gets a slow ember pulse when it's the recommended move. Bank's coins burst out on press.
- **Dice:** tap a die to lift it and see what it does ("+50" or "Strike"). There is no dragging in this game, so drop targets don't apply.
- **Targets:** when you pick a target for a Tier 2, valid Sin windows glow and can be tapped, and the rest dim. The plaques stay as a fallback.
- **Haptics:** light on press, medium on bank and your turn, heavy on a Strike nail and a bust. A Reduce Motion setting swaps shake and flashes for fades.

## Always readable (rule 5)
- The active window is lit and casts a light shaft. The banner shows whose turn it is in that Sin's colour.
- **Your turn:** the thumb zone header says what you can do ("Throw how many dice?").
- **Bot turns:** the thumb zone dims and shows "Wrath is playing · tap to speed up", with no buttons.
- The Strikes count and turn total sit on the stage at all times.

## Pace check
A typical bot turn (two throws, then bank) comes to about 6 s at 1x, so six bots take about 35 s at 1x, 18 s at 2x and 9 s at 4x. Tap-to-skip covers the rest.

## Build order (one event type at a time, Ben plays between)
1. Queue, snapshots, speed and skip. Every event gets a generic beat (log line plus a pause). Nothing jumps any more. **Done** (`ui/action_queue.gd`, `ui/events.gd`).
2. Turn change and glanceability (#1, #5, #12, rule 5).
3. Throw and dice (#3, #6).
4. Strikes and bust (#9, #10).
5. Scoring and bank (#11, #15, plus count-up and popup helpers).
6. Buying and plates (#2, #17, #18, #19, #20).
7. Abilities and attacks (#4, #7, #8, #13, #14, #21–#24).
8. Input feel (seals, haptics, dice inspect, target glow).
9. Win (#16).
