# Packet: REPLY 18 (round floor at 550)
**Local only, not pushed** (it ships with the next push, after you've played 118). Layout is not locked.
- **Rule:** the Master calls the end no earlier than round 3's end (`Rules.MASTER_CALL_FLOOR` 3, game opt `call_floor`). Round 5 is the earliest last round. The call stays at 550. The table passes it in `ui/main.gd` `table_rules()`. TableDesign has a "Decided (REPLY 18)" line.
- **Test:** `v5_check` plays 12 seeded games with the floor and 12 without. With it, every call comes at round 3's end or later and every game lasts 5+ rounds. Without it, some calls come earlier, so the floor binds. Suite: all pass (v5_check 376).
- **Parked:** "Grammar and voice pass" is in `Docs/UXPlan.md` (table row and section). It covers every line, the Master's first, and each Master line must fit on one line beside his arm.
- **Not changed:** the hood may rise above the SE safe line (Q4 no). The mark's plate keeps crossing his arm (Q3).
- **Visuals:** none changed, so there's no sheet. The text audit is unchanged from REPLY 17 (32/32 clean at se and std).

**Sim** (20000 mixed, as built: 550, floor 3, Idle-one, Hubris x2, Devour +45; from REPLY 17's run with the same rule):
| Sin range | over 6 rounds | 4 or fewer | round 5 / 6 / 7+ | last seat wins |
|---|---|---|---|---|
| 20.4-27.8 | 9.5% | 0% | 62.9% / 27.6% / 9.5% | 5.9% |

**What I see:** a leader can now pass the 550 post in rounds 1-2 and the Master says nothing. Nothing on the table shows that the post isn't live yet.

**Questions**
1. Should the 550 post show it isn't live before round 3 (dim, then lit when it can fire)? Rec: yes. Dim it, and light it at round 3's end. No new words.
2. When a leader is already past 550 at round 3's end, should his call line still say "550 reached"? Rec: yes. It's still true, and the line stays short.
