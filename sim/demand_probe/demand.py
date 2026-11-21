"""Exact solver for dice poker (bag 7, draw 1-3, row 5, 3 skulls bust, no cash out) with a Sin's demand.
Demand = bonus marks paid with the hand (nothing on a bust):
  face: {face: marks per die of that face in the row}   skull: marks per skull on the table
  d3 / d1: marks per throw of three dice / of one die (not the Last Dance)
Reports, under exact best play, by exact reach probability (no sampling):
  value, bust, dance, draw mix, share of keeps (>=2 different faces) whose best two are worth the same.
"""
import sys
from functools import lru_cache
from itertools import product

PAY = [0, 1, 2, 3, 5, 5, 7, 12]
BAG, ROW, BUST, MAXD = 7, 5, 3, 3


def classify(row):
    counts = {}
    for f in row:
        counts[f] = counts.get(f, 0) + 1
    c = sorted(counts.values(), reverse=True)
    if not c:
        return 0
    if c[0] >= 5:
        return 7
    if c[0] == 4:
        return 6
    if c[0] == 3 and len(c) > 1 and c[1] == 2:
        return 5
    if len(row) == 5 and len(counts) == 5 and max(row) - min(row) == 4:
        return 4
    if c[0] == 3:
        return 3
    if c[0] == 2 and len(c) > 1 and c[1] == 2:
        return 2
    if c[0] == 2:
        return 1
    return 0


