# Step 1 rules: 2 to 4 players, one phone

Status: **Approved by Ben 2026-11-24.** Brief: `docs/fun-brief.md`. Build notes: `docs/step1-build.md`.
Sources: Ben's 2025 printed rulebook (`Sinners Gambit.pdf`, 21 pages), his rulings of 2026-11-24, and the Sin cards in the Google Doc rulebook. Where the PDF and the Google Doc differ, the PDF wins. The PDF has no Sin cards, so every ability below started as the Google Doc's, copied as written; Ben's later rulings, each dated below, changed some costs and numbers.

## The game
- **Goal:** first to 1000 points (Ben's ruling, 2026-11-25, a starting value under test; the rulebook's goal is 3000). It is checked at the end of your own Fate Phase: the first player to end a Fate Phase at 1000 or more, and not in Purgatory after that roll, wins at once. You cannot win while in Purgatory (Ben, 2026-11-24). There is no tie-breaker.
- **Players:** 2, 3 or 4, passing one phone; chosen on the How to play card before the first turn (Ben, 2026-11-26; it was 4 only). No bots. The rules are the same at every table size except the two readings under "Two players" below.
- **Dice:** each player starts with 3, and the shared supply starts with 6 spare dice at any table size (4 players: 18 dice in all). Ben's ruling, 2026-11-25: a seven-player table with the 27-dice box has 6 spare, and with 15 spare at a four-player table everyone bought dice freely and no one made a deal. A die still costs 20. No one ever drops below 2.
- **Sins:** one each, shown to everyone. On the How to play card the players either pick them, the phone passed in seat order and each tapping a Sin no one has taken yet, or tap "Deal them out" for a random deal (Ben, 2026-11-26; it was the random deal only).
- **Start:** everyone at 0 points. Turns go round in seat order.
- **Points never go below 0.** A loss stops at 0, and you cannot pay a cost you do not have.
- **Last rolls stay on screen.** Each player's last roll stays shown until they roll again. Those are the dice other players' abilities see and act on.

## Your turn
**1. Fate Phase**
- Roll all your dice once. No reroll unless an ability gives one.
- A 4, 5 or 6 scores 40, 50 or 60. A 1, 2 or 3 scores nothing.
- **Purgatory:** if every die shows 1, 2 or 3, you score 0 and your turn ends.
- Otherwise add up your scoring dice and go on to the Gambit Phase.

**2. Gambit Phase**, in any order, as often as you like, then pass:
- **Talk.** Promises are not binding. Lying is allowed.
- **Use abilities:** one Tier 1 and one Tier 2 a turn.
- **Buy a die:** 20 points from the supply, at most one die a turn (Ben's ruling, 2026-11-25). The die Gluttony buys back after Feast is that one die. You roll it from your next turn.
- **No gifts.** Giving points, lending a die and buying a die for another player were cut by Ben on 2026-11-26, after the 0.21.0 playtest, and with them the rule that a die bought for another player is extra. Deals are talk only.

## Purgatory
- While you are in Purgatory you cannot buy or use abilities.
- On your next turn, roll your dice as usual. Two or more dice showing 1, 2 or 3 frees you. Fewer, and your turn ends with nothing scored, whatever the roll shows; you try again next turn.
- The escape roll is never checked for Purgatory. Once free, you score its 4s, 5s and 6s and play on into your Gambit Phase.

## Abilities
Tier 1 is open from the start. Tier 2 opens when you reach 350 points and stays open even if you drop below. Tier 3 is not in step 1. Cut a Deal costs 70, not the card's 50 (Ben's ruling, 2026-11-25, a starting value under test); what the target pays is still 50. A won Hubris scores the roll plus 50, not the card's double (Ben's ruling, 2026-11-26, a starting value under test: with doubling Pride won 46% of sim matches at a five-Sin table, where a fair share is 25%). A Whisper of Desire swap is refused if it is what takes the player to 1000 or more (Ben's ruling, 2026-11-26, after the 0.19.0 playtest: swaps were pushing players over the goal at the climax; in the sim 41% of Lust's wins came that way). A roll that reaches 1000 without the swap can still be swapped. A Whisper copied by Jealous Grasp is refused the same way (Ben confirmed, 2026-11-26).

