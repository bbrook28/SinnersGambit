# Onboarding plan (draft for Ben, 2026-11-15)

No rules text before play. The first three games teach by doing; each adds one idea. The separate scripted tutorial goes; game one is the tutorial. The rulebook stays in the pause menu, and a hold explains anything.

## Game one: throw, bank, bust
Table: you + 2 bots, Sins' abilities off, no temptations, bots cautious. The opening card goes; the game opens straight onto your first decision with Throw lit.
Dice are rigged for your first two turns only (the tutorial already rigs dice this way):
- Turn 1, throw 1 scores (gold dice lift). Throw 2 adds one Strike (a candle goes out). Bank is lit.
- A bot's first turn busts while you watch: three candles out, its pile swept away.
- From your turn 2 on, the dice are fair. You can bust; nothing stops you.

Captions (5, six words or fewer, each shown once, at the moment it's true):
1. "Tap Throw." (your first decision)
2. "Gold dice score. Throw again?" (after the first scoring throw)
3. "Three red Strikes and you bust." (the first Strike)
4. "Bank keeps your points." (first time Bank is lit with points at stake)
5. "First to 1000 wins." (your first Bank, as your marker moves up the track)

Done when: the game ends. Win or lose, game two unlocks. Measure: time to first Bank, busts in game one.

## Game two: your Sin
Abilities on (Basic only). Before the first turn, your Sin's window comes forward and acts its ability once, with its one icon; no card. The first time it can act in play, it does, and one caption names it in six words or fewer (from `RulesText`, one per Sin, for your OK). Rivals' abilities show the same way, by acting, the first time each fires. Still no temptations.

## Game three: temptations
Temptations on. At your first decision where an offer fits, one comes (forced, the cheapest-cost offer). One caption, once: "Accept: gain now, take its mark." The first mark shows on your window; a claim is explained by a hold, not a caption.

## Mapping
- **Solo ladder:** Circle 1 = game one (you + 2 bots, First Game). Circle 2 = game two (abilities on, no temptations). Circle 3 = game three (temptations on; first forced offer). TableDesign §6-7 changes: temptations start at Circle 3, not Circle 2; C1-2 stay at you + 2 bots, C3 moves to you + 3 bots as planned.
- **Table game first:** the same three steps follow your total games played across both modes (`games_finished` 0, 1, 2). A first Table game with 4+ seats is still game one (abilities off, no temptations, rigged first two turns); the table setup screen notes "First game: basics only."
- **Replay:** Settings > Tutorial resets the counter to replay game one.

## What changes in code (after your OK)
`ui/tutorial*.gd` retires; a small `ui/onboarding.gd` holds the step, the five captions and the rigged dice; `main._opening_card()` is skipped in game one; offers gated on step 3. No `core/` change: rigging reuses the tutorial's dice hook in `ui/`.
