# Audit: Sinners' Gambit, top down (2026-11-19)
Brief from Ben's interview: (1) pace: the wait through rivals' turns; bots should resolve in a beat or two, and Solo may become heads-up duels; (2) scope: cut the bets, the rest arrives too fast and explains itself badly; (3) look: cluttered, half finished, hard to read; keep only the stained-glass Sin art and the fonts; (4) every rule is negotiable; (5) presentation is a massive issue.
No code changed. Evidence: `sheet.png`, `clip.mp4`, `text_audit_se.txt`, `text_audit_max.txt`, `sim_check_v4.txt`, `sim_agency.txt`.

**Limits of this audit**
- No Godot MCP in this session (no `run_project`, `get_debug_output`), so the play audit uses fixtures, `tools/show.gd`, `tools/clip.gd` and the suite's pace tests.
- The Solo ladder and pass-and-play could not be played: neither is built (`Docs/UXPlan.md` 7b and 7c, "not started").
- `picks:grill-me` and `human-writing` are not installed. The interview used the grilling skill instead, and no player wording is proposed here.
- The sims measure `Rules.V4` (check_v3 and agency_sim both run on V4); the table plays V5.

## Critical
**C1. Most of a match is watching.**
- The rules make a short game: the sim estimates 5.5 rounds and 1.6 min with you and 3 bots (`sim_agency.txt`).
- The UI stretches it: a real match through the table takes 267 s, with a median bot turn of 6.5 s (`tests/table_pace_check.gd`), and the gap between two of your decisions measured 20.75 s (`tests/table_tap_check.gd`).
- So about 2.8 of the 4.5 minutes are presentation, mostly rivals' throws.
- The pace floors were then raised (3.0 s a bot turn, 180 s a match), and the bets (REPLY 36-43) were built to fill the wait rather than cut it. The clip shows one rival bank.

