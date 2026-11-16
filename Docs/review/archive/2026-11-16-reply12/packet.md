# Packet: REPLY 12 (totals, old board, roll and bust audit, bank caps; local, not pushed)
**Built:** a6c35bf every total at its track marker (bone on ink; above a rival's head with its crown above, under mine; heads on a level spread to fit) · 79fdfa9 old board out of the build · 3d006db the Master's win line reads the winner's score · 39500f4 sim audit, roll audit, turn_cap and first_ones. Suite: all 10 pass. Text audit: all 28 table fixtures clean at se and std (new: table_end).
**How a player reached the old board in 116:** (1) the game end. With a winner the table hid itself, and main's old board showed (banner, final scores, chain "x3.5", "New game"). That matches your 1725. (2) The table also hides under an offer, a page, settings or the log, with the old board drawn beneath. (3) Settings > Tutorial ran the V3 tutorial on the old board. **Now:** the game ends on the table ("New game" in the choice row). A dark cover hides the old board's scores and dice whenever the table steps aside (the thumb row stays, since offers use it), and the tutorial row is gone from the table build.
**Sheet:** before and after: table_master_call, table_buy; then after only: table_close_7 (7 seats), table_end. Seen: with totals the band grows, so 7-seat windows shrink. The totals of the two head levels sit close. On table_end, my 640 sits over the post's 600.
**Roll audit (1M dice each, raw throws before any power):** Rules.roll 33.35% Strikes, chi 8.4 · player seat 33.35%, chi 1.9 · bots 33.34%, chi 7.3 (fair is below 11.07). The dice are fair and the same for everyone.
**Why it busts:** the chance that one throw from scratch reaches 3 Strikes, exactly: 3 dice 4%, 4 dice 11%, 5 dice 21%, 6 dice 32%, 7 dice 43%, 8 dice 53%. Per throw in play (Novice / Gambler): 3 dice 12/16%, 5 dice 33/27%, 6 dice 31/36%, 8 dice 55/41%. Per turn: Novice 28-44%, Gambler 50-56%. Turns banking 0: 42% overall, Gambler 53%.
**Banks (call at 600):** median / p90 / max: round 1 110/315/1390, round 2 130/405/2205, round 4 45/435/2185. Points come 46% from faces, **44% from the chain multiplier**, and 10% from everything else.
**Tests** (20000 mixed games, call at 600; Sin range · lead after round 2 over 2nd / last · last seat wins · zero-bank turns):
- base: 19.3-33.1 · 202 / 445 · 3.9% · 42.3%
- (a) cap 300 before the call: 17.1-34.9 · 165 / 378 · 4.9% · 40.8% (Greed 34.9: Cash Out multiplies the capped bank)
- (a) cap 400: 18.4-33.3 · 177 / 409 · 4.4% · 41.6%
- (b) only 1s strike on the first throw: 14.0-38.6 · 222 / 498 · 3.7% · 38.6% (Envy 38.6, Greed 37.0)
- Greed Cash Out x1.25: 20.3-34.8; Greed drops 32.1 → 24.5, and Envy (34.8) is now on top.

**Questions**
1. The chain multiplier makes up 44% of all points and causes the spikes. Should I sim chain 0.25 (from 0.5) under the call? Rec: yes, before any cap.
2. Cap 300 narrows the lead after round 2 by about 40 but widens the Sin range. Should I test it with the cap applied after Cash Out? Rec: hold it until question 1 is answered.
3. Only-1s on the first throw cuts zero-bank turns by 4 points but feeds Envy and Greed. Drop it? Rec: drop it.
4. Greed x1.25 brings Greed back to fair. Make it the next sim baseline (still sim only)? Rec: yes.