**Green-Eyed Glance (Ben's ruling, 2026-11-26, after the 0.20.0 playtest: Envy won on 1050 in round 6 with the others on 630 to 670).** The copied number stands in for one of Envy's dice, which is not rolled; it was an extra die. And it cannot be used on two of Envy's turns running, at any table size: after a use it is refused on Envy's next turn and open again on the one after. Jealous Grasp cannot copy it, as before (it works before the roll). Sim, bots, four players, full and lean pass: Envy won 75.5% and 66.8% of matches as first written, 38.4% and 27.7% with this; a fair share is 25%. A starting value under test.

**Feast (Ben's ruling, 2026-11-26, after the 0.21.0 playtest).** Feast gains 120, not 150, and cannot be used on two of the player's turns running, at any table size: after a use it is refused on their next turn and open again on the one after. A Feast copied by Jealous Grasp follows the same rest: Envy cannot Feast on two of Envy's turns running. Sim, bots, four players, 20,000 matches a row on two seeds, full and lean pass: Gluttony won 24.4% and 37.8% of matches at 150 with no rest, 23.5% and 25.0% with this; a fair share is 25%. Feast was 60% of the points Gluttony gained before and is 41% with this. The rest is what closes the gap between the two passes; 120 with no rest gave 15.6% and 26.0%. A starting value under test: if Feast still runs away, 100 with the rest (18% in both passes); if Gluttony feels dead, 150 with the rest (31% and 34%). Raw reports: `build/sim_step1/out/feast2/`.

**Once a turn (Ben's ruling, 2026-11-25):** every ability can be used at most once per turn by the player whose turn it is. The passive abilities (The Vig, Slow Drip) are unchanged. "Not the same target twice running" still holds.

| Sin | Tier 1 (free) | Tier 2 |
|---|---|---|
| Wrath | **Spark of Rage:** make a player reroll one die showing 5 or 6. If it comes up 1-3 they score 0 for it and lose 10. | **Vengeful Strike (50):** target chooses: lose 50, or give you 1 die for 2 full rounds. Not the same target twice running. |
| Greed | **The Vig:** passive. When an opponent buys a die, 20 of its price goes to you. | **Cut a Deal (70):** target chooses: pay you 50, or give you 1 die for 1 full round. Not the same target twice running. |
| Lust | **Whisper of Desire:** before scoring, swap one of your dice with a higher die of another player's. Not if the swap is what takes you to 1000. | **Entangling Allure (40):** choose 2 players; each secretly picks 1 die. Match: you take one. No match: they swap. |
| Envy | **Green-Eyed Glance:** before you roll, copy any die an opponent just rolled: one of your dice is not rolled and shows that number. Not on two turns running. | **Jealous Grasp (30):** copy any Tier 1 ability used this round. Not the same one twice running. |
| Pride | **Hubris:** before you roll, declare. Beat the previous player's total and score 50 more for the roll; fail and it is 0. First player must beat 50. | **Superiority (40):** passive. The first time you are targeted each round, the attacker loses 20. |
| Gluttony | **Feast:** give one of your scoring dice (4-6) to the supply and gain 120. Not on two turns running. | **Voracious Bite (20):** steal 20 from a player. Not the same target twice running. |
| Sloth | **Slow Drip:** if you score under 60 this turn, gain 40 more. | **Lethargic Aura (30):** next turn the target rolls 1 die twice and keeps the lower. You gain 10. |

How five of them work on one phone:
- **Wrath's Spark of Rage.** Every other player's roll result that has a 5 or 6 shows a Spark of Rage button; a roll with no 5 or 6 shows none, and on Wrath's own turn the ability button is not shown while no other player's roll has one (Ben, 2026-11-26). Wrath calls it out loud and taps it, at most once a round. The phone is not passed to Wrath and there is no hidden prompt: everyone is in the same room.
- **Lust's Whisper of Desire.** A die whose swap would be what takes Lust to 1000 is switched off and marked "to 1000"; if every swap would, the Whisper button is switched off with the reason. The match log says which swaps were refused on that roll (Ben, 2026-11-26).
- **Pride's Hubris.** "The previous player's total" is the points the player before you scored on their last roll (0 if they were in Purgatory). The 50 is for the roll, not for each die: if Spark of Rage rerolls a die of a won Hubris roll, the die's change counts once and the 50 stays.
- **Pride's Superiority.** Pride pays 40 in their own Gambit Phase to arm it until their next turn.
- **Lust's Entangling Allure.** The phone is passed to each chosen player in turn; each taps one die from their own last roll with the screen showing nothing to the others; then both picks are shown together. "Match" means the two dice show the same number. Nothing else about it changes.

## Two players
Ben's rulings, 2026-11-26. Everything else is as above: 3 dice each and 6 spare (12 dice in all), first to 1000, Hubris against the other player's last roll, and Green-Eyed Glance and Feast not on two of your own turns running.
- **"Not the same target twice running"** (Vengeful Strike, Cut a Deal, Voracious Bite) and Jealous Grasp's "not the same one twice running": with one opponent there is no one else to choose, so it means not on two of your turns running. After a use it is refused on your next turn and open again on the one after. At 3 or 4 players it is as before: refused until you choose another target.
- **Entangling Allure:** Lust is one of the two. Lust picks one die of their own last roll in secret, then the phone goes to the other player, who picks one of theirs. Match: Lust takes the other player's die, to keep (nothing is taken from a player on 2 dice). No match: the two dice swap. Only the other player counts as targeted.
- The Sin cards for these five abilities have their own words at a two-player table (`TWO` in `game/sins.gd`).
- Not measured: the sims so far were at four seats.

A die taken by an ability stays away for as long as its card says (Wrath 2 full rounds, Greed 1 full round), not the PDF's "until the owner's next Fate Phase".

## Not in step 1
Tier 3 abilities, the chain multiplier, bets, the Master's call, comeback offers, temptations, marks, claims, bots, new art.

## Known risks
- The ability numbers come from the Google Doc, where a die cost 100; the PDF prices a die at 20. So some abilities are stronger than either edition intended. Feast was the clearest case (gain 150, then buy the die back for 20) and was changed on 2026-11-26, above.
- In the Feast sim Lust won 44% to 64% of matches and Envy 27% to 41% in every row, at a four-player table dealt from all seven Sins. Not addressed in 0.22.0.
