# Packet: V5 build (REPLY 3)
**Changed:** items 1-13 built, one commit each with a test (`2bd52c9`..`d2a00b4`). UI on the table view: V5 rules, my seal, power beats, the Master's line, first-game bots, Purgatory gone (`1a5d4c8`, `3209a68`, `bde6124`). Fixtures and V5 table play (`45abc16`). Docs: TableSpec, TableDesign §10 (`83897f5`). Sim length option (`70ad084`). All local; nothing pushed.
**Tests:** `bash tests/run_all.sh`: all pass. Includes v5_check (353 checks), lines (393), table_check (1214), replay, ui_autoplay (7 games) and table_play_check: 7 full V5 games through the table, 20 seals pressed and 8 throws let stand. V4 is unchanged; old saves and replays still pass.
**Text audit** (all 20 table fixtures plus offer_scaled, se and max): table fixtures clean. offer_scaled at se: 4 lines at 13.2-13.6 pt (the context line, the Master's announcement, Accept, Refuse). The offer card already uses these sizes; the min is 15 pt.
**Gallery --check:** not run. `tests/golden/` does not exist yet, so there is nothing to compare against.
**Sheet** (se, left to right): power ready (Lust, the seal shows a 6, tap the dice to let it stand) · power spent (Wrath) · my power firing (Lust's ring on the changed die) · a rival's power firing (Greed's Cash Out rings the stake) · Master line · scaled offer (100 x3 = 300, 460 behind) · decision without the jester.
**Core V5** (`sim/v5_sim.gd`, 40k games, 4 seats): every Sin 22.1-28.3. Comebacks 12.4%, 4.3 rounds.
**Item 12:** the tilt stays. With it, 22.3-28.7. Without it, Sloth drops to 21.9, so no Sin is taken outside 22-28.
**Greed vs novices:** 28.9 (Envy 48.6, mean 36.2). Scheduled for the next sim pass.
**Game length** (V5, comebacks counted from half the target):

| Target | Win range | Comebacks | Lead changes | Rounds | Minutes | Skill edge |
|---|---|---|---|---|---|---|
| 1000 | 22.3-28.6 | 12.4% | 3.99 | 4.3 | 1.4 | 29.9 |
| 1500 | 19.6-41.2 | 13.5% | 5.56 | 6.0 | 2.0 | 26.4 |
| 2000 | 17.1-51.5 | 14.7% | 7.02 | 7.8 | 2.6 | 23.4 |

Envy is the high end at 1500 and 2000, because Mimicry is once a round. Bot thresholds were not rescaled for longer games.
**Not finished:** hold to explain (not on the table, as before). The power's tap-to-finish and skip still go through main's queue.
**TestFlight** (main must be pushed first):
```bash
git push origin main
gh workflow run ios.yml --ref main -f table=true
```
**Questions**
1. Game length: keep 1000? Longer games add comebacks and lead changes but lower the skill edge, and Envy runs away. **Rec:** keep 1000.
2. offer_scaled small text at se: raise the offer card's context line and seal words to 15 pt? **Rec:** yes, next UI pass.
3. Push and run TestFlight with the commands above? **Rec:** yes.
