# REPLY 39 item 2: the fall and the hex, proven at today's structure (proposal; sim and sheet only)
Today's structure throughout: the call at 550, 4 seats. Sims: `sim/match_sim.gd` (mixed bot profiles, item 2's beats, seat 0 plays you) and `sim/tables_sim.gd`, 1500 matches a row. No game code changed. The new fixtures are for the sheet only. Raw output: `sims.txt`.

**Rules as simmed.**
- **Fall:** at a rival's turn start, stake 50 that it busts this turn, at even money (it busts: you take 50). On the sheet, Gluttony leads, so it shows the standings price (65; item e).
- **Hex:** once a round, at 2 Strikes, pay 60 and its best scorer turns to a Strike.
- **Master's credit:** capped at 150 (item c).
- **No hex on a rival you backed** (item b explains why).

## a. Prompt sheet (`prompts_se.png` at 0.48 of SE device px; `prompts_std.png` at 0.31 of std)
- **Placement:** the offer takes the seals row. On a rival's turn Bank and Throw are idle, so Pass sits where Bank is, Take or Hex where Throw is, and the offer goes between them.
- **The lock:** `build/art27/win_lock.txt` locks the windows only. Nothing locked moves: the windows, track, dice and candles stay where they are.
- **Frames:** (0) REPLY 39 item 4: before the open, his table lights window by window with his line (Greed and Wrath lit, Gluttony still dark); (1) the fall offer at turn start; (2a) it busts and the Master's 50 flies to your token; (2b) it banks and your 50 flies to its token; (3) the hex offer at 2 Strikes, the target die ringed; (4) the die snuffs, the third candle goes, and its stake breaks.
- **What I see:**
  - the slip covers the lower half of the candles (frames 1 and 3), but each candle's flame or smoke stays visible;
  - in (2a) the flight crosses "Gluttony's turn" and ends just under your 340 label;
  - in (2b) the "50" sits on Gluttony's stem;
  - in (4) the flight crosses your 280 label.
- **Sizes:** Pass, Take and Hex are 224 layout px across (about 80 pt). The slip text is 42-50 layout px.

