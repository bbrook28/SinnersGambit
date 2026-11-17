# Player-facing strings (REPLY 26 item 5)

Copied as written; nothing changed. `{x}` is filled at play (a name, a number from the rules). Source: `ui/rules_text.gd` unless a file:line is given. The parked run game (`RUN`) is left out.

## 1. The Master

Shows: on the table, his plate in his robe over the windows (one line a round at most; call, final round, mark and end always). A line with a condition plays only when it is true.

**start**
- Take your seats. The dance begins.
- Dice ready. Souls ready. Shall we?
- Seven Sins, one table. Delightful.
- Mind your candles. Let us begin.
- You throw first. Do begin.  _(only if: first)_

**my_bust**
- Ah. The dice have spoken.
- {strikes} candles out. Do sit.
- A misstep. Everyone stumbles.
- Gone. Shall we try again?
- Pity. It was going beautifully.  _(only if: stake)_

**my_bank**
- Splendid. Do bank like that again.
- Well kept. The Sins noticed.
- A fine harvest, if I may.
- Bravo. My compliments to your nerve.
- Into your keeping. Nicely done.

**rival_bust**
- Oh dear. Not you this time.
- {name} trips. How very human.
- Snuffed. Do take note.
- The dance claims {name}. Briefly.
- Careful steps win. Usually.

**offer**
- {name} has a little proposal.
- A word from {name}, please.
- Ah, {name} wishes to bargain.
- Listen closely. {name} is generous.
- {name} approaches. Mind your purse.

**mark**
- Marked. {name} will remember.
- A small price. For now.
- Signed in ink. How brave.
- {name} smiles. That's rarely good.
- One mark. {claim_marks} and it claims.  _(only if: first_mark)_

**claim**
- {claim_marks} marks. {name} owns you now.
- Claimed. I did mention it.
- {name} will keep you close.
- Bound. The dance goes on.
- Well. A lasting arrangement, then.

**my_win**
- The dance is yours. Well played.
- {win}. I'm genuinely impressed.
- Victory. The Sins will sulk.
- Bow, please. You've earned it.
- Splendid. Do come again.

**my_loss**
- Not tonight. There's always another.
- The dice were unkind. Again?
- A good dance, all the same.
- Rest. The table will wait.
- Close. Closer than they'd admit.  _(only if: close)_

**call**
- {call} reached. Two rounds left.
- Two rounds left. Then I judge.
- The music slows. Two rounds.
- Nearly done. Two rounds remain.
- Savour it. Two rounds to go.

**final**
- Last round. Highest score wins.
- Final round. Make it count.
- Last dance. No second chances.
- One last throw each. Choose well.
- The end. Dance it well.

**marked_me**
- You lead. No chain this round.
- Ahead? Then no chain this round.
- First place. No chain this round.
- Marked. No chain this round.
- Leader's toll: no chain this round.

**marked_rival**
- {name} leads. No chain this round.
- {name} leads. Chain off this round.
- I mark {name}. No chain.
- Marked: {name}. No chain this round.
- {name} pays: no chain this round.

**idle**
- Throw, or keep? Your call.
- Candles are patient. I am less.
- Courage or caution, dear guest?
- Another throw? Purely a suggestion.
- Take your time. Eternity's long.

Offer screen, his line before a Sin's offer: the `offer` event above (`ui/main.gd` master_offer_line).

## 2. The Sins

Lines show on the table, on the Master's plate spot in the Sin's colour with its sigil (`Tuning.LINE_CHANCE` of events). Offer lines show on the offer screen under the Sin's portrait. Claims show on the offer screen and in the log when a Sin claims you. Name, epithet, play and abilities show in Sin select, the rulebook and the pause menu's Sin abilities; the power is the line beside my seal.

