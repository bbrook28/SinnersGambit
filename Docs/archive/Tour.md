# Sinners' Gambit: a tour of the game (2026-11-14, after Phase 6)

The written version of the tour video (`build/SinnersGambit_tour.mp4`, 5 min 43 s, recorded by `tools/tour.gd`; see the end). It follows the video in order: title page, Settings, rulebook, the tutorial, Sin select, then a full game as Envy at a table of 4, through to the win. Each section covers what you see (visuals), what moves (VFX and animation), what you can do (UX) and what you hear (audio). Stills are in `Docs/tour/`.

What isn't built yet is marked **(later: Phase N)**, from `Docs/UXPlan.md`.

---

## The look in one paragraph
A gothic illuminated manuscript lit by one candle, with stained glass. The board is a dark painted desk with a candle at the right. The seven Sins are painted lancet windows. Prompts are blackletter lettering inked onto parchment with a crimson capital and a red pen flourish. Buttons are red wax seals with gold-leaf numerals, and numbers are gold-leaf Cinzel. The dice are painted ivory with inked pips; the Strike faces (1 and 2) are inked red. Every sound plays in a dark stone nave: bells for outcomes, wax for commitments, parchment for movement, bone for dice. No casino sounds.

---

## 1. Title page
![Title](tour/menu.jpg)

- **Visuals:** a dark far wall with the seven windows in a centred row, each casting a shaft of its own colour onto the desk. The painted candle stands at the right with a flickering pool of light. Below are the title in gold lettering with a crimson capital, the tagline "Choose your Sin, push your luck, and be the first to 1000.", and three seals: Play (big), Rulebook and Settings. Continue appears only when there's a saved game.
- **VFX:** each window's glass is lit from behind by slow cloud light, with a pale sheen sweeping across it now and then. Each window has a breathing halo and rim glow. Coloured dust motes drift inside the shafts, the light pools breathe where the shafts land, and the title breathes slowly. The seals enter one by one, springing up, then breathe. A specular glint travels along the wax.
- **UX:** Play opens the Sin choice under an ink wash. On the very first launch, Play starts the tutorial instead. Seals squash on press and spring back with a small rock on release.
- **Audio:** "Cathedral" (CC0 organ music), looping from launch; a wax press on each seal.

## 2. Settings
![Settings](tour/settings.jpg)

- A parchment page that fades and scales in from the centre: Music and Sound sliders, then segmented controls for Haptics, Speed (1x / 2x / 4x) and Reduce Motion, and Tutorial (Play). Back is a seal.
- Reduce Motion turns off shake, tilt, idle breathing, candle flicker and the marginalia figures' reactions.

## 3. Rulebook
![Contents](tour/rulebook_contents.jpg) ![Scoring](tour/rulebook_scoring.jpg) ![Strikes](tour/rulebook_strikes.jpg)
![Purgatory](tour/rulebook_purgatory.jpg) ![Sins](tour/rulebook_all_sins.jpg) ![Glossary](tour/rulebook_glossary.jpg)

- Twelve parchment pages, illustrated with the game's own art (dice, candles, seals, windows):
  - Contents: the rules in five sentences, plus page buttons
  - Goal, Your Turn, Scoring (with a worked example), Strikes and Busting, Banking, Purgatory, Buying Dice
  - Sins and Greater Abilities, Winning, The Seven Sins (each window with both abilities), Glossary
- **UX:** swipe or use Previous / Next; Contents and Close are always there. It opens from the menu, from the pause menu (at the page that fits the moment), and from any explain card. All wording lives in `ui/rules_text.gd`, with numbers filled in from the rules, so balance changes flow through.

## 4. Tutorial (a practice game against Sloth)
![Welcome](tour/tutorial_00.jpg) ![Throw](tour/tutorial_01_act.jpg) ![Scored](tour/tutorial_02.jpg)
![Strike](tour/tutorial_04.jpg) ![Bank](tour/tutorial_05_act.jpg) ![Buy](tour/tutorial_06_act.jpg)
![Bot turn](tour/tutorial_07.jpg) ![Your Sin](tour/tutorial_09_act.jpg) ![Glance](tour/tutorial_10.jpg)
![Bust](tour/tutorial_12.jpg) ![Purgatory](tour/tutorial_14.jpg) ![End](tour/tutorial_end.jpg)

