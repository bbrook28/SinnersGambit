# REPLY 38 item 3 (with REPLY 35 item 3): match length, decisions on rivals' turns, the Master's table (proposal; sim only)
Nothing in the game changed. Sims: `sim/match_sim.gd` (item 2's beat times, mixed bot profiles, seat 0 plays you and pays thinking time) and `sim/tables_sim.gd` (core V5 with the Master's call, the game's bot). Raw output: `sims.txt`.

**The measure.** The time from one of your decisions to the next, decision to decision (as in item 2: a prompt's 0.5 s rise and your 2 s answer count inside the gap). The pass mark is 10 s or under, at the median and in the worst case.

## Lever 1: decisions on a rival's turn (seat 0 only; the bots don't use them)
1. **Back the fall.** At a rival's turn start, the Master offers: 50 says it busts this turn.
   - If it busts, he pays you 40; if it banks, your 50 goes to the rival.
   - You judge by the busts you've watched this match. Today's table busts 57% of turns, so 40 is about break-even.
   - Visible result: your 50 flies to its token, or his 40 flies to yours.
2. **The long shot.** Before a rival's next throw, the Master prices the long shot by the dice: it busts this throw, or it survives a throw that will likely bust it.
   - Win: 50 × (1 − q) / q, at chance q (10% or better). Lose: your 50 goes to the rival.
   - Its value by the dice is always even, so the choice is about your standing. Behind, you take the swing; ahead, you refuse it.
3. **Hex** (a power spent out of turn). Once a round, when a rival's dice leave it on 2 Strikes, pay 60 to turn its best scorer into a Strike, so it busts.
   - Visible result: the die snuffs and its stake breaks.

**On the Master's credit.** A stake you don't hold comes off your next bank. Without this, 10-16% of rival turns show no prompt (you hold under 50); those turns play at their floor and give the worst gaps.

| Per rival turn, 4 seats | Shown | Taken | Close call (\|value\| small by your read) |
|---|---|---|---|
| Back the fall | 1.00 | 41-55% | 62-78% |
| Long shot | 0.47-0.50 | 51-57% | every one (an even swing) |
| Hex | 0.41-0.45 | 43-44% | 59-62% |
- With credit, no rival turn is left without a live prompt (0%).
- The worst gaps that remain all come from long turns that cannot bust in a throw, for example a rival dragged down to one die. Nothing is worth deciding there, and it plays at its floor.
- The rivals' beats keep their minimums. Prompts only add time: a rival's turn goes from a median of 8.2 s to 13.0 s.

## Lever 2: a table of 4 picked by the Master
- **How he picks:** the Sin that beat you last time; the Sin you have beaten least; and one you haven't faced in your last two tables. In the first game, the three are drawn at random.
- **On screen:** before the open, the windows light one at a time. Each lights with his line ("Wrath. It beat you last time."), and the empty windows stay dark.
- In the sim, this lever is 4 seats against a full table of 7. Today's default is already 4 seats, so here the lever's effect on time is the cut from 7 seats to 4. The picking itself is about story, not time.

## The gap (all decisions: median / p90 / worst; share over 10 s) and minutes (median)
| Structure | 7 seats, no levers | Lever 1 only (7 + decisions) | Lever 2 only (4) | Both (4 + decisions) |
|---|---|---|---|---|
| Today (call 550) | 3.6 / 57 / 88; 24%; 5.8 min | 6.0 / 10.4 / 52; 11%; 8.2 | 3.6 / 32 / 65; 25%; 3.9 | 5.5 / 9.6 / 35; 8%; 5.3 |
| A. Three dances, carry 1200/2400/3600 | 3.6 / 58 / 96; 28%; 20.6 | 6.0 / 10.0 / 46; 10%; 29.4 | 3.6 / 32 / 79; 28%; 14.8 | 5.5 / 9.6 / 44; 8%; 21.2 |
| B. Three dances, reset, call 750 | 3.6 / 61 / 114; 25%; 21.9 | 6.0 / 10.5 / 44; 12%; 30.4 | 3.6 / 34 / 77; 26%; 14.6 | 5.5 / 10.0 / 42; 10%; 19.8 |
- Without lever 1, every gap that spans the rivals is over 10 s: about 31 s at 4 seats and 56 s at 7.
- The prompts add about 35% to a match, so the targets are re-set for 15 minutes with both levers on (4 seats, the fall paying 40):

| With both levers | Minutes, median (p10-p90) | Gap median / p90 / worst; over 10 s | Lead changes | Leader entering the last stretch loses | You win |
|---|---|---|---|---|---|
| A. Three dances, carry 800/1600/2400 | 15.0 (12.6-18.1) | 5.5 / 9.6 / 42.5; 8% | 14.1 | 63% | 29% |
| B. Three dances, reset, call 400 | 15.5 (14.1-17.6) | 5.5 / 10.4 / 41.6; 11% | 6.7 | 38% | 29% |
| Short: three dances, carry 500/1000/1500 | 10.8 (9.3-12.8) | 5.5 / 9.6 / 42.8; 9% | 10.5 | 63% | 31% |
| Short: one race, the call at 1000 from round 4 | 7.6 (6.1-9.6) | 5.5 / 9.6 / 39.3; 8% | 8.0 | 49% (the leader at the call) | 31% |

**Verdict.** With both levers, the measure holds at the median (5.5 s) and nearly at p90 (9.6-10.4 s). It fails in the worst case (39-43 s) and on 8-11% of gaps. The cause is a long rival turn with nothing live in it, and that is the same at every match length. So a shorter match doesn't fix the measure; it only bounds what the gaps cost. Following item 3's rule, I propose the shorter match rather than a padded 15.
- **Edge:** you win 29-31% (the fair share is 25), against 16% for seat 0 without the decisions. A good reader of busts profits.
- **Lever 3 (compressed rival turns):** left out. No sheet proves that a short turn shows every fact.

## All 35 tables of four Sins (today's abilities, 2000 games each)
- No Sin is outside 15-35 at any table: 0 of 140 pairings.
- Nearest the edges:
  - High: Gluttony 33.9 (with Greed, Envy and Pride) and 33.8 (with Wrath, Greed and Pride); Sloth 33.0 (with Wrath, Greed and Envy).
  - Low: Pride 17.9 (with Envy, Gluttony and Sloth) and 18.4 (with Wrath, Gluttony and Sloth); Wrath 18.9 (with Greed, Lust and Sloth).
- Nothing rebalanced.

## Touches / Could break (if built)
- **Rules:** three new out-of-turn prompts and the Master's credit. New wording in `ui/rules_text.gd`. It needs Ben's OK for `core/`.
- **Bots:** they don't bet. If they did, your edge goes, and every Sin's numbers need a new sim.
- **Layout lock:** a prompt over the rival's turn needs a place in the locked frame. The proposal is the dice band, where your Throw/Bank sits on your own turn. Check this against `build/art27/win_lock.txt` before any build.
- **The Master's lines:** new events (offers the bet, pays, collects) and the pick lines, all needed in `ui/rules_text.gd`.
- **Pace:** a rival's turn goes to a median of 13 s. The pace-test floors (REPLY 38 item 1) must take the prompts into account.
