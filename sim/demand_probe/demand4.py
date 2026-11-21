"""Does the demand ask a real question? Best play against two players who ignore it except to break ties:
  greedy+: keeps the die that scores best in poker now, ties to what the Sin pays now, then the face it has most of,
           then the higher; draws 3 with no skulls, 2 with one, 1 with two.
  poker+:  plays the no-Sin game exactly right, and breaks its exact ties toward what the Sin pays now.
Both are scored with the Sin paying. gap = (best - player) / player. With no Sin, best beats greedy by 11%.
A demand is any function of the finished row; python -I demand4.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from functools import lru_cache
from collections import Counter
from demand import PAY, classify, BAG, ROW, BUST, MAXD
from itertools import product


class Game:
    def __init__(self, name, bonus=None):
        self.name, self.bonus = name, bonus or (lambda row: 0)
        self.value = lru_cache(maxsize=None)(self._value)
        self.throw_value = lru_cache(maxsize=None)(self._throw_value)

    def split(self, row):
        """(total, poker, sin) of a row; a wild takes the face that pays most in all, ties to the better hand."""
        if 0 in row:
            r = [f for f in row if f != 0]
            return max((self.split(tuple(sorted(r + [f]))) for f in range(2, 7)), key=lambda t: (t[0], t[1]))
        p, b = PAY[classify(row)], self.bonus(row)
        return (max(0, p + b), p, b)

    def now(self, row):
        """What the Sin pays for the row as it stands (for tie-breaks)."""
        return self.bonus(tuple(f for f in row if f != 0))

    def _value(self, row, skulls, bag):
        if len(row) >= ROW or bag == 0:
            return float(self.split(row)[0])
        return max(self.throw_value(row, skulls, bag, n) for n in range(1, min(MAXD, bag) + 1))

    def outcomes(self, row, skulls, bag, n):
        dance = bag == 1
        p = 1.0 / 6 ** n
        for faces in product(range(1, 7), repeat=n):
            k = faces.count(1)
            pips = sorted(set(f for f in faces if f != 1))
            sk = skulls + k
            if sk >= BUST or (dance and k > 0):
                continue
            if dance:
                yield p, [(0, (tuple(sorted(row + (0,))), sk, 0))]
            elif not pips:
                yield p, [(None, (row, sk, bag - n))]
            else:
                yield p, [(f, (tuple(sorted(row + (f,))), sk, bag - k - 1)) for f in pips]

    def _throw_value(self, row, skulls, bag, n):
        return sum(p * max(self.value(*st) for _, st in opts) for p, opts in self.outcomes(row, skulls, bag, n))

    def best_draw(self, row, skulls, bag):
        opts = list(range(1, min(MAXD, bag) + 1))
        vals = [self.throw_value(row, skulls, bag, n) for n in opts]
        return opts[max(i for i, v in enumerate(vals) if v > max(vals) - 1e-9)]

    def play(self, draw, keep):
        """Exact expected (total, poker, sin, bust) of a fixed player in this game."""
        @lru_cache(maxsize=None)
        def ev(row, skulls, bag):
            if len(row) >= ROW or bag == 0:
                t = self.split(row)
                return (float(t[0]), float(t[1]), float(t[2]), 0.0)
            n = draw(row, skulls, bag)
            out = [0.0, 0.0, 0.0, 0.0]
            mass = 0.0
            for p, opts in self.outcomes(row, skulls, bag, n):
                st = opts[0][1] if len(opts) == 1 else keep(row, skulls, bag, opts)
                r = ev(*st)
                mass += p
                for i in range(4):
                    out[i] += p * r[i]
            out[3] += 1.0 - mass
            return tuple(out)
        return ev((), 0, BAG)


def players(g, plain):
    def greedy_draw(row, skulls, bag):
        return min(max(BUST - skulls, 1), MAXD, bag)

    def greedy_keep(row, skulls, bag, opts):
        def key(o):
            f, st = o
            r = st[0]
            return (PAY[classify(r)], g.now(r), r.count(f), f)
        return max(opts, key=key)[1]

    def poker_draw(row, skulls, bag):
        return plain.best_draw(row, skulls, bag)

    def poker_keep(row, skulls, bag, opts):
        return max(opts, key=lambda o: (round(plain.value(*o[1]), 9), g.now(o[1][0]), o[0]))[1]

    def best_keep(row, skulls, bag, opts):
        return max(opts, key=lambda o: g.value(*o[1]))[1]

    return {"greedy+": (greedy_draw, greedy_keep), "poker+": (poker_draw, poker_keep),
            "best": (lambda r, s, b: g.best_draw(r, s, b), best_keep)}


def faces(table):
    return lambda row: sum(table.get(f, 0) for f in row)

def singles(m):          # each face you hold exactly once
    return lambda row: m * sum(1 for c in Counter(row).values() if c == 1)

def odd_one(m):          # each die that is not part of your biggest set
    return lambda row: m * (len(row) - max(Counter(row).values())) if row else 0

def lone(face, m):       # the Sin's face pays only while it stands alone
    return lambda row: m if row.count(face) == 1 else 0

def lone_or_cost(face, m, c):   # a lone one pays; every one after the first costs
    return lambda row: (m - c * (row.count(face) - 1)) if row.count(face) >= 1 else 0

def spread(m):           # pays the gap between your highest and lowest die
    return lambda row: m * (max(row) - min(row)) if row else 0

def no_face(face, m):    # pays if you finish without the face
    return lambda row: m if len(row) == ROW and face not in row else 0

def pair_tax(m):         # each die beyond the first of a face costs
    return lambda row: -m * sum(c - 1 for c in Counter(row).values())


if __name__ == "__main__":
    plain = Game("no Sin")
    games = [
        plain,
        Game("Pride: 6 +2, 5 +1", faces({6: 2, 5: 1})),
        Game("Envy: 6 +1, 2 -1", faces({6: 1, 2: -1})),
        Game("each face held once +1", singles(1)),
        Game("each face held once +2", singles(2)),
        Game("each die outside your biggest set +1", odd_one(1)),
        Game("each die outside your biggest set +2", odd_one(2)),
        Game("a lone 6 pays +3", lone(6, 3)),
        Game("a lone 6 pays +4", lone(6, 4)),
        Game("first 6 +3, each more -2", lone_or_cost(6, 3, 2)),
        Game("gap high-low x1", spread(1)),
        Game("no 6 in a full row +3", no_face(6, 3)),
        Game("each repeat of a face -1", pair_tax(1)),
        Game("6 +2, each repeat of a face -1", lambda row: faces({6: 2})(row) + pair_tax(1)(row)),
    ]
    print("%-38s %6s %6s %6s %6s | %-16s %-16s" % ("demand", "best", "poker", "sin", "bust", "over greedy+", "over poker+"))
    for g in games:
        pl = players(g, plain)
        b = g.play(*pl["best"])
        row = "%-38s %6.2f %6.2f %6.2f %5.1f%% |" % (g.name, b[0], b[1], b[2], 100 * b[3])
        for who in ("greedy+", "poker+"):
            r = g.play(*pl[who])
            row += " %5.2f (%+4.0f%%)   " % (r[0], 100 * (b[0] - r[0]) / r[0])
        print(row)