### Wrath
- **Epithet:** the Avenger. **Play:** Profit when others fall.
- **power:** Rethrow: Rethrow up to {wrath_rethrow} of this throw's Strikes.
- **basic:** Spark of Rage: +{rage} whenever a rival busts.
- **greater:** Fury: The first rival throw worth {fury_trigger}+ rerolls its {fury_dice} best dice.
- **Claim:** Each bust costs you {claim_bust}.
- **Offer lines:** Wipe it clean. (w1) · Tear it from them. (w2) · Burn it all. (w3) · Hit harder. (w4)
- **own_bust:** Rrraagh! Again! · Which of you cursed these? · I'll burn this table. · Someone pays for this. · That one stays with me.
- **rival_bust:** Burn, {name}. · Ha! Into the fire. · Your loss feeds my rage. · Kneel in the ashes. · Scream louder, {name}.
- **big_bank:** Feel that? Fury. · I break. I take. · Ashes for the rest. · Next, I hit you. · Count it, cowards.
- **lead:** Top of the pyre. · Catch me, if you dare. · Who's angry now? · The crown smoulders. Mine. · Step up and bleed.
- **attacked:** You'll pay for that. · Your last mistake, {name}. · I remember faces. · Oh, now it's war. · Run, {name}. Run now.
- **aim:** You, {name}. Now. · Payback, {name}. Brace yourself. · The leader burns first. · I never forget, {name}. · Your turn to bleed.
- **win:** Everything burns. I win. · Bow to the fire. · On your knees, worms. · Told you. Ashes. · Crawl home, all of you.
- **lose:** This isn't over. · I'll be back. Angrier. · Next table, you burn. · I'll find you, {name}. · Sleep lightly, {name}.
- **recall:** {host} went easy. I won't. · Still sore from Circle {n}. · You burned past {host}. Not me. · Circle {n} left you scarred. · Cheat {host}? Try cheating me.

### Greed
- **Epithet:** the Hoarder. **Play:** Grow rich on everyone's spending.
- **power:** Cash Out: Bank half your stake at {greed_mult}; keep throwing.
- **basic:** The Vig: When a rival buys a die, you get {vig} of its price.
- **greater:** Interest: Bank and buy no dice: +{interest}.
- **Claim:** Every Bank pays Greed {claim_greed}.
- **Offer lines:** On credit, naturally. (g1) · A small fee. (g2) · Interest applies, of course. (g3) · Cash now. Collateral later. (g4)
- **own_bust:** A poor investment. · Write it off. Quietly. · A rounding error. Ignore it. · Losses. Temporary losses. · I'll bill someone for that.
- **rival_bust:** Your loss, my margin. · Bankrupt. I'll take the furniture. · I'll buy your remains. · Should've cashed out, {name}. · Every bust pays someone.
- **big_bank:** Interest compounds. Beautifully. · Into the vault. Forever. · Profit. The only true love. · Count it twice. · Now that's a return.
- **lead:** Top earner. Naturally. · The market favours me. · I hold your debts now. · Buy low, lead high. · I own this table. And you.
- **attacked:** That will cost you. · I'm adding interest, {name}. · Theft. Noted. Collected later. · You'll repay that. Tenfold. · Everything you own is collateral.
- **aim:** Your account's overdue, {name}. · Collecting from the leader. · Pay, {name}, or forfeit everything. · {name}, settle your debt. · Your fortune looks underpriced, leader.
- **win:** Paid in full. · The house always wins. · All of it. Mine. · Every soul here, signed over. · Closing the books. Goodbye.
- **lose:** Bad quarter. Nothing more. · I want an audit. · Keep it. I'll repossess later. · I'll buy this table later. · Debts get collected, {name}.
- **recall:** You still owe me, Circle {n}. · {host} paid. Now you pay. · Your Circle {n} winnings? Mine now. · {host}'s losses raised my rates. · Welcome back, valued customer.

### Lust
- **Epithet:** the Temptress. **Play:** Take the best of what others throw.
- **power:** Desire: Turn a Strike into the last player's best die.
- **basic:** Whisper of Desire: Once a turn, your 3 or 2 becomes the last player's best die.
- **greater:** Binding Pact: Pick a rival; take {pact} of the next turn they Bank.
- **Claim:** You can't Bank before your second throw.
- **Offer lines:** Twice the pleasure, darling. (l1) · Take it, darling. (l2) · More for you, sweetheart. (l3) · I'll kiss it away. (l4)
- **own_bust:** Mm. Too much, too fast. · Worth it, almost. · You caught me wanting. · Again? I can't resist. · Pleasure has a price.
- **rival_bust:** Couldn't stop, could you? · Poor thing. Let me comfort you. · I know that hunger. · You wanted more. Me too. · Such sweet ruin, {name}.
- **big_bank:** Doesn't that feel good? · Mm, I'm only warming up. · You can't look away. · Don't stop now, darling. · Ooh, give me more.
- **lead:** All eyes on me. Good. · Follow me, darlings. · Out in front. Lovely. · Want this? Come closer. · Mine to lose, sweetly.
- **attacked:** Rough. I like it. · Oh, {name}, you're bold. · You'll want me back. · Careful what you touch. · That stung. How thrilling.
- **aim:** Come closer, {name}. Closer. · I want what's yours. · The leader looks tempting. · Your turn, sweetheart. · {name}, I'm coming for you.
- **win:** You all wanted me. · Utterly irresistible. Me. · Satisfied, finally. · Kiss the dice goodbye. · Never enough. Except now.
- **lose:** Leaving me wanting? Cruel. · Next time, I take everything. · Leaving so soon, {name}? · I'll remember your touch. · Unfinished business, {name}.
- **recall:** Missed me since Circle {n}? · {host} bored you. I won't. · {host} told me about you. · Still warm from Circle {n}? · Come closer. Forget {host}.