- **What it is:** a scripted 15-step game, you as Envy against a Sloth bot, with rigged dice so you see every rule once: throwing, scoring and the multiplier, a Strike, banking, buying a die, a bot's turn, your Sin's Basic ability (Green-Eyed Glance adds a copy of the previous player's best die), risk, a bust, and Purgatory.
- **Visuals:** the real board, dimmed, with a soft spotlight cut round whatever matters. One line per step sits on a dark card. Skip stays in the top corner the whole time.
- **UX:** read steps advance on a tap. Act steps light exactly one live button (Throw, Bank, Buy, Yes) inside the spotlight. It ends with Play / Menu, and you can replay it from Settings > Tutorial.

## 5. Choose thy Sin
![Sloth](tour/select_sloth.jpg) ![Wrath](tour/select_wrath.jpg) ![Envy](tour/select_envy.jpg)

- **Visuals:** one Sin per page: the lit lancet window, "Name, the Epithet" in its colour, a one-line playstyle, then the Basic ability (and the Greater one outside your first game) with the ability names in gold. Sloth opens first and wears a crimson "Recommended" ribbon. Below are seven page dots in the Sin colours, the table-size control (Table of 4 / Table of 7), and the Choose seal.
- **VFX:** a soft glow in the Sin's colour behind the window cross-fades as the page turns, and breathes.
- **UX:** swipe (it follows your finger, rubber-bands at the ends, and turns on a third of the width or a flick) or tap a dot. Tapping the window doesn't start a game, so a swipe can't choose by accident. Choose starts the game under the ink wash.
- **Audio:** each Sin has its own sting in its own key when its page settles. Examples: Wrath, one hard low strike; Envy, two bells a minor second apart; Gluttony, a heavy low organ chord. A new sting fades the last one out.

## 6. The board
![Your throw](tour/prompt_throw.jpg)

Three zones, top to bottom (`Tuning.ZONE_*` 21 / 49 / 30 since Phase 6):
1. **Windows and plates:** one cropped window per seat (arch and figure) over a brass plate with Score and Dice. The current Sin's window glows. Your column has a gold frame, a wash of your Sin's colour behind it, and "You" in gold. A gold crown sits over the leader. Status badges stack down a window's right edge: a Purgatory flame, a Greater-ready star, a Dragged chevron, Pact rings. A Sin's name turns red in Purgatory.
2. **The tray** (leather in a carved frame), about 44% of the screen:
   - top: the turn lettering ("Your turn", "Greed's turn") with the pause seal at its right
   - the dice, in one fixed size and rows of six
   - the **score strip**: the throw total over a one-line result
   - "This turn N" and three Strike candles
3. **The parchment page** (with marginalia: a jester, a pennant, a skeleton, a die): on your turn, the prompt lettering and the seals. On a bot's turn, its "is thinking..." line, the bot-turn summary and Skip to my turn.

- **Always on:** the page's candle pool slides with the phone's tilt (on desktop, a slow drift) and flickers. Seals breathe, and the selected count seal's gold ring pulses.
- **Input:** tap during a beat to finish it, tap again to skip to your next decision, hold anything to explain it. Your buttons appear only once every queued beat has played.

## 7. A turn, beat by beat
Every event is a queued beat: anticipation, action, impact, hold. The board only ever shows the state as of the last beat played. Bots run the same beats about 2.25 times faster, with no anticipation and short holds (about 4 s per bot turn).

**Turn change:** a full-width band sweeps across in the new Sin's colour and holds a moment longer when it's yours. The old window dims and the new one lights.

**Throw:** the tray draws breath (a small lift and a dice shake). Then the dice tumble in from the thrower's side, one after another. Each drops from above, bounces twice with its shadow left on the leather (fainter and wider while it's in the air), lands with a squash and a puff of dust, and rocks once. The tray shakes and you feel a tap, both scaled to the number of dice. Scoring dice (4-6) sit raised and candle-lit; 3s and Strikes sit sunk and darker.

**Strikes:** each 1 or 2 flashes red, an ember flies to the next lit candle and snuffs it, and a wisp of smoke rises with an iron nail sound. The third adds a small toll.

**Score** (on your turn):
![Throw total](tour/score_total.jpg) ![Multiplier](tour/score_multiplier.jpg)
- The scoring dice lift and glow, then each die's "+N" flies into the score strip, which counts up as they land. It never shows "+0".
- With several scorers, the multiplier joins the same line as one fixed number ("+45  x1.5"), then the total snaps to the product. The line shrinks to fit the strip.
- Gold sparks burst and the page shakes, scaled to the size of the score. The total then flies down to "This turn", which punches and counts up.
- The result line under the total says it in words ("4, 5 and 6 score 15, x1.5 = 22. One Strike.").
- On a bot's turn, one flight goes straight from the dice to "This turn".

**Throw again or bank:**
![Throw or Bank](tour/prompt_throw_or_bank.jpg)
- Bank is a bronze seal on the left with its amount; Throw is the crimson seal under your right thumb with the stained-glass hand. Both keep a fixed size. The prompt inks in left to right with a wet edge.
- **Bank:** the turn total streaks to your plate, which counts up. Two bells ring a fifth apart, the skeleton in the corner hops and the pennant waves.