class Game:
    def __init__(self, face=None, skull=0, d3=0, d1=0, name="none"):
        self.face = face or {}
        self.skull, self.d3, self.d1, self.name = skull, d3, d1, name
        self.value = lru_cache(maxsize=None)(self._value)
        self.throw_value = lru_cache(maxsize=None)(self._throw_value)

    def payout(self, row, skulls, bank):
        if 0 in row:
            best = -1
            r = [f for f in row if f != 0]
            for f in range(2, 7):
                best = max(best, self.payout(tuple(sorted(r + [f])), skulls, bank))
            return best
        return PAY[classify(row)] + sum(self.face.get(f, 0) for f in row) + self.skull * skulls + bank

    def _value(self, row, skulls, bag, bank):
        if len(row) >= ROW or bag == 0:
            return float(self.payout(row, skulls, bank))
        return max(self.throw_value(row, skulls, bag, bank, n) for n in range(1, min(MAXD, bag) + 1))

    def gain(self, n, dance):
        if dance:
            return 0
        return self.d3 if n == 3 else (self.d1 if n == 1 else 0)

    def outcomes(self, row, skulls, bag, bank, n):
        """Yields (prob, kind, data): kind 'bust' | 'state' (next state) | 'keep' (list of (face, next state))."""
        dance = bag == 1
        b2 = bank + self.gain(n, dance)
        p = 1.0 / 6 ** n
        for faces in product(range(1, 7), repeat=n):
            k = sum(1 for f in faces if f == 1)
            pips = [f for f in faces if f != 1]
            sk = skulls + k
            if sk >= BUST or (dance and k > 0):
                yield p, "bust", None
            elif dance:
                yield p, "state", (tuple(sorted(row + (0,))), sk, 0, b2)
            elif not pips:
                yield p, "state", (row, sk, bag - n, b2)
            else:
                opts = [(f, (tuple(sorted(row + (f,))), sk, bag - k - 1, b2)) for f in sorted(set(pips))]
                yield p, "keep", opts

    def _throw_value(self, row, skulls, bag, bank, n):
        total = 0.0
        for p, kind, data in self.outcomes(row, skulls, bag, bank, n):
            if kind == "state":
                total += p * self.value(*data)
            elif kind == "keep":
                total += p * max(self.value(*st) for _, st in data)
        return total

    def report(self):
        stats = {"bust": 0.0, "dance": 0.0, "draw": [0.0] * 4, "keeps": 0.0, "ties": 0.0, "near": 0.0, "costly": 0.0,
                 "throws": 0.0, "drawtie": 0.0, "by_skull": {0: [0.0] * 4, 1: [0.0] * 4, 2: [0.0] * 4},
                 "tie_sinface": 0.0}
        reach = {((), 0, BAG, 0): 1.0}
        # states only move forward (bag strictly falls), so process by bag size descending
        for bag in range(BAG, 0, -1):
            layer = {s: w for s, w in reach.items() if s[2] == bag and len(s[0]) < ROW}
            for s, w in layer.items():
                row, skulls, _, bank = s
                opts = list(range(1, min(MAXD, bag) + 1))
                vals = [self.throw_value(row, skulls, bag, bank, n) for n in opts]
                best = max(vals)
                n = opts[max(i for i, v in enumerate(vals) if v > best - 1e-9)]  # ties: the bigger draw
                stats["throws"] += w
                if bag > 1:
                    stats["draw"][n] += w
                    stats["by_skull"][skulls][n] += w
                    sv = sorted(vals)
                    if len(sv) > 1 and sv[-1] - sv[-2] < 0.05:
                        stats["drawtie"] += w
                else:
                    stats["dance"] += w
                for p, kind, data in self.outcomes(row, skulls, bag, bank, n):
                    if kind == "bust":
                        stats["bust"] += w * p
                        continue
                    if kind == "state":
                        reach[data] = reach.get(data, 0.0) + w * p
                        continue
                    scored = sorted(((self.value(*st), f, st) for f, st in data), reverse=True)
                    if len(scored) > 1:
                        d = scored[0][0] - scored[1][0]
                        stats["keeps"] += w * p
                        if d < 1e-9:
                            stats["ties"] += w * p
                        elif d < 0.5:
                            stats["near"] += w * p
                        if d >= 0.25:
                            stats["costly"] += w * p
                    st = scored[0][2]
                    reach[st] = reach.get(st, 0.0) + w * p
        v = self.value((), 0, BAG, 0)
        base = sum(stats["draw"])
        k = max(stats["keeps"], 1e-12)
        mix = " ".join("%d:%2.0f%%" % (i, 100 * stats["draw"][i] / base) for i in (1, 2, 3))
        bs = []
        for sk in (0, 1, 2):
            t = sum(stats["by_skull"][sk]) or 1
            bs.append("%dsk[%s]" % (sk, "/".join("%.0f" % (100 * stats["by_skull"][sk][i] / t) for i in (1, 2, 3))))
        print("%-26s value %.3f  bust %4.1f%%  dance %4.1f%%  draws %s  %s" % (
            self.name, v, 100 * stats["bust"], 100 * stats["dance"], mix, " ".join(bs)))
        print("%-26s keeps/hand %.2f  same-worth %4.1f%%  within 0.5 %4.1f%%  wrong costs>=0.25 %4.1f%%  draw choice within 0.05: %4.1f%% of throws" % (
            "", stats["keeps"], 100 * stats["ties"] / k, 100 * stats["near"] / k, 100 * stats["costly"] / k,
            100 * stats["drawtie"] / max(base, 1e-12)))
        return v


if __name__ == "__main__":
    games = [
        Game(name="no Sin (0.11.2)"),
        Game(face={6: 1}, name="face 6 +1"),
        Game(face={2: 1}, name="face 2 +1"),
        Game(face={6: 2}, name="face 6 +2"),
        Game(face={6: 2, 5: 1}, name="6 +2, 5 +1"),
        Game(face={2: 1, 3: 2, 4: 3, 5: 4, 6: 5}, name="pips ladder 2..6 +1..+5"),
        Game(skull=1, name="skull +1"),
        Game(skull=2, name="skull +2"),
        Game(skull=3, name="skull +3"),
        Game(d3=1, name="three-dice throw +1"),
        Game(d3=2, name="three-dice throw +2"),
        Game(d1=1, name="one-die throw +1"),
        Game(d1=2, name="one-die throw +2"),
        Game(d1=3, name="one-die throw +3"),
    ]
    for g in games:
        g.report()
