# Packet: REPLY 11 (buy ghosts, Master's line, post number, bots under the call; pushed)
**Built and pushed:** b779693 run_all fails a test on any FAILED line · 2c9478d buy ghost shows only while its button is held, no tie lines; the Master's line is centred above the dice band with a bone edge; the post's "600" is bone on ink · 5169ee6 under the call the Master's {win} reads the called target · 0afd5c9 under the call, bots drop the 1000 bank-to-win; behind in the penultimate round they chase half the gap; progress counts rounds left. TestFlight build 116 (run 43912590756) started from main.
**Suite:** all 10 pass. **Text audit (std):** every table fixture is clean. The Master's line needed its bone edge to pass under a seat's cone of light (it was 3.9:1).
**Sheet:** before and after, left to right: table_buy, table_buy_press, table_master_call, table_master_final. Full-size after shots are in this folder (plus table_buy_many and table_master).
**Seen in the shots:** the "Buy none" press shows no ghost, by design (it leaves me where I am). Under the call, the Master's line sits below the "600", clear of the candles and the skeleton.
**Profile sim** (seed 1, 20000 mixed; odd seats 4000 each):

| | 1000, no call (REPLY 10) | call at 600, new bots |
|---|---|---|
| Sin range | 21.2-31.5 | 19.3-33.1 |
| Envy / Greed overall | 31.5 / 25.1 | 33.1 / 32.1 |
| Envy+Banker | 39.8 | 40.6 |
| Greed+Banker | under 31.6 (not in the top six) | 41.5 |
| Last seat entering the final round wins | 6.8% (559 behind) | 3.9% (769 behind) |
| Rounds / final margin | 4.53 / 407 | 5.03 / 351 |
| Comebacks (last at half wins) | 13.0% | 18.0% |
| Odd seat: Novice / Banker / Forgetter | 18.4 / 18.8 / 11.4 | 19.5 / 22.6 / 12.2 |

Note: the base table was run with REPLY 10's bots, but nothing changed for games without the call.

**Questions**
1. Greed rises to 32% under the call (Greed+Banker 41.5), because banking steadily pays when the end is called. Should I sim Greed's Cash Out at x1.25 under the call (sim only)? Rec: yes.
2. The last seat wins 3.9% from the final round: the gap at the call (769) is too big for one turn. Rec: accept it for the prototype and judge it in play.
3. The "{win}. I'm genuinely impressed." line now says "600", even when the winner is far past it. Use the winner's score instead? Rec: yes.
