# The Pact: options

Status: paper design for Ben, 2026-11-26. Ben's rulings of the same day are in the next section and win over the options below wherever they differ. Nothing built. Rules it sits on: `docs/step1-rules.md`. Why: `docs/fun-brief.md`, moment 2 (promises made and broken) and moment 5 (messing with others).

Every number here is a starting value, not a measured one, unless it says "measured". Measured numbers are from today's bot sims (20,000 matches a run, raw files in `build/sim_step1/out/whisper/` and `out/2p/`). Bots are not people: treat them as a rough guide.

## Ben's rulings, 2026-11-26
The Pact stays on paper: no code yet.
1. **Table-wide at 4 players, off at 2.** Any two players can seal a Pact, one Pact per player. It is not Greed's ability. Cut a Deal is not replaced by it and stays as it is (section 1's "Greed only" answer is not taken).
2. **Whisper of Desire betrays at double: two swaps.** Changed by Ben on 2026-11-27 (it was one swap at normal strength). The caught roll is the same as for every other ability. The option C limit applies to both swaps: neither swap can be what takes the player to 1000.
3. **At 700 the perk stops, the Pact still binds.** A partner on 700 or more gets no perk. Neither partner can target the other until the Pact is broken or left. This replaces guard 1 in section 4.
4. **Leaving openly is allowed.** A player can say they are leaving; it takes effect on that player's next turn. No die, no penalty.
5. **The numbers are Rising stakes** (version C in section 2): perk 10 a turn each, caught on a 1 or 2, penalty 50 plus every perk point this Pact has paid the betrayer.

What follows from them:
- With two Pacts at a 4 player table, each player can target two of the three others. That cost of table-wide was accepted with ruling 1.
- Past 700 a leader keeps the Pact's protection and loses only the perk. The answers left to the partner are betrayal (the die) or leaving (a full round's notice). Watch in the first playtest whether a leader hides behind a Pact to the end.
- Between saying "I leave" and that player's next turn, the Pact still binds and can still be betrayed, by either partner. The partner has one round to betray first.
- Rising stakes with the perk stopped: the penalty stops growing for a partner on 700 or more, because no more perk is paid to them.

Second round of rulings, 2026-11-27:
6. **Off at 3 players, for now.** Two players sealing against the third decides the game. The next Pact test is at 4; settle 3 later.
7. **No perk once you announce you are leaving.** The pay stops at once for the player who announced; the protection holds until their next turn. Their partner is still paid until the Pact ends. Under Rising stakes the leaver's penalty stops growing from that moment.
8. **Entangling Allure betrays at normal strength.** (Unlike Whisper, which is doubled since ruling 2 changed.) A normal use cannot include your partner as one of the two players. Including them is a betrayal at normal strength, with the caught roll.

Ruling 8 checked against Allure as built (`game/rules.gd`; 40 points; Lust chooses 2 players, each picks one die of their last roll in secret; match: Lust takes one of the two dice to keep, Lust's choice when both owners can spare it; no match: the two dice swap, which changes no one's points). The reading works, with these points fixed so the screen can state them:
- The Master's die is rolled when Lust confirms the two players, before the phone goes round for the secret picks. Caught: no picks happen, the 40 is still paid, Allure counts as used, the Pact ends and the penalty is paid. The other chosen player is untouched.
- Not caught: Allure runs exactly as written. On a match Lust may take the partner's die or the other player's.
- Only Lust's own partner makes it a betrayal. Choosing two players who are bound to each other is a normal use.
- It is nearly all risk for Lust. Most uses do the partner no harm: a match came up in about 15% of bot uses (measured at 2 players, 20,000 matches; not measured at 4), and a swap costs the partner nothing. So Lust pays a 1 in 3 chance of the penalty for about a 1 in 7 chance of taking a die. Expect it to be rare. Lust's real betrayal is the doubled Whisper (ruling 2).

Still open:
- 3 players, later (ruling 6).

## The idea, as Ben gave it
Two players seal a Pact. While it holds, neither can target the other with abilities, and each gets a small perk every turn. Either can betray by using an ability on their partner: one die is rolled. Success: the ability lands twice. Caught: the ability does nothing, the Pact ends, and the partner takes points from the betrayer. The odds and both outcomes are shown before the betrayer commits. One Pact per player.

## 1. Should it replace what Cut a Deal does now?
Not taken: Ben ruled the Pact table-wide (ruling 1). Kept for the record.

Yes, with one condition: the Pact becomes Greed's Tier 2 (the name Cut a Deal stays), and it is not a rule every player has.

Why replace:
- Cut a Deal today is not a deal. The target is forced to pay 50 or hand over a die. Nothing is promised and nothing can be broken.
- It loses Greed points. Measured at 4 players: each use costs Greed 60 and the others 11 between them. Greed wins 9% of sim matches where a fair share is 25%.