### Envy
- **Epithet:** the Mirror. **Play:** Copy the previous player's best die.
- **power:** Copy: Copy your best die: it scores its face again.
- **basic:** Green-Eyed Glance: While behind, your first scoring throw each turn copies the last player's best die.
- **greater:** Mimicry: That throw gains two copies instead.
- **greater_v5:** Mimicry: Once a round, a scoring throw gains {mimic} copies of the last best die.
- **Claim:** While you lead, each Bank pays Envy {claim_envy}.
- **Offer lines:** You deserve their dice. (e1) · Double, like the leader. (e2) · Their luck, for you. (e3) · They always get this. (e4)
- **own_bust:** Of course. Only me. · Everyone else gets lucky. · Why is it always me? · Their dice. Their luck. Theirs. · I hope you're all happy.
- **rival_bust:** Not so perfect now. · Finally, someone else suffers. · Good. Now you're me. · How does that feel, {name}? · I prayed for that, {name}.
- **big_bank:** See? I can too. · Look at me. LOOK at me. · Now you know how it feels. · Take that, all of you. · Copied that from {name}.
- **lead:** Hate me now? Good. · Now you envy me. · How's the view from behind? · Finally. It's mine. · Don't you dare catch up.
- **attacked:** Always me. Always. · Why not pick {name}? · You think you're better? · I'll take everything you love. · Everyone hates me. Fine.
- **aim:** You have too much, {name}. · Whoever leads, I hate. · Why do you deserve it? · {name}, I want your life. · Your crown should be mine.
- **win:** Now you all want this. · Envy me. I insist. · Who's jealous now? · Mine, and never yours. · Finally, I'm the one.
- **lose:** Of course {name} won. · It should've been me. · Enjoy it. I won't. · Lucky. Just lucky. · I'll wear your smile someday.
- **recall:** You beat {host}? Lucky. · Everyone adores you. I don't. · Why did {host} get you first? · Circle {n} was luck. Admit it. · Everyone beat {host}. Even you.

### Pride
- **Epithet:** the Untouchable. **Play:** Bet on yourself and win big.
- **power:** Hubris: Name your Bank: reach it for {hubris_mult}, else nothing.
- **basic:** Hubris: Before throwing, bet {hubris_targets}: Bank that much for {hubris_mult}, else 0.
- **greater:** Untouchable: The first ability aimed at you bounces back.
- **Claim:** A Bank under {claim_pride_min} scores nothing.
- **Offer lines:** Score like royalty. (p1) · As you deserve. (p2) · A mere trifle. (p3) · My gift to you. (p4)
- **own_bust:** A test of my patience. · The dice erred, not I. · Beneath my notice. · I allowed that. · Even gods stumble. Briefly.
- **rival_bust:** Know your place. · Predictable, {name}. · Crawl back to the gutter. · Pitiful. Truly pitiful. · Mortals. Always overreaching.
- **big_bank:** As expected. · Witness true greatness. · Applause is customary. · Effortless, naturally. · Weep, lesser souls. Weep.
- **lead:** Where I belong. · The throne returns to me. · Bow. Lower. Lower still. · Order is restored. · Look up, all of you.
- **attacked:** How dare you, {name}. · You touched the crown? · Insolence. You'll beg for mercy. · I am Untouchable. · You'll kneel for that.
- **aim:** Remember your place, {name}. · The pretender must fall. · No one outshines me. · {name} forgets who rules. · Off my throne, you peasant.
- **win:** Was there any doubt? · Kneel before your better. · Perfection, as always. · History will forget you all. · Of course I won.
- **lose:** I let you win. · A hollow victory, {name}. · This changes nothing. · Savour it. It won't happen again. · The crown is merely lent.
- **recall:** {host} fell. I won't. · I watched Circle {n}. Unimpressive. · {host} was a warm-up act. · You survived Circle {n}? Adorable. · Beating {host} means nothing here.