**C2. The game teaches nothing, and some of what it says is wrong.**
- Onboarding (`Docs/Onboarding.md`, Phase 11) was approved on 15 Nov and never built. The table build skips the tutorial (TableSpec, "No tutorial in the table build"), and hold-to-explain is not built on the table.
- The setup screen in the table build says "First to 1000" (sheet panel 1), and the track ends at 1000. V5 has no win score: the Master calls the end at 550, and totals run past it (panel 5: 1180 and 1725 bunched at the track's end, the 550 post inside it).
- The chain, the leader's mark, marks, claims and the call all reach a new player with no words on the table.

**C3. Decisions are thin and the result is mostly luck.**
- A turn averages 1.97 throws (`sim_agency.txt`), so roughly one push-or-bank choice a turn.
- Best-policy bot against plain bots: 30.1% against a fair 25% (target 35-45, missed). Against novice stand-ins: 37%.
- The powers carry no real choice except Greed's: pressing at the first chance is best for the rest (TableDesign §10).
- Temptations: 41% accepted, but claims come 0.14 a game, so the "claimed by a Sin" fantasy almost never happens (`sim_check_v4.txt`).

**C4. The table is half-built presentation over another game's scaffolding.**
- `ui/table_play.gd` is a layer over the old board: main builds the old board, the table redraws it from main's snapshots, and main's overlays (offer, game end, prompts) cover it (TableSpec, Code).
- Painted seals, candles, dice and the Master sit on a flat blockout page and track (panels 2-3).
- Text audit:
  - SE: 43 of 94 fixtures fail (878 contrast, 792 small text, 19 side margin).
  - Max: 35 of 96 fail.
  - Screens the table build uses: offer (Accept and Refuse at 13.5 pt), setup (10.4 pt ability text), rulebook (11.8 pt, contrast 3.4:1).
  - The rest are old-board fixtures that still ship in the binary.

**C5. The v1 promise is unbuilt while the table was polished.**
- v1 is Solo ladder plus pass-and-play (CLAUDE.md). Both are "not started", and so are Phase 10 (text and layout), 11 (onboarding) and 12 (motion).
- 158 commits since 15 Nov went to the table layout, its review packets and the bets.

## Should fix
**S1. Seven seats are broken and crowd the screen.**
- Fair share at 7 seats is 14.3%. Greed wins 30.6%, Sloth 7.0%, Lust 9.6% and Gluttony 9.7% (`sim_check_v4.txt`).
- At 7 the windows shrink to slivers, and tokens fan on leaning stems (panel 2).

**S2. One design doc holds three rulesets.** TableDesign §0 is V5 as built, §1 is the V4 base rules, and §5's ability table is V4 (Spark of Rage, Fury at 150+), which the table no longer plays. A reader can't tell which game is the game.

**S3. The UI learns what happened by regex over the rules' text log.** `ui/events.gd` matches lines like `" BUSTS( and goes to Purgatory)?\."`, so rewording a log line in `core/` silently drops a beat. Core should emit typed events.

**S4. `ui/main.gd` runs everything, in 3,825 lines and 144 functions.**
- It holds the menu, setup, settings, the old board, the table's host, offers, the game end, the tutorial and the parked run game.
- It branches on `table_view()` 8 times, carries static load flags, and references rules V2, V3, V4 and V5.
- `ui/table_blockout.gd` is 1,688 lines and `ui/director.gd` 1,191.

**S5. Core carries four rule versions.** `Rules.V2` to `V5` branch through `core/game.gd`, `turn_state.gd`, `player_state.gd`, `sins/` and `ai/`, with 26 option reads in `game.gd` alone, kept so old tests and saves replay.

**S6. The table layer makes no sound.**
- `ui/table_play.gd` and `ui/table_blockout.gd` contain no sound calls. Sound comes only from `ui/director.gd` (16 calls) and `ui/main.gd` (7).
- So the token pulse, the slide, the bets, the slip and the Master's pick are silent.
- The Master limiter (AudioStyle) is unbuilt.

**S7. The text audit crashes at SE.** `tools/ui_audit.gd` segfaults twice in a full SE pass inside `tools/fixture.gd:203` `_bank_beat`, my REPLY 43 clip animation: it awaits timers after the fixture is freed. SE was audited without the two `table_beat_bank_*` fixtures.

## Nice to have
- **N1.** The rival's turn dims Bank and Throw but keeps them on screen (panel 3), so the near edge shows controls you can't use for most of the match.
- **N2.** The stake numeral (230) has no label. Nothing on the decision screen says that throwing again risks it.
- **N3.** Old-board fixtures (decision_s*, bust_*, score_*, win_4, claim_4) fail the audit and still ship. They go with the old board.

## Design audit
**Red team, verdict: promising but fragile.** The dice core (push your luck, Strikes, bank) and the Sins' look are strong. The game around them fails as a phone game for mechanical reasons:
1. **Spectating** (C1): watching outweighs choosing about 3:1. Early warning: the floors went up and the bets were added to fill the gap.
2. **Low agency** (C3): about one choice a turn and a 5-point skill edge, so wins feel dealt. Fix the ratio of choices per minute, not the number of systems.
3. **Layers with no spine** (C2, C3): leader's mark, chain cap, powers, temptations, marks, claims, the call and bets. Each is a rule a new player meets unexplained, and the payoff rarely lands.
4. **Production drift** (C4, C5): the layout was locked (REPLY 24) before the rules, pacing or art settled, so each new system cost a layout round.

Weakest assumption: that a 4-7 seat tabletop table translates to a phone. At the table, the other turns are social time; on a phone they are dead time.

**One thing to remove: the multi-seat table in Solo.**
- Play Solo heads-up, you against one Sin a table.
- It cuts the watching by about two thirds before any other change.
- It removes most of the clutter: 7 windows, 7 tokens on fanned stems.
- It removes the 7-seat balance fault, the Master's table of 4 and the bets' reason to exist.
- It makes every temptation come from the Sin you're facing.
- What's lost: the crowd, and the comeback and lead-change drama of four seats (comebacks 7.0%, lead changes 4.18 a game).
- How to keep the good part: pass-and-play keeps 2-4 seats with the same one-beat rival turns.
- Verdict: prototype without it first.

**Unknowns, and the cheapest prototype for each:**
1. **Is a duel tense enough?** With one rival, does push-your-luck carry a 2-3 minute match? Prototype: a greybox duel on today's `core/` with 2 seats and a one-beat rival turn, played 10 times. Kill it if most matches are decided by round 3.
2. **Do one-beat rival turns lose the drama of a bust?** Prototype: the same greybox with two variants, the result only (score slides, "Busts") or three fast throws in 1.5 s. Compare which Ben wants to watch.
3. **Can the rules carry more choice per turn?** Today it is about 1 choice a turn. Prototype: a sim pass with a keep-some-dice option (set dice aside between throws), measuring the skill edge (target 35-45) and throws a turn. This touches `core/` behind an option, so it needs Ben's OK.
4. **Does a temptation feel like a choice?** With one rival tempting, raise the claim rate toward 0.5-1.5 a game in the sim, then play.
Stop when a 2-3 minute duel holds Ben's attention for 10 matches with a decision every 5 s or less.

## Play audit
**Feel:**
- The beat model (`ui/action_queue.gd`: anticipation, action, impact, hold) is sound, and its durations live in `ui/tuning.gd`.
- The problem is what gets beats: every rival throw gets the full set (start 0.6, throw 0.7, result 0.9, bank 0.9, line 2.5 s at 1x).
- There is no hit-stop or shake on your own bust beyond a page shake. The clip shows a rival's bank: pulse, flight, slide.

**UI/UX:**
- Text audit as in C4. Tap targets on the table pass (seals 86 pt; the audit reports none under 44 pt).
- The safe areas are respected in fixtures.
- Hierarchy: the eye goes to the lit window and the Master, not to the dice or the decision (panels 2-3).

**Audio:** see S6. Pillars and families are documented (AudioStyle); the new table beats are silent.

**First five minutes** (Onboarding.md against the build): none of the 7 captions exist. Game one is not rigged or simplified in the table build. The first screen a new player reads states a win rule the game doesn't use (C2).

## Code health
**Keep:**
- `core/` with no UI, plus `sins/` and `ai/`: the headless rules, bots and sims are the project's best asset. 4,000 games run headless in seconds.
- The sims: `check_v3`, `agency_sim`, `v5_sim`, `match_sim`, `seat_sim`, `tables_sim`.
- The beat queue, `ui/rules_text.gd` (all wording, `vals()`), `ui/tuning.gd`, the fixture, gallery and audit tools, the art and audio pipelines, and `ui/version.gd`.

**Replace:**
- `ui/main.gd`, `ui/table_play.gd` and the old board, with one screen per state and a small host.
- `ui/events.gd`'s regex, with typed events from core (S3; needs Ben's OK for `core/`).
- `ui/director.gd`, rebuilt on typed events.
- Prune core to one ruleset and drop V2 to V4 (S5).
- Retire the tutorial and the run game from the shipping binary.

