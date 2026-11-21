import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from demand import Game, PAY, classify, BAG, ROW, MAXD
from demand2 import G2

def split(g):
    """Expected poker marks and demand marks under best play (exact)."""
    reach = {((), 0, BAG, 0): 1.0}
    poker = total = 0.0
    hands = [0.0] * 8
    for bag in range(BAG, -1, -1):
        for s, w in [(s, w) for s, w in reach.items() if s[2] == bag]:
            row, skulls, _, bank = s
            if len(row) >= ROW or bag == 0:
                best = None
                rows = [row] if 0 not in row else [tuple(sorted([f for f in row if f] + [x])) for x in range(2, 7)]
                for r in rows:
                    p = g.payout(r, skulls, bank)
                    if best is None or p > best[0]:
                        best = (p, PAY[classify(r)], classify(r))
                total += w * best[0]; poker += w * best[1]; hands[best[2]] += w
                continue
            opts = list(range(1, min(MAXD, bag) + 1))
            vals = [g.throw_value(row, skulls, bag, bank, n) for n in opts]
            n = opts[max(i for i, v in enumerate(vals) if v > max(vals) - 1e-9)]
            for p, kind, data in g.outcomes(row, skulls, bag, bank, n):
                if kind == "bust": continue
                st = data if kind == "state" else max(((g.value(*x), x) for _, x in data))[1]
                reach[st] = reach.get(st, 0.0) + w * p
    print("%-28s total %.2f  poker %.2f  demand %.2f  straight %.1f%% full+ %.1f%% pair-or-less %.1f%%" % (
        g.name, total, poker, total - poker, 100*hands[4], 100*sum(hands[5:]), 100*(hands[0]+hands[1])))

for g in [Game(name="no Sin"), Game(face={6:2,5:1}, name="Pride 6+2 5+1"), Game(face={6:1,5:1}, name="6,5 +1"),
          Game(face={6:1,2:-1}, name="Envy 6+1 2-1"), Game(face={4:2,3:1,5:1}, name="middle 4+2 3,5+1"),
          G2(danger=1, at=2, name="Wrath die at 2 skulls +1")]:
    split(g)