### Gluttony
- **Epithet:** the Devourer. **Play:** Trade dice for points.
- **power:** Devour: Eat a Strike die: +{eat} to your stake.
- **basic:** Feast: Once a turn, feed a thrown die for +{feast}; a fed Strike doesn't count.
- **greater:** Gorge: Your first die each turn costs {gorge}.
- **Claim:** Each bust eats one of your dice (never below {min_dice}).
- **Offer lines:** Delicious, isn't it? (u1) · Feed me a die. (u2) · Twice the feast. (u3) · Fresh and juicy. (u4)
- **own_bust:** Bit off too much. · Urp. It's coming back up. · My eyes, too big. · Spit it out. Again. · Still hungry. Always hungry.
- **rival_bust:** More for me. · Ooh, warm leftovers. · I'll lick up your crumbs, {name}. · You choked. I won't. · Pass the plate.
- **big_bank:** Delicious! · Second helping, please. · Mmmf. Gristle and all. · Loosen the belt. Wider. · Feast, feast, feast!
- **lead:** Biggest plate at the table. · I'm getting fat on this. · Top of the menu. · Who's hungry? Just me. · My belly leads the way.
- **attacked:** Hands off my plate! · You ate my dice! · I'll swallow you whole, {name}. · Now I'm angry hungry. · Rude. I was eating.
- **aim:** You look juicy, {name}. · I'll eat the leader. · Open wide, {name}. · Biggest plate gets bitten. · I'll pick my teeth with {name}.
- **win:** Every last crumb. Mine. · BURRRP. Thank you all. · The whole table, eaten. · Dessert is victory. · Stuffed. And champion.
- **lose:** Still starving. · Leave me the scraps. · I'll eat you next time. · I'll gnaw on this loss. · Save me a plate, {name}.
- **recall:** Hungry since {host}'s table. · You smell delicious. Like Circle {n}. · {host} was only the starter. · Circle {n} whetted my appetite. · Saved room for you.

### Sloth
- **Epithet:** the Delayer. **Play:** Shrug off a Strike every turn.
- **power:** Idle: Ignore this throw's Strikes; the first becomes a 4.
- **basic:** Lazy Bones: Your first Strike each turn doesn't count.
- **greater:** Drag: Pick a rival; they throw {drag} fewer dice next turn (never below 1).
- **Claim:** You throw {claim_sloth_fewer} fewer dice (never below 1).
- **Offer lines:** Take it and rest. (s1) · Rest that Strike. (s2) · Why bother? (s3) · Lie back. Take it. (s4)
- **own_bust:** Eh. Too much effort. · Should've stayed in bed. · Wake me next turn. · Worth it for the nap. · That's what trying gets.
- **rival_bust:** All that effort. For nothing. · See? Trying hurts. · Pathetic. And so loud. · Mm. Called it. Yawn. · Lie down. Stay down.
- **big_bank:** Hm. That was easy. · No sweat. Literally. · Done. Nap time. · Barely lifted a finger. · You sweat. I win.
- **lead:** Ahead? Didn't notice. · Wake me at the end. · Look at you all. Panting. · Huh. Look at that. · Nobody rush. Please.
- **attacked:** Rude. I was napping. · Must you, {name}? · Ugh. Fine. Noted. · So much effort. So little point. · I'll get you. Later.
- **aim:** Slow down, {name}. · Sit down, leader. · Sleep, {name}. Forever, perhaps. · Rest your dice, {name}. · Such frantic little creatures.
- **win:** Wake me for the trophy. · Didn't even try. You did. · Rest wins. Again. · Can I sleep now? · Told you. Patience.
- **lose:** Eh. Tomorrow. · Too tired to care. · Good game. Nap time. · Sweating for a win? Vulgar. · I'll rest on it.
- **recall:** Back again? Already? Ugh. · Didn't {host} tire you out? · Circle {n} again? So tiring. · Five more minutes. Then you. · You woke me for this?

## 3. Questions

Shows: the prompt over the choice row (table: the plate under the windows; the board: the prompt line). Typed in code, so listed with file:line.