Why Greed only, not everyone:
- It is one ability's worth of rules and screens, not a new system for all seven Sins.
- With a Pact open to everyone, a 4 player table can hold two Pacts. Then each player can target only two of the three others, and moment 5 shrinks.
- At 3 players a table-wide Pact leaves one player out with no perk. At 2 players it switches off every targeting ability and the perks cancel out.
- It gives Greed something only Greed does, next to The Vig.

The hole in Greed only: Greed has no ability that targets, so Greed could never betray. Fix: Greed's betrayal is the old Cut a Deal (partner pays 50 or gives a die for a round), doubled on success like any other.

If you want the Pact for every player anyway, leave Cut a Deal as it is for now. That is a larger build and the 3 player and 2 player problems above need an answer first. At 2 players I would switch the Pact off in both versions.

## 2. Three versions of the numbers
"Net" is what a betrayal is worth against using the same ability on someone else at normal strength. V is what one use of the ability is worth, c the chance of being caught, P the penalty: net = V x (1 - 2c) - c x P. It ignores the perks both players lose when the Pact ends.

| Version | Perk a turn, each | Caught on | Penalty | Net for a 50 point ability | What it plays like |
|---|---|---|---|---|---|
| A. Loose seal | 10 | 1 or 2 (33%) | 50 | 0 | Betrayal is a coin flip in value. Expect most Pacts to end in one. |
| B. Firm seal | 20 | 1, 2 or 3 (50%) | 100 | -50 | Betrayal loses points on average. It happens only to stop a partner who is about to win. |
| C. Rising stakes | 10 | 1 or 2 (33%) | 50, plus every perk point this Pact has paid the betrayer | 0 at first, falling by about 3 a turn | Cheap to break early, dear to break late. The longer the trust, the bigger the fall. |

For scale (measured, 4 players): a match is about 8 turns each, and a roll scores about 100 to 115 for most Sins. A 10 point perk over a 5 turn Pact is 50 each, 5% of the goal. A 20 point perk is 10%.

Chosen: C, Rising stakes (ruling 5).

Test for any version: in a sim with a simple betrayal bot, and then at the table, count Pacts sealed a match and the share that end in betrayal. Pass: at least one Pact sealed in most matches, and between a third and two thirds of them betrayed. No one seals: raise the perk. Everyone betrays at once: raise the penalty or the caught odds. No one ever betrays: lower them.

Rules the versions share, so the screen can state them:
- Sealing takes the partner's tap to agree, like a gift. The cost is paid only when they agree.
- The die is rolled after the betrayer confirms and before any other choice.
- Caught: the ability's cost is still paid and it counts as used this turn.
- The Pact ends on a betrayal, caught or not. A player can also leave openly, with no die and no penalty; it takes effect on that player's next turn (ruling 4).
- No Pact with or by a player in Purgatory. A partner who falls into Purgatory keeps the Pact but gets no perk.

