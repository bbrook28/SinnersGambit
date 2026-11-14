# Audio style: "in the nave"

Sinners' Gambit sounds like a dice game played on a desk inside a dark cathedral at night. The sounds are stylized, not realistic foley: every sound is the sound of the illuminated page, not of a casino table.

## Pillars
1. **Stone room.** Everything that matters rings out into a big, dark stone space: a short pre-delay, a long, soft, dark reverb tail. Small UI touches stay dry and close, so the important sounds stand out against them.
2. **Bells, wax, parchment, bone.** These are the four materials. Bells mean outcomes (bank, bust, win, an ability). Wax means your commitments (seals, stamps). Parchment means movement (banners, lifts, flights). Bone means the dice. No casino chips, no electronic UI blips, no realistic coins.
3. **Low and dark.** Base pitch sits below "as recorded". Little top end: a gentle high-frequency roll-off on the nave. Brightness is earned: only a good result gets the high shimmer.
4. **Tension rises in pitch.** Counts climb in pitch as the number grows. Bigger results ring louder and longer (the `k` argument), never just more often.
5. **One voice at a time for outcomes.** A bank, bust or win is a single clear bell gesture, not a pile of layered hits.

## Sound families (ui/sfx.gd `SETS`)
| Family | Meaning | Material | Bus |
|---|---|---|---|
| Outcome bells | bank, bust toll, win, ability chime, count ping | synthesized bells (`tools/bake_audio.gd`) | Nave |
| Commitment | seal press, stamp, nails (Strikes) | wax and iron, pitched down | Nave |
| Movement | lift, fly, banner in/out, bot card | parchment, pitched down | Nave |
| Dice | shake, throw, landing | bone on wood | Nave |
| Touch | plaques, buttons, ticker | soft click (and the count pings) | dry (Master) |

## Mapping
- **Bank:** two bell strikes a fifth apart, bright, about 2 s ring.
- **Bust:** one low toll, long tail (about 4 s), under the glass crack.
- **Win:** a minor organ chord swelling under a bell, about 3.5 s.
- **Ability / freed from Purgatory:** a small high bell cluster (shimmer).
- **Count-up ticks:** tiny bell pings, rising in pitch across the count.
- **Third Strike:** the iron nail plus a small toll.
- **Buy dice:** bone dropped on wood, pitched down (no chips).

## Limits
- Every synthesized sound is mono, 44.1 kHz, peak at -1 dBFS, a 5 ms attack (no clicks) and a faded tail.
- Outcome bells never exceed 4.5 s; touch sounds stay under 0.3 s.
- Music stays dry on Master; only effects go through the nave.
- The limiter on Master comes in Phase 9.
- Phase 4's per-Sin stings follow this sheet: one bell or organ gesture in the Sin's own key, sent to the nave.

## Where things live
- `ui/sfx.gd`: sound sets, the per-sound pitch (`T.SFX_PITCH`) and the dry list (`T.SFX_DRY`); it builds the `Nave` bus (reverb plus low-pass) at start.
- `ui/tuning.gd` § Sound: volumes, pitches, nave reverb settings.
- `tools/bake_audio.gd`: synthesizes the bells into `assets/audio/synth_*.wav` (headless, deterministic).
