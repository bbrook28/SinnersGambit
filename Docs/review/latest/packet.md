# Packet: REPLY 15 (new rules built, the Master behind the windows, pushed)
**Built and pushed** (main 2d85ff5; TestFlight run 17 = build 117, internal only):
- `Rules.V5`: chain capped at x2; a bust keeps half the turn's face points (to 5); Cash Out x1.25; the Master marks each round's strict leader: no chain for them that round. His mark line (new pools, 5 lines each) and mark pose play live, and a gold ring stays on the marked window all round. Save version 5. TableDesign §10 records it. v5_check adds 11 checks, including whole games where he marks the right seat.
- The Master stands behind the window row: hood and mask in a 130 px band above it, plum robe to both screen edges behind the windows. The offer card rests just above its window, scaled to it. `table_end`: the post's 600 now sits beside the post, clear of my 640.
- Suite: all pass. Text audit: 32/32 clean at se and std. Fixture changed: `table_master_mark` (now marked).

**Sheet** (std): before (REPLY 13 build), rest, mark, offer, calling, table_end. `sheet_se.png`: rest, mark, offer, calling at SE.
**What I see:** at std the active window is smaller than in the REPLY 13 build (the hood band takes 130 px from the wall), but larger than in REPLY 14. At SE the wall is short, so the windows are small and the robe is a thin strip. The offer card to Greed sits close to my window's top-right corner.

**Sim** (20000 mixed, new baseline = the build's rules, call at 600 unless noted):
| run | Sin range | Gluttony | Sloth | rounds (over 6) | last seat wins |
|---|---|---|---|---|---|
| baseline | 18.9-32.0 | 32.0 | 18.9 | 5.57 (16.7%) | 5.7% |
| Devour +45 (from 60) | 19.5-28.9 | 27.8 | 19.5 | 5.61 (18.1%) | 5.9% |
| Devour +30 | 19.7-29.4 | 24.4 | 19.7 | 5.65 (19.2%) | 5.8% |
| Drag 6 (from 4) | 18.9-32.0 | 32.0 | 18.9 | 5.57 (16.7%) | 5.8% |
| Idle turns Strikes to 4s (from 3s) | 17.9-34.1 | 29.0 | 34.1 | 5.45 (13.1%) | 5.8% |
| call at 550 | 19.1-31.8 | 31.8 | 19.1 | 5.32 (11.2%) | 5.8% |
| call at 500 | 19.4-31.7 | 31.7 | 19.4 | 5.06 (6.8%) | 5.9% |
| **call at 500 + Devour +45** | **19.7-30.2** | 28.1 | 19.7 | **5.10 (7.5%)** | 6.2% |

**What it says:** Devour +45 fixes Gluttony. The call at 500 is the only lever that brings games past 6 rounds under 10%; 550 lands at 11%. Drag doesn't touch Sloth, and Idle to 4s overshoots. Sloth and Pride (about 20) stay low, and Greed (30) is now the top Sin.

**Questions**
1. Build the call at 500 and Devour +45? Rec: yes. It is the only pair here that meets your 10% bar with the narrowest range.
2. Sloth: should I sim Idle turning one Strike to a 4 (the rest to 3s)? Rec: yes. Both ends of the knob are measured; the middle is untried.
3. At SE the hood band leaves small windows. Should the band shrink on short screens (a quarter of the wall, at most 130 px)? Rec: yes.
4. The table hides during an offer, so the Master's offer pose is still fixture-only. Should the offer show on the table, with the card in his hand, before the card screen opens? Rec: yes, as the offer's anticipation beat.