**Tests:**
- 15 of 15 pass (REPLY 47).
- Strong: rules checks (`v5_check` 384, `table_check` 1211), real-UI integration (pace, taps, the guard, save, autoplay).
- Weak: the UI tests drive the old board's scaffolding, so they would be rewritten with it. No test asserts what the player is told against the rules: C2's "First to 1000" passes everything.
- Proposed: a check that every on-screen rule number comes from `vals()` and matches the active ruleset.

## Process
Yes, the way we've been working is part of the problem.
- **Where the time went:** in 5 days there were 39 review rounds and 158 commits, and 44 of the commits are packets or archive moves (28%).
- **What it optimises:** pixel placement and local correctness. REPLY 44-46 took three rounds for a version label.
- **What it doesn't optimise:** whether the game is fun. Ben's play is the only fun signal, and it happens rarely.
- **Locked too early:** the layout was locked before the rules, pacing and art, so every system added a layout round, and v1's ladder, pass-and-play and onboarding never started.
- **Indirect:** a reviewer relays Ben's word, which adds a round trip to every decision.

**What to change:**
1. Work in playable milestones of about a week. Each ends with Ben playing on a phone, and with a packet only at the milestone's end.
2. Greybox first. No paint and no packets on a prototype; layout locks only after the loop is fun.
3. Ask for decisions, not placement. Ben approves a direction and an acceptance test; Claude meets it without a round per pixel.
4. One fun metric each milestone: seconds between decisions, match length, and Ben's "again?" rate.

## Rework options (smallest to boldest)
| | A. Strip and finish | B. The duel ladder (recommended) | C. A new dice game |
|---|---|---|---|
| What changes | Cut the bets. A rival turn becomes one beat. Build onboarding. Fix the wrong text. Paint the table at today's layout. | Solo becomes 7 heads-up duels, one Sin a Circle (the ladder, finally). A new 2-seat screen: the big glass Sin, your dice, a two-token race, one decision at a time. The rival turn is one beat. Rules retuned for 2 seats; more choice a turn is tested (unknown 3). | New rules for a phone: simultaneous rounds, or you against a Sin's tableau. Push-your-luck kept as a flavour, not the spine. |
| Kept | All of V5, 2-7 seats, layout, Master | `core/` (2 seats already allowed), sins, bots, sims, beat queue, rules_text, glass art, fonts, temptations, marks, claims, the Master as narrator | Glass art, fonts, the Sins' voices, tools |
| Cut | Bets; old-board fixtures | Bets; the 4-7 seat Solo table; Master's table of 4; old board; the run game; regex events. Pass-and-play waits for v1.1 on the same screen. | Nearly all of `core/`, `sins/`, `ai/` and the sims |
| First playable test | Today's table with one-beat rivals: Ben plays 3 games; decision gap ≤ 6 s | A greybox duel on today's core (2 seats, one-beat rival), no art, 10 matches. Pass if a match runs 2-3 min, a decision comes every ≤ 5 s, and Ben wants another. | A paper or greybox prototype of the new rules, 10 games |
| Rough size | 2-3 weeks | Greybox 1-2 days; full v1 about 4-6 weeks | 2-3 months, with a high risk of losing the game you designed |
| Risk | Keeps C3's low agency and the clutter's cause | The duel may lack tension (unknown 1); needs a `core/` OK for typed events and the 2-seat retune | Throws away the proven rules and the sims |

**Recommendation: B.** It answers all three things you named:
- **Pace:** one rival, resolved in one beat.
- **Scope:** fewer seats, no bets.
- **Look:** a new screen built for 2 seats around the glass art and fonts, rather than repainting a 7-seat blockout.

It also finally builds v1's ladder. The greybox duel costs 1-2 days and answers the biggest unknown before any art.