## b. Win rate by decision (seat 0, today's structure)
| Seat 0 has | none | fall only | hex only | both | both, hex allowed on a rival you backed |
|---|---|---|---|---|---|
| You win | 16.8% | 19.7% | 19.5% | 21.3% | 26.6% |
- **Why seat 0 sits at 16.8:** the seat order. Wins by seat, first to last, are 16.8 / 22.7 / 28.7 / 31.8. The core game with its own bot shows the same pattern (14.7 / 20.5 / 28.8 / 35.7 over all 35 tables). The last seat throws last in the final round, with every score known. You are always seat 0. This is a rules finding, outside this item.
- **The 29-31% last packet came from the long shot** (a swing taken whenever you're behind), now dropped.
- **Hex does not carry most of the edge:** fall and hex each add about 3 points, and together 4.5.
- **What reaches 25-28:** allowing the hex on a rival whose fall you backed. You win 26.6%, because you can make your own bet come true for 60. Proposed as the limit: allowed, still once a round.

## c. The Master's credit
- **The cap:** 150 at most, counting the bets still open, so the worst score is −150.
- **At the cap:** a prompt that could take you past it is not shown, so a prompt you cannot take never appears. This happens 0.15-0.9 times a match. A stake you don't hold comes off your next bank.

## d. The dead turns
- **Fix simmed:** compression. Within a run of throws that cannot bust the rival, every throw after the first plays as one 0.4 s beat.
- **Alternative:** the raise, a second fall offer before a later throw (item e), which stays live while the turn can still bust.
- **No sheet made yet** that shows a compressed stretch loses no fact, so the fix is not proposed until there is one.

| Gap (median / p90 / worst; share over 10 s) | fall + hex | + compression | + raise | + both |
|---|---|---|---|---|
| | 6.0 / 11.5 / 50.9; 21% | 6.0 / 11.2 / 36.0; 21% | 6.0 / 10.7 / 50.5; 14% | 6.0 / 10.7 / 34.2; 14% |
- With the hex allowed on a rival you backed: 6.0 / 11.1 / 42.8; 18%.
- Without the long shot, neither fix holds 10 s: compression cuts the worst case, and the raise cuts the share. The long shot (6.0 / 9.6 / 35; 8%) was what filled the middle of a rival's turn.

## e. Sameness
- **The fall:** your read calls it close (|value| under 15) on 79-81% of rival turns and obvious on 19-21%. You take it on 38-39%, and win 55% of those.
- **Variation 1, the price follows the standings:** the Master pays 65 on the leader's fall, 35 on the last seat's, and 50 otherwise. Close 80%, taken 39%, you win 19.6%.
- **Variation 2, the raise follows the Strikes:** before a 3rd+ throw, the Master re-offers the fall at fair odds for its Strikes now (turns bust 44% from 0 Strikes, 64% from 1, 88% from 2). Shown 0.27 a rival turn, close 81%, taken 35%, won 48%.
- **Both variations together:** gap 6.0 / 10.7 / 50.5; 14%; you win 21.3%.

## f. 35 tables with the fall and hex on, seat 0 betting
- **Same engine for both runs.** The game's bot sits in every seat, 2000 games a table, seat order shuffled. Seat 0 bets with the standings price and the hex not allowed on a rival you backed.
- **Why not core:** the bets live in the sim game, which models V5 with the profile sim's rule keys. Core can't run them. So the comparison is that engine without bets against the same engine with bets. Core without bets, last packet: 0 of 140 pairings outside.
- **Without bets** (this engine): 2 of 140 outside, Gluttony 36.4 (with Greed, Envy and Pride) and Sloth 35.5 (with Wrath, Greed and Envy).
- **With bets:** 6 of 140 outside, all of them Gluttony high: 38.6 (with Greed, Envy and Pride), 38.3 (with Wrath, Greed and Pride), 36.6 (with Wrath, Envy and Pride), 35.6 (with Wrath, Greed and Envy), 35.5 (with Wrath, Pride and Sloth), 35.1 (with Greed, Lust and Envy).
  - Lowest: Pride 15.4 (with Wrath, Gluttony and Sloth).
  - The average Sin moves 2.2 points. The biggest moves are Pride −6.2 (with Greed, Lust and Gluttony) and Greed +6.1 (with Wrath, Envy and Pride).
- **Seat 0 with the game's bot:** 17.3% without bets, 19.1% with them.
- Nothing rebalanced.

## The decisions, side by side (today's structure, 4 seats)
| | Minutes | Gap | You win |
|---|---|---|---|
| No decisions | 3.9 | 3.6 / 31.9 / 74.5; 25% | 16.8% |
| Fall + hex (hex not on a rival you backed) | 5.0 | 6.0 / 11.5 / 50.9; 21% | 21.3% |
| Fall + hex, the hex allowed on a backed rival | 5.2 | 6.0 / 11.1 / 42.8; 18% | 26.6% |
| Fall + hex + raise + compression, standings price | 5.1 | 6.0 / 10.7 / 34.2; 14% | 21.3% |

## Touches / Could break (if built after Ben plays)
- **Rules:** the fall, the hex and the Master's credit capped at 150. Needs Ben's OK for `core/`. Wording goes in `ui/rules_text.gd`.
- **Bots:** they don't bet (REPLY 39 item 3). The Sins' numbers above assume only you bet.
- **The lock:** the windows don't move. The seals row changes on a rival's turn only.
- **The Master's lines:** offer, pay, collect, the hex, and the pick lines.
- **The pace-test floors:** a rival's turn grows to about 11 s at the median.
- **New fixtures, for the sheet only:** `table_oot_fall`, `table_oot_fall_bust`, `table_oot_hex`, `table_oot_hex_bust`, `table_oot_pick`.