**Bust:**
![Bust](tour/bust.jpg)
- All three candles glow and "This turn" drains to 0 as the result reads "Third Strike: bust. This turn's points are lost."
- Then a red flash, BUST stamped on the tray's top edge (not over the dice), a heavy shake, one low bell toll under a glass crack, and the jester flinching.
- You start your next turn in Purgatory: a free throw where any 6 frees you, "Free!" or "Still in Purgatory" stamped on the tray edge; otherwise you pay 50.

**Buy dice** (after you bank):
![Buy](tour/prompt_buy.jpg)
- Plaques for each offer ("Buy none", "Buy 1 (100)"). The price leaves your plate and flies away while the score counts down, then new dice drop onto the Dice count with a die-on-wood sound.

**Abilities:**
![Ability prompt](tour/prompt_ability.jpg) ![Ability note](tour/ability_note.jpg) ![Added dice](tour/added_dice_tinted.jpg)
- You're asked when an ability is legal ("Green-Eyed Glance? Add a 5 to this throw (once a turn)." Yes / No).
- When any Sin acts, its window lifts, flares white-hot and settles, with a glass chime. Its note takes the score strip for that beat: the ability name in the Sin's colour, then what it did. Whatever it changed then flies to where it belongs: plate scores, the turn total, the dice.
- Envy's added dice are drawn as real dice, washed green with a rim, thrown in from Envy's window. Lust's swaps and Gluttony's feasts change the dice on the leather before the throw scores.
- Attacks (Fury, Pact, Drag) send a streak window to window, and Pride's Untouchable bounces it back.

## 8. Bot turns
![Bot turn summary](tour/bot_summary.jpg)

- The page shows "Greed is thinking..." with growing dots and the window breathes. Then the turn plays at bot pace.
- The bot-turn summary lists one line per bot turn since yours, each in that Sin's colour: "Greed: banked 155 (now 260)", "Pride: Hubris, went bust, lost 90". At most six lines; older ones drop off. Tap it for the Chronicle.
- Skip to my turn (the same as a double tap) fast-forwards with all sound silenced.

## 9. Pause menu, explain cards, Chronicle
![Pause](tour/pause_menu.jpg) ![Explain](tour/explain_your_sin.jpg) ![Chronicle](tour/chronicle.jpg)

- **Pause** (the seal in the tray): Resume, Rulebook (at the page for the moment), Sin abilities (only this table's Sins), Chronicle, Settings, Main menu. The game waits underneath.
- **Explain:** tap a window when nothing is playing, or hold anything at any time. A card opens with that Sin's playstyle, both abilities (with Greater state), status, score and dice, plus a link to its rulebook page. It works the same for scores, dice counts, Strikes, This turn, the throw total and the tray.
- **Chronicle:** the whole game, turn by turn, in plain words with each Sin's sigil before its name. Main menu and Close sit at the foot. The game saves after every answer, so Continue resumes it exactly.

## 10. The win
![Game over](tour/game_over_prompt.jpg) ![Win](tour/win.jpg)

- The winner's window flares, the plate glows gold and the rest dim. "You win" (or "Wrath wins") is lettered in the tray, and a minor organ chord swells under a bell. The page reads "The game is done. You reached 1203." with a New game seal, which opens the Sin choice under the ink.
- **(later: Phase 10)** a staged finale sequence instead of this.

---

## Not in the game yet
- **Phase 7 (Controls):** a Throw N stepper with bust chance, a Buy stepper (replacing the buy pills, which overflow at 7+), ability consequence text, and the 12-dice gaps.
- **Phase 8 (Mechanics):** multiplier and die price, the Wrath and Greed caps, multiples of 5, final round, balance (Envy too strong with Greater; Greed and Gluttony weak).
- **Phase 9 (Polish):** a serif for body text with blackletter for titles only; painted turn banners in each Sin's glass colour (now a flat band); no silent screens and an audio limiter; windows take their seats after Choose; the app icon.
- **Phase 10 (VFX spectacle):** full-screen Sin ability effects, score tiers (sparks, illumination burst, slow-motion hold), the page burning into Purgatory on a bust, a staged win and lose, and tension building with the multiplier.

## How the video was made
`tools/tour.gd` drives the real game with Godot's Movie Maker at 30 fps (720x1560 through a temporary `override.cfg`, since the project's window override is 540x960). The player throws, says yes to every ability, banks at 150 or on two Strikes, and takes the first buy offer. The game itself is unrigged, so a new recording plays a different game. ffmpeg (already installed) encodes it to H.264 MP4 with the game's own audio.

```bash
godot --path . --fixed-fps 30 --write-movie build/tour/tour.avi --script res://tools/tour.gd -- build/tour   # with override.cfg setting the window to 720x1560
```