## 3. Which abilities break if doubled
| Ability | Doubled means | Verdict |
|---|---|---|
| Voracious Bite | Steal 40 | Fine. |
| Vengeful Strike | Lose 100, or 1 die for 4 full rounds | Fine with the die option as rounds, not as 2 dice (2 dice can break the 2 dice floor). |
| Spark of Rage | Reroll two dice showing 5 or 6 | Works. It is used out of turn, so the betrayal screen has to work on another player's turn. |
| Lethargic Aura | Two dice rolled twice next turn; Sloth gains 20 | Works. Needs its own line on the card. |
| Old Cut a Deal (Greed's betrayal) | Pay 100, or 1 die for 2 full rounds | Fine. |
| Jealous Grasp | Whatever it copies | Follows the copied ability. |
| Entangling Allure | Nothing sensible | Breaks if doubled: it names two players and its result is a match or a swap. Ruled: a normal use cannot include your partner; including them is a betrayal at normal strength (ruling 8). |
| Whisper of Desire | Two swaps | Ruled: doubled, two swaps, with the 1000 limit on both (ruling 2). The size and timing risks below stand. |
| Green-Eyed Glance, Hubris, Feast, Slow Drip, The Vig, Superiority | Not targeting | Not blocked by a Pact and never a betrayal. An armed Superiority still costs a betrayer 20. |

Whisper of Desire, three reasons:
- Size. One swap is worth 57 points a use (measured, 4 players). Two swaps is about 110 before the roll is scored, on a Tier 1 that is free and usable every turn.
- The end-game leap gets bigger. Today 3% of Whisper uses win the match on a roll that would not have won unswapped, and that is 41% of Lust's sim wins. Doubling makes that swing twice as large.
- Timing. Whisper happens between the roll and the scoring. A betrayal die there puts a second roll inside the first.

Ruled (ruling 2, as changed 2026-11-27): a Pact blocks Whisper on your partner unless Lust breaks the seal. Lust betrays with two swaps and the usual die. Caught: no swap, the roll is scored as it is, the Pact ends and the penalty is paid. The die is rolled between Lust's roll and its scoring, so the screen has to show the betrayal result before the roll's score.

How the 1000 limit reads with two swaps: each swap is judged as it is made, against the roll as rolled. If the roll as rolled does not reach 1000, the first swap cannot reach it, and neither can the second on top of the first. If the roll as rolled already reaches 1000, both swaps are free. So the doubled Whisper cannot create the end-game leap, which answers the second of the three reasons above.

What it is worth: about 110 points on one roll (57 a swap, measured at 4 players), against a 1 in 3 chance of losing the swap and paying 50 plus the perks. In the section 2 sum that is a net of about plus 20 at the start of a Pact, the best betrayal at the table, and Lust can do it every turn the Pact is new. Watch this first in a Pact test.

Assumptions to confirm before any build:
- Both swaps take dice from the partner. (If the second could come from anyone, only the first is a betrayal.)
- The two swaps use two different dice of Lust's. Swapping the same die twice would waste the first.
- If only one allowed swap exists (one higher die, or the limit refuses the second), Lust makes one swap and the betrayal still counts.

## 4. Can a leader abuse a Pact for protection?
Yes. The leader's best Pact is with whoever hurts them most. Measured harm per use at 4 players: Vengeful Strike 50, Spark of Rage 37, Voracious Bite 20, and bots aim these at the leader. A leader sealed to Wrath is safe from about 37 a round plus the Strike, and is paid a perk for it. The partner has a reason to agree too: the perk, and safety from the leader.

Betrayal is the built-in answer, and in version B it is too costly to be one.

Guards, cheapest first:
1. The seal breaks at 700. No Pact can be sealed by or with a player on 700 or more, and a Pact ends with no penalty when either partner reaches 700. The last stretch is every player for themselves. (700 is a starting value: 70% of the goal.)
2. A leading partner is easier to betray: caught only on a 1 when your partner has more points than anyone else.
3. A Pact lasts 2 full rounds, then must be sealed again.

Ruled (ruling 3): none of these as written. At 700 the perk stops and the Pact still binds. So the leader is no longer paid for hiding, but is still protected from their partner until the partner betrays or leaves. Guards 2 and 3 stay available if leaders hide in play.

## 5. Wording
The witness is the Master of the Dance. He holds the seal, rolls the die, and collects.

- The mechanic: **Binding Pact**. Players in one are **bound**. The tag on a player: BOUND TO PLAYER 3.
- To make one: **Seal a Pact**. Offer screen: "Player 1 offers a Binding Pact. While it holds, neither of you can use an ability on the other, and each of you gains 10 at the start of your turn. Player 3, do you seal it?" Buttons: Seal it, Refuse.
- Sealed: "The Master of the Dance witnesses the Pact between Player 1 and Player 3."
- The perk line: "Bound: the Pact pays you 10."
- A blocked ability: "Bound to Player 3: you cannot use this on them unless you break the seal."
- To betray: **Break the seal**. Confirm screen: "Break the seal on Player 3 with Vengeful Strike? The Master rolls one die. 3, 4, 5 or 6: the Strike lands twice. 1 or 2: you are Forsworn. The Strike does nothing, the Pact ends, and the Master takes 50 from you for Player 3." Buttons: Break the seal, Keep my word.
- Success: "The Master looks away. Player 1 broke the seal: Vengeful Strike lands twice on Player 3. The Pact is ended."
- Caught: "Forsworn. The Master saw. Player 1's Vengeful Strike does nothing, the Pact is ended, and the Master takes 50 from Player 1 for Player 3."
- The penalty: **the Master's due**.
- At 700 (ruling 3): "Player 1 has passed 700. The Pact pays them no more. It still binds."
- Leaving (ruling 4): button "Leave the Pact". Line: "Player 1 has told the Master they will leave the Pact with Player 3. It holds until Player 1's next turn." Then: "The Pact between Player 1 and Player 3 is ended. No one is Forsworn."
- A Whisper betrayal (ruling 2): "Break the seal on Player 3 with Whisper of Desire? The Master rolls one die. 3, 4, 5 or 6: you swap two of your dice for two of theirs. 1 or 2: you are Forsworn. No swap, the Pact ends, and the Master takes 50 and the 30 the Pact has paid you, for Player 3."
- The penalty under Rising stakes, on the confirm screen, always as a number: "the Master takes 50 and the 30 the Pact has paid you".

## Risks
- Clarity. "Lands twice" means something different for each ability. Each card needs its own doubled line, and the confirm screen must spell out both outcomes with numbers every time.
- It may replace talk with a button. The brief's promises are free and not binding. A sealed Pact with a perk could become the only deal anyone makes. Watch for this in the first playtest.
- Scope. `docs/step1-rules.md` lists "the Master's call" under "Not in step 1". The Master as witness is wording only here, but it is a new presence on a flat blockout screen.

## What a playtest of it would answer
Does anyone seal a Pact, and does anyone break one? If no one seals, the perk is too small or the screen is too slow. If no one breaks, the Pact is a quiet alliance and adds nothing to moment 2. Either result changes the numbers above before anything else is built.
