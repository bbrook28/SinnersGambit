import sys
import os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from collections import Counter
from demand4 import Game, faces, singles, lone
from demand5 import study, mix_text
def hi_lone(row):
    l = [f for f, c in Counter(row).items() if c == 1]
    return max(0, max(l) - 3) if l else 0
def lone_cost(row): return (4 if row.count(6) == 1 else 0) - row.count(2)
def singles_cost(row): return sum(1 for c in Counter(row).values() if c == 1) - row.count(2)
def singles_hi(row): return sum(1 for f, c in Counter(row).items() if c == 1 and f >= 4)
def singles_hi2(row): return 2 * sum(1 for f, c in Counter(row).items() if c == 1 and f >= 5)
def lone_each(row): return sum({6: 3, 5: 2, 4: 1}.get(f, 0) for f, c in Counter(row).items() if c == 1)
def pairs_cost(row): return sum(1 for c in Counter(row).values() if c == 1) - sum(1 for c in Counter(row).values() if c >= 2)
plain = Game("no Sin")
gs = [Game("highest lone die pays face-3", hi_lone), Game("lone 6 pays 4, each 2 costs 1", lone_cost),
      Game("held once pays 1, each 2 costs 1", singles_cost), Game("lone 4,5,6 pay 1 each", singles_hi),
      Game("lone 5,6 pay 2 each", singles_hi2), Game("lone 6 +3, lone 5 +2, lone 4 +1", lone_each),
      Game("held once +1, each set -1", pairs_cost)]
for g in gs:
    b, gaps, st = study(g, plain)
    h = st["hands"]
    print("%-34s best %.2f hand %.2f Sin %.2f bust %4.1f%% g+ %+3.0f%% p+ %+3.0f%% | keeps %.2f costly %.2f  0/1/2+ %2.0f/%2.0f/%2.0f draws %.2f" % (
        g.name, b[0], b[1], b[2], 100*b[3], 100*(b[0]-gaps["greedy+"])/gaps["greedy+"], 100*(b[0]-gaps["poker+"])/gaps["poker+"],
        st["keeps"], st["costly"], 100*h[0], 100*h[1], 100*h[2], st["draw_changed"]))
    print("    " + mix_text(st))