- `ui/human.gd:8` You
- `ui/human.gd:52` Throw again, or bank?
- `ui/human.gd:54` Throw how many dice?
- `ui/human.gd:56`  (Dragged: max %d)
- `ui/human.gd:58` \nHubris: bank at least %d, or score 0.
- `ui/human.gd:63` Bank %d
- `ui/human.gd:75` Throw your dice. · Throw again, or bank?
- `ui/human.gd:77`  (Dragged: %d dice)
- `ui/human.gd:79` \nHubris: bank at least %d, or score 0.
- `ui/human.gd:82` Bank %d
- `ui/human.gd:95` %d Strike%s
- `ui/human.gd:110` Buy none
- `ui/human.gd:112` Buy %d (%d)
- `ui/human.gd:113` Buy dice? You have %d dice and %d points.
- `ui/human.gd:123` Yes · No
- `ui/human.gd:131` %s (%d)
- `ui/human.gd:132` Skip
- `ui/human.gd:133` %s: pick a target.
- `ui/human.gd:149` @seal %d
- `ui/human.gd:157` Bank %d

- `sins/envy.gd:66` Green-Eyed Glance? Add a %d to this throw (once a turn).
- `sins/envy.gd:83` Mimicry? Add two %ds to this throw (once a round).
- `sins/gluttony.gd:29` Feast? Give up your %d for +%d (you lose the die for good).
- `sins/lust.gd:31` Whisper of Desire? Swap your %d for a %d (once a turn).
- `sins/pride.gd:30` Hubris? Bet you'll bank at least this: x%s if you do, 0 if not.
- `sins/pride.gd:54` Untouchable? Bounce %s's %s back onto them. · Fury · Binding Pact · Drag
- `sins/wrath.gd:36` Fury? %s's throw is worth %d. Make them reroll their %d best dice.
- `ui/main.gd:948` The game is done. %s reached %d. · New game

**Offer prompt and answers (TABLE)**
- tempt_prompt: {sin} tempts you.
- accept: Accept
- refuse: Refuse
- tempt_tip: Accept for the gain and take its mark. {marks} marks, and it claims you.
- tempt_context: This turn {pts}  ·  {strikes}  ·  You {me}  ·  Leader {lead}
- tempt_context_lead: This turn {pts}  ·  {strikes}  ·  You lead {me} to {lead}

## 4. Labels

