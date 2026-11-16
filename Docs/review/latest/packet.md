# Packet: REPLY 21 (reports 5-6, post, game end, buy row, docs; line-time and A proposals)
**Local only, not pushed.** Suite: all pass. Text audit: 33/33 clean at se and std.
**5. Your 725 lead.** In 118 your rivals were the normal table bots (`chooser(5)`: buy to 5 dice, bank at 300). First-game bots only play your very first game after install (`games_finished` 0). Sim (20000 mixed, built rules): after round 3 the leader is 300+ clear of second in 12.5% of games, 400+ in 5.2%, 500+ in 2.3%, 600+ in 0.9%. By the leader's profile: gamblers 15/8/4/2%, every other profile within 2 points of the mean. "Plain" tables match (12.5/5.3/2.2/1.0). So yours was about a 1-in-100 game.
**6. Greed's Cash Out.** The player reads "Bank half your stake at x1.25; keep throwing." What happens: half the stake (rounded down to 5) goes to your total as x1.25 (to 5). The other half stays as stake, and you must throw (there's no bank on that decision). On a later bust you lose the stake but keep half of the whole turn's face points, including the half you already cashed. That last part pays twice. Reported, not fixed.
**7. Post:** a dim grey-gold bar until he may call (after round 3), gold after. The number keeps its contrast (bone on an ink edge). New fixture `table_master_post_dim`.
**3. Game end:** its line and New game sit on their own plate on the page where the dice were. My window and every total stay clear.
**2. Buy:** one row, low to high: Buy none, then 1 up to what you can afford, at most 5. `Rules.MAX_BUY` 5 is in `max_buy` and the bots' clamp. Each button reads "Buy 3" over "300" (42 px, about 14.6 pt at SE: just under 15). Sim baseline with the cap: identical (20.4-27.8, 1.72 dice bought a seat). Bots never buy more than 5 at once; a cap of 1 shows the cap is wired (1.52). **Dead top row:** not found. Real clicks and touch taps work in a live game; my test of 118's two-row layout hung twice, so I dropped it. That layout is gone.
**1. Docs:** TableDesign §0 (the game as built: round, turn steps, buying, each power), and Handoff is up to date. Code and docs differ here (reported, not picked): (a) a Pride bust under Hubris still keeps half the face points; (b) the Greed double pay above; (c) TableDesign §5 says a table bot turn takes 2.5 s, tuning.gd and bot_pace say 4 s; (d) TableDesign's title still says V4.
**Sheets:** `sheet.png` / `sheet_se.png`: post lit, post dim, end before, end after, buy row (6 and 5 options). The buy row before (two rows, high to low): `Docs/review/archive/2026-11-16-reply20/now_*`.
**4. Line times (proposal; measured in a live game at 1x, 120 bot turns).** Today: 11-12 lines a minute (Master about half), so 49-60% are already replaced by the next one before 2.6 s. Bot turn avg 4.0 s at 4 seats, 4.1 s at 7 (the 4 s target already fails).
| option | bot turn | cut short by the next line | game time |
|---|---|---|---|
| A: 3.5 s, table doesn't wait | 4.0 s | 56-64% | +0% |
| B: 4.5 s, table doesn't wait | 4.0 s | 67-72% | +0% |
| C: 4.5 s, table waits for each line | about 5.8 s | 0% | +43-46% |
**REPLY 20, A (`mockA_std/se`).** Your lines, corrected: the gain does pop in the strip between the track and the dice, and A1 (the line in that strip) collides with it. A2 puts the line on the Master's plate spot in the robe, with the speaker's sigil, clear of the gain. The rival's seal in my seal's slot is a flat disc, with no bone ring and no press. My seal is hidden on their turn. At SE the rival's stake still touches the Bank button's top edge, and A2's plate meets the hood when window 1 is active.

**Questions**
1. Line time: A, B, or C? Rec: B plus fewer Master lines (at most one a round outside the call, the mark and the end), so fewer are cut.
2. A1 or A2 for the line under option A? Rec: A2. The gain owns the strip.
3. Greed: on a bust after Cash Out, keep half of only the face points still in the stake? Rec: yes. It's a rules change (core/game.gd) for your OK.
