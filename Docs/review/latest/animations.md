# What animates on the table today (REPLY 28 item 7; no changes)
Seconds at 1x. "pace" = 1 on your turn, 6x faster on a bot's (Tuning.BOT_PACE). "speed" = the player's speed setting.

| What | When | How long | Where |
|---|---|---|---|
| Master breathes (0.6% taller) | always | 4.2 s loop | `table_blockout.gd` `_process`, Tuning MASTER_BREATH* |
| Master sways 0.5° | always | 6.6 s loop | same, MASTER_SWAY* |
| Master tilts his head 0.35° | always | 9.7 s loop | same, MASTER_TILT* |
| Master's jaw opens up to 5° | while his own line shows | 0.32 s per syllable, as long as the line | same, MASTER_JAW* |
| A line shows (his or a Sin's), then goes | an event with a line | holds 3.5 s (LINE_MIN, scaled by speed); appears and goes with no fade | `table_play.gd` `_show_line` |
| Seal "ready" glow: fades to 60% and shrinks to 88%, back | my seal can fire | 1.1 s loop (SEAL_READY_PULSE / speed) | `table_blockout.gd` aura tween |
| Power fires: seal swells to 130%, settles | a power fires (any seat) | 0.22 s up, 0.33 s down (SEAL_FLARE) | `table_play.gd` `power_fired` |
| Power fires: a Sin-coloured ring spreads to 3.2x and fades | same | 0.55 s | same |
| Power's ring and sigil on the dice it changed | same | held 0.7 s (POWER_FOR / speed) | same |
| Dice drop in from 160 px up, spun, fading in | each new throw | 0.22 s each, 0.04 s apart (/ pace) | `table_play.gd` `_animate` |
| Stake swells from 130% | the stake grows on the same turn | 0.3 s after 0.2 s (/ pace) | same |
| Candle flash: crimson box over the candle fades | a Strike | 0.5 s after 0.15 s (/ pace) | same |
| Page shakes 18 px side to side, 6 times | a bust | 0.28 s (/ pace) | same |
| Gain number fades in | a gain shows | 0.12 s after 0.25 s (/ pace) | `table_play.gd` `_draw` |
| Offer beat: the table holds before the offer screen | an offer | 1.2 s (MASTER_OFFER_BEAT); a tap skips | `ui/main.gd` |
| Call and final-round hold | his call; the final round | 1.6 s (MASTER_CALL_HOLD) | `ui/main.gd` |
| Idle line | no answer at my decision | after 9 s, once a turn (MASTER_IDLE) | `table_play.gd` `_process` |
| Pressed seal or button darkens | while held | instant | button pressed style |

Not animated: the candles' flames, the window light, the track tokens (they jump to their new place), the mark ring, the plates.
Screens off the table (offer card, overlays, banners) use main's beat phases: anticipation 0.3, action 0.4, impact 0.15, hold 0.4 (`ui/action_queue.gd`).

# What animates on the Sin selection screen today (REPLY 30 item 2; `ui/sin_carousel.gd`)
| What | When | How long |
|---|---|---|
| The Sin-coloured glow behind the window breathes down to 70% and back | always (off with Reduce Motion) | 4.0 s loop (SELECT_LIGHT_PERIOD) |
| The glow cross-fades to the next Sin's colour | the page turns | 0.35 s (SELECT_LIGHT_FADE) |
| A sheen sweeps across each window (menu_glass shader, plus backlight through the bright panes) | always, each window offset 3.1 s (Reduce Motion: steady light, no sweep) | every 9 s (MENU_SHEEN_PERIOD) |
| The page follows the finger; rubber-banded to 35% past the first and last | while dragging | live |
| The page springs into place | release (turns at 20% of the width or a flick over 900 px/s) | 0.45 s spring (Reduce Motion: 0.27 s, no spring) |
| Page dots: the current one larger with a gold ring | the page turns | instant |
| Sounds: "plaque" on each turn; the Sin's sting | the page turns | — |
| Keyboard left and right turn the page; a tap on the dot strip jumps there | input | as the spring |
Also on the page, not animated: the "Recommended" tag on Sloth, the name, epithet, play and abilities, the table-size control, the Choose seal.
