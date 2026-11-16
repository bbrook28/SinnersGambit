# Onboarding plan (approved by Ben, 2026-11-15; captions approved, REPLY 2)

No rules text before play. The first three games teach by doing; each adds one idea. The scripted tutorial goes; game one is the tutorial. The Master of the Dance (`Docs/TableDesign.md` §10) narrates all three: every caption is his, 8 words or fewer, shown once at the moment it's true. Captions aren't lines: they ignore his one-in-three chance, and no other line plays in the same beat. The rulebook stays in the pause menu, and a hold explains anything.

## Game one: throw, bank, bust
Table: you + 2 bots, no abilities, no temptations, first-game bots (TableDesign §10). No opening card: the Master bows, and the game opens straight onto your first decision with Throw lit.
Dice are rigged for your first two turns only (the tutorial already rigs dice this way):
- Turn 1: throw 1 scores (gold dice lift), then throw 2 adds one Strike (he snuffs a candle). Bank is lit.
- A bot's first turn busts while you watch: he snuffs its candles, and its stake is blotted.
- From your turn 2 on, the dice are fair. You can bust; nothing stops you.

Captions:
1. "Tap Throw, dear guest. The dance begins." (your first decision)
2. "Gold dice score. Dare another throw?" (after the first scoring throw)
3. "Red is a Strike. Three, and you bust." (the first Strike)
4. "Bank, and those points are safely yours." (first time Bank is lit with points at stake)
5. "First to a thousand wins the dance." (your first Bank, as your marker moves along the track)

Done when: the game ends. Win or lose, game two unlocks. Measure: time to first Bank, busts in game one.

## Game two: your Sin
Abilities on (powers only, no Greater). Before the first turn the Master presents your Sin; its window comes forward and its seal lights once. The first time your power is usable:
6. "Your Sin's seal glows. Once a turn: tap."
The power's own line (10 words or fewer) shows once beside the seal. Rivals' powers show by acting, the first time each fires, with the Master's bow towards that window. Still no temptations.

## Game three: temptations
Temptations on. At your first decision where an offer fits, the Master announces the Sin and its offer comes (forced, the cheapest-cost offer):
7. "Accept: gain now, and wear its mark."
The first mark shows on your edge with one of his mark lines; a claim is explained by a hold, not a caption.

## Mapping
- **Solo ladder:** Circle 1 = game one (you + 2 bots). Circle 2 = game two (powers on, no temptations). Circle 3 = game three (temptations on; first forced offer). Until this is built, TableDesign §6-7 stand (temptations from Circle 2).
- **Table game first:** the same three steps follow your total games played across both modes (`games_finished` 0, 1, 2). A first Table game with 4+ seats is still game one (no abilities or temptations, rigged first two turns); the table setup screen notes "First game: basics only."
- **Replay:** Settings > Tutorial resets the counter to replay game one.

## What changes in code (after Ben's OK)
`ui/tutorial*.gd` retires; a small `ui/onboarding.gd` holds the step, the seven captions and the rigged dice; `main._opening_card()` is skipped in game one; offers gated on step 3. No `core/` change: rigging reuses the tutorial's dice hook in `ui/`.