WORDS: seals, banners, the opening card, results, Sin select, the pause menu, the bot-turn summary (the table uses `their_turn`; the rest shows on main's screens and the old board). TABLE: the menu line, offer screen and chips. Terms: the offer's gain and cost.

**WORDS**
- score: Score
- dice: Dice
- this_turn: This turn {n}
- strikes: Strikes
- throw_cap: Throw
- bank_cap: Bank
- your_turn: Your turn
- their_turn: {name}'s turn
- purgatory_need: Purgatory: a 6 frees you
- at_dice_you: You are at the dice.
- at_dice: {name} is at the dice.
- chronicle_turn: {name}'s turn ({score})
- chronicle_your_turn: Your turn ({score})
- open_title: You are {sin}
- open_epithet: {sin}, {epithet}: {play}
- open_greater: From {greater_at} points: {ability}
- open_goal: Be the first to {win} points.
- open_first: You throw first.
- open_seat: You throw {ordinal} of {count}, so you start with {score} points.
- open_seat_plain: You throw {ordinal} of {count}.
- open_begin: Begin
- res_scores_one: {faces} scores {sum}.
- res_scores: {faces} score {sum}.
- res_scores_mult: {faces} score {sum}, {mult} = {total}.
- res_nothing: Nothing scores.
- res_strike:  One Strike.
- res_strikes:  {count} Strikes.
- res_bust: Third Strike: bust. This turn's points are lost.
- cause_bank: Banked
- cause_buy_one: Bought a die
- cause_buy: Bought {n} dice
- cause_purgatory: Purgatory
- cause_score: Score
- setup_title: Choose thy Sin
- setup_blurb: {others} shall face thee. First to {win}.
- setup_blurb_first: Three others shall face thee. First to {win}. Finishing a game unlocks Greater abilities and the Table of 7.
- setup_three: Three others
- setup_six: Six others
- setup_table: Table of {n}
- setup_recommended: Recommended
- setup_choose: Choose
- pause_title: Paused
- pause_resume: Resume
- pause_rulebook: Rulebook
- pause_sins: Sin abilities
- pause_chronicle: Chronicle
- pause_settings: Settings
- pause_menu: Main menu
- sum_playing: at the dice
- sum_bank: banked {n} (now {score})
- sum_bust: went bust, lost {n}
- sum_buy_one: bought a die
- sum_buy: bought {n} dice
- sum_ability: {ability}
- sum_attack: {ability} on {target}
- sum_freed: left Purgatory
- sum_stuck: stays in Purgatory

**TABLE**
- menu_sub: Throw the dice. Bank or burn. Resist the Sins.
- tempt_tip: Accept for the gain and take its mark. {marks} marks, and it claims you.
- tempt_prompt: {sin} tempts you.
- tempt_context: This turn {pts}  ·  {strikes}  ·  You {me}  ·  Leader {lead}
- tempt_context_lead: This turn {pts}  ·  {strikes}  ·  You lead {me} to {lead}
- accept: Accept
- refuse: Refuse
- accepts: accepts
- refuses: refuses
- temptation: Temptation
- answer: Answer
- claimed: {sin} claims you: {claim}
- chip_bank: -{n} / next Bank
- chip_strike: Strike / next turn
- chip_fewer: -{n} dice / next turn
- chip_fewer_1: -1 die / next turn
- chip_die: -1 die / at turn end
- hubris_name: Name {n}

**GAIN_TERMS (offer gain)**
- points: Take {n} now.
- points_leader: Take {n} from the leader.
- clear: Clear a Strike.
- dice: {Count} extra dice this throw.
- x2: Throw at x2.
- die: A free die.

**COST_TERMS (offer cost)**
- lose: Lose {n} now.
- bank: Your next Bank loses {n}.
- strike: Start next turn with a Strike.
- fewer: {Count} fewer dice next turn.
- fewer_1: One fewer die next turn.
- die: Lose a die after this turn.

Typed in table code:

- `ui/table_blockout.gd:486` Bank
- `ui/table_blockout.gd:487` Throw
- `ui/table_play.gd:429` Standings
- `ui/table_play.gd:463` Close
- `ui/table_play.gd:464` Menu

## 5. Rulebook and glossary

Shows: the rulebook (pause menu) and tap-to-explain cards.

**FIVE (the first game in five sentences)**
- On your turn, throw all your dice as often as you like, then Bank to keep this turn's points.
- 4, 5 and 6 score {face_mult} times their face; 3 does nothing; 1 and 2 are Strikes.
- Scoring several dice in one throw is worth more.
- Bust: your third Strike in a turn loses this turn's points.
- After you bank you may buy dice for {die_cost} each, and the first to {win} wins.

**Page**
- contents
- The Rules
- 

**Page**
- goal
- Goal
- windows
- Be the first to reach {win} points.
- Everyone at the table plays one of seven Sins, and each Sin bends one rule in its favour.
- Players further from the first seat start a little ahead: {seat_bonus} points for each seat.

**Page**
- turn
- Your Turn
- turn
- On your turn, throw all your dice.
- After each throw, choose: throw again, or Bank to keep this turn's points. The points from every throw add up until you bank or bust.
- There's no limit on throws. Each one can score more, and each one can bring a Strike.

**Page**
- scoring
- Scoring
- scoring
- 4, 5 and 6 score {face_mult} times their face: {f4}, {f5} and {f6}. 3 does nothing. 1 and 2 are Strikes.
- Scoring several dice in one throw is worth more: two scoring dice {x2}, three {x3}, four {x4}. The game always shows the sum for you.
- Example: you throw 4, 6 and 3. The 4 and 6 score {ex_sum}, and two scorers make it {x2}: {ex_total}.

**Page**
- strikes
- Strikes and Busting
- strikes
- Every 1 and 2 you throw is a Strike. Strikes add up over your whole turn: each one snuffs a candle beside the dice.
- Bust: your third Strike in a turn loses this turn's points.
- Your Strikes clear when your turn ends.

**Page**
- banking
- Banking
- bank
- Bank to add this turn's points to your score. Your turn then ends.
- Banking early is safe. Throwing again can win more, or lose it all.

**Page**
- buying
- Buying Dice
- buying
- After you bank, you may buy dice for {die_cost} each. They're yours for the rest of the game.
- More dice score more, but they also throw more Strikes.
- The table holds a limited supply of dice. When it runs out, no one can buy.

**Page**
- sins
- Sins and Greater Abilities
- tiers
- Every Sin has a power: once a turn, when its seal glows, tap it to use it.
- The first time you reach {greater_at} points, your Greater ability unlocks for good. You can use it once a round.
- First Game: no powers or Greater abilities, at a table of 4. Finishing a game unlocks them and the Table of 7.

**Page**
- temptations
- Temptations
- 
- Once a turn, a rival Sin may offer you a deal: a gain now for a cost later. Accept or refuse with one tap.
- Accepting gives you that Sin's mark. A Sin whose mark you hold comes back to tempt you again.
- {marks} marks from one Sin, and it claims you: its claim binds you for the rest of the game.

**Page**
- winning
- Winning
- winning
- The first player to reach {win} points wins the game at once.

**Page**
- all_sins
- The Seven Sins
- 

**Page**
- glossary
- Glossary
- 

**TERMS**
- **Throw:** Throw all your dice at once. After each throw, throw again or bank.
- **Turn:** Your go: throw as often as you like, until you bank or bust.
- **Round:** Everyone at the table takes one turn.
- **Score:** Your banked points. The first to {win} wins. Points only count once you bank them.
- **Dice:** How many dice you throw each time. You start with {start_dice}; buy more for {die_cost} each after you bank.
- **This turn:** Points from this turn's throws so far. Bank to keep them; bust and they're lost.
- **Scoring:** 4, 5 and 6 score {face_mult} times their face: {f4}, {f5} and {f6}. 3 does nothing. 1 and 2 are Strikes.
- **Multiplier:** Scoring several dice in one throw is worth more: two scoring dice {x2}, three {x3}, four {x4}. The game does the sum for you.
- **Strike:** Every 1 or 2 you throw is a Strike. They add up over your turn. A third Strike is a bust.
- **Strikes:** The three candles beside the dice: each Strike this turn snuffs one. All three out is a bust.
- **Bust:** Your third Strike in a turn: you lose this turn's points.
- **Bank:** Keep this turn's points: they're added to your score and your turn ends.
- **Power:** Your Sin's seal: once a turn, when it glows, tap it to use it.
- **The Vig:** Greed's lasting rule: when a rival buys a die, Greed gets {vig} of its price.
- **Buy dice:** After you bank, buy dice for {die_cost} each. More dice score more, and throw more Strikes.
- **Supply:** The dice left on the table to buy. When it's empty, no one can buy.
- **Sin:** The character you play. Each of the seven Sins bends one rule with its abilities.
- **Basic ability:** Your Sin's first ability. You have it from the start.
- **Greater ability:** Your Sin's second ability. It unlocks for good the first time you reach {greater_at}, and you can use it once a round.
- **Greater ready:** This player's Greater ability is unlocked and can be used this round.
- **Dragged:** Sloth's Drag: this player throws {drag} fewer dice next turn (never under 1).
- **Pact:** Lust's Binding Pact: Lust takes {pact} of the next turn this player banks.
- **Temptation:** A rival Sin's offer on your turn: a gain now for a cost later. Accepting gives you its mark.
- **Mark:** What you take from a Sin when you accept its temptation. {marks} from one Sin, and it claims you.
- **Claim:** A Sin's lasting rule on you once you hold {marks} of its marks. It binds you for the rest of the game.
- **First Game:** Your first game: a table of 4, no powers or Greater abilities, gentler opponents. Finish it to unlock them and the Table of 7.

## 6. Log and Chronicle

Shows: the ticker and the Chronicle (pause menu): core's log lines reworded. Pattern → as shown.

**SAY**
- `^(.+?) throws (\d+): (.+)$` → $1 throws $2 dice: $3
- `^(.+?) throws to leave Purgatory: (.+)$` → $1 throws to leave Purgatory: $2
- `^\s+Fury \(bounced\) rerolls (\d+): (.+)$` → Fury bounces back: the best $1 dice are thrown again: $2
- `^\s+Rerolled: (.+)$` → Thrown again: $1
- `^\s+\d+ Strikes: (.+?) BUSTS and goes to Purgatory\.$` → Third Strike! $1 busts, off to Purgatory.
- `^\s+\d+ Strikes: (.+?) BUSTS\.$` → Third Strike! $1 busts.
- `^\s+\+0 \(turn (\d+), Strikes \d+\)$` → {who} scores nothing ($1 this turn).
- `^\s+\+(\d+) \(turn (\d+), Strikes \d+\)$` → {who} scores $1 ($2 this turn).
- `^\s+Hubris pays off: (\d+) -> (\d+)$` → Hubris pays off: $1 becomes $2.
- `^\s+Hubris fails: (\d+) -> 0$` → Hubris fails: $1 becomes 0.
- `^\s+Binding Pact: (.+?) takes (\d+)\.$` → Binding Pact: $1 takes $2.
- `^(.+?) banks (\d+) \(score (\d+)\)\.$` → $1 banks $2. Score: $3.
- `^(.+?) buys 1 die for (\d+) \(now (\d+) dice\)\.$` → $1 buys a die for $2 ($3 dice now).
- `^(.+?) buys (\d+) dice for (\d+) \(now (\d+) dice\)\.$` → $1 buys $2 dice for $3 ($4 dice now).
- `^\s+The Vig: (.+?) takes (\d+)\.$` → The Vig: $1 takes $2.
- `^(.+?) Drags (.+?)\.$` → $1 uses Drag on $2.
- `^(.+?) binds a Pact on (.+?)\.$` → $1 binds $2 with a Binding Pact.
- `^\s+(.+?) must reroll (\d+) best dice on their next throw\.$` → $1 must throw their $2 best dice again next throw.
- `^\s+(.+?) must reroll (\d+) best dice\.$` → $1 must throw their $2 best dice again.
- `^\s+(.+?) gives (\d+)% of their next banked turn to (.+?)\.$` → $1 gives $2% of their next bank to $3.
- `^\s+(.+?) gives (\d+) of their next banked turn to (.+?)\.$` → $1 gives $2 of their next Bank to $3.
- `^\s+(.+?)'s answer: (.+)$` → $1 $2.
- `^\s+(.+?)'s claim: (.+?), for the rest of the game$` → $1 claims $2 for the rest of the game.
- `^\s+(.+?) throws at most (\d+) fewer dice next turn\.$` → $1 throws $2 fewer dice next turn.
- `^\s+A 6! Free\.$` → A 6! {who} is free of Purgatory.
- `^\s+No 6: (.+?) pays (\d+) to leave Purgatory\.$` → No 6: $1 pays $2 to leave Purgatory.
- `^\s+No 6, and (.+?) can't pay: free anyway\.$` → No 6, but $1 can't pay: $1 leaves Purgatory free.
- `^\s+(.+?)'s (.+?): \+(\d+) \((.+?) busted\)$` → $1's $2: gains $3 because $4 busted.
- `^\s+(.+?)'s (.+?): \+(\d+) for buying nothing$` → $1's $2: earns $3 for buying nothing.
- `^\s+(.+?)'s (.+?): gives up a (\d) for \+(\d+) \((\d+) dice left\)$` → $1's $2: gives up a $3 for $4 ($5 dice left).
- `^\s+(.+?)'s (.+?): first die cost (\d+)$` → $1's $2: the first die costs $3.
- `^\s+(.+?)'s (.+?): bets (\d+)\. Must bank at least \d+$` → $1's $2: bets $3. Bank at least $3, or score 0.
- `^\s+(.+?)'s (.+?): (.+)$` → $1's $2: $3.

## 7. Tutorial (not in the table build)

**TUTORIAL**
- settings_play: Play
- skip: Skip
- tap: Tap to continue
- welcome: A practice game against Sloth. The dice are set, so you'll see every rule once.
- throw: Tap Throw to throw all your dice.
- scored: 4, 5 and 6 score {face_mult} times their face; 3 does nothing. Two scorers in one throw make it {x2}.
- again: Every throw adds to this turn's points. Throw again.
- strike: A 1 or 2 is a Strike: it snuffs a candle. Strikes add up all turn.
- bank: Bank now to keep this turn's points.
- buy: After you bank, you may buy dice for {die_cost} each. More dice score more, and throw more Strikes. Buy one.
- bot: Sloth's turn. Watch its best die: your Sin can copy it.
- turn2: Your turn again, now with four dice. Throw.
- sin: You are Envy. {ability} Tap Yes.
- glance: The copy counts like any die you threw.
- risk: One candle is out. Push your luck: throw again.
- bust: Three Strikes: bust. This turn's points are lost, and your next turn starts in Purgatory.
- purgatory: Purgatory: your turn starts with a free throw. Any 6 frees you; without one you pay {purg_cost}.
- done: That's the game. Throw, bank before your luck runs out, and be the first to {win}.
- done_play: Play
- done_menu: Menu

