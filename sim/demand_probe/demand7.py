"""The hand itself: which change gives more keeps with a choice, and more questions? Exact, like demand5.py.
One engine with the hand's numbers as parameters, so each option is the same game with one thing changed:
  min_draw / max_draw   the fewest and most dice a throw may draw (today 1 and 3)
  bust_at, bag          skulls that bust; dice in the bag
  refuse                you may keep nothing: the pips go back, but one die leaves the bag for good
  keep_bonus(row, face, pips)  a Sin that pays at the keep, into a bank paid with the hand (a Sin on the draw)
  end_bonus(row)        a Sin that pays for the finished row (demand4.py's shapes)
Reports, under best play: marks (hand / Sin), busts, the Last Dance, throws a hand,
  choices: keeps a hand with two or more different things to do (dice of different faces, or refusing)
  costly:  of those, the share where the second-best choice costs a quarter mark or more
  flips:   the share where the best two are worth the same
  asked:   with a Sin, keeps a hand where nothing is best for both the poker alone and the Sin alone,
           and how often the hand's choice wins
  draws:   share of throws at each number of dice, by skulls showing
python -I demand7.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from functools import lru_cache
from itertools import product
from demand import PAY, classify

ROW = 5


class Hand:
    def __init__(self, name, bag=7, min_draw=1, max_draw=3, bust_at=3, refuse=False,
                 end_bonus=None, keep_bonus=None, poker=True):
        self.name, self.bag, self.min_draw, self.max_draw = name, bag, min_draw, max_draw
        self.bust_at, self.refuse, self.poker = bust_at, refuse, poker
        self.end_bonus = end_bonus or (lambda row: 0)
        self.keep_bonus = keep_bonus
        self.value = lru_cache(maxsize=None)(self._value)
        self.throw_value = lru_cache(maxsize=None)(self._throw_value)

    def twin(self, **kw):
        """The same hand with something switched: twin(end_bonus=None, keep_bonus=None) is the hand with no Sin."""
        a = dict(bag=self.bag, min_draw=self.min_draw, max_draw=self.max_draw, bust_at=self.bust_at,
                 refuse=self.refuse, end_bonus=self.end_bonus, keep_bonus=self.keep_bonus, poker=self.poker)
        a.update(kw)
        return Hand(self.name, **a)

    def split(self, row, bank):
        if 0 in row:
            r = [f for f in row if f != 0]
            return max((self.split(tuple(sorted(r + [f])), bank) for f in range(2, 7)), key=lambda t: (t[0], t[1]))
        p = PAY[classify(row)] if self.poker else 0
        b = self.end_bonus(row) + bank
        return ((max(0, p + b) if self.poker else p + b), p, b)

    def draws(self, bag):
        if bag <= 1:
            return [1]
        return list(range(min(self.min_draw, bag), min(self.max_draw, bag) + 1))

    def _value(self, row, skulls, bag, bank):
        if len(row) >= ROW or bag == 0:
            return float(self.split(row, bank)[0])
        return max(self.throw_value(row, skulls, bag, bank, n) for n in self.draws(bag))

    def outcomes(self, row, skulls, bag, bank, n):
        """Yields (prob, [(what, next state)]); what is a face, 0 (the wild), None (nothing to do) or 'refuse'."""
        dance = bag == 1
        p = 1.0 / 6 ** n
        for faces in product(range(1, 7), repeat=n):
            k = faces.count(1)
            pips = sorted(f for f in faces if f != 1)
            sk = skulls + k
            if sk >= self.bust_at or (dance and k > 0):
                continue
            if dance:
                yield p, [(0, (tuple(sorted(row + (0,))), sk, 0, bank))]
            elif not pips:
                yield p, [(None, (row, sk, bag - n, bank))]
            else:
                opts = []
                for f in sorted(set(pips)):
                    b2 = bank + (self.keep_bonus(row, f, pips) if self.keep_bonus else 0)
                    opts.append((f, (tuple(sorted(row + (f,))), sk, bag - k - 1, b2)))
                if self.refuse:
                    opts.append(("refuse", (row, sk, bag - k - 1, bank)))
                yield p, opts

    def _throw_value(self, row, skulls, bag, bank, n):
        return sum(p * max(self.value(*st) for _, st in opts) for p, opts in self.outcomes(row, skulls, bag, bank, n))

    def best_draw(self, row, skulls, bag, bank):
        opts = self.draws(bag)
        vals = [self.throw_value(row, skulls, bag, bank, n) for n in opts]
        return opts[max(i for i, v in enumerate(vals) if v > max(vals) - 1e-9)]


def study(g):
    has_sin = g.keep_bonus is not None or g.end_bonus((2, 3, 4, 5, 6)) != 0 or g.end_bonus((6,)) != 0 or g.end_bonus((2,)) != 0
    plain = g.twin(end_bonus=None, keep_bonus=None) if has_sin else None
    alone = g.twin(poker=False) if has_sin else None
    reach = {((), 0, g.bag, 0): 1.0}
    st = dict(hand=0.0, sin=0.0, total=0.0, bust=0.0, dance=0.0, throws=0.0, choices=0.0, costly=0.0, flips=0.0,
              asked=0.0, hand_wins=0.0, refused=0.0, lone=0.0, mix={})
    for bag in range(g.bag, -1, -1):
        for key, w in [(k, w) for k, w in reach.items() if k[2] == bag]:
            row, skulls, _, bank = key
            if len(row) >= ROW or bag == 0:
                t = g.split(row, bank)
                st["total"] += w * t[0]; st["hand"] += w * t[1]; st["sin"] += w * t[2]
                continue
            n = g.best_draw(row, skulls, bag, bank)
            if bag > 1:
                st["throws"] += w
                st["mix"].setdefault(skulls, {}).setdefault(n, 0.0)
                st["mix"][skulls][n] += w
            else:
                st["dance"] += w
            mass = 0.0
            for p, opts in g.outcomes(row, skulls, bag, bank, n):
                mass += p
                vals = sorted(((g.value(*o[1]), i) for i, o in enumerate(opts)), reverse=True)
                pick = opts[vals[0][1]]
                if len(opts) > 1:
                    d = vals[0][0] - vals[1][0]
                    st["choices"] += w * p
                    if d >= 0.25:
                        st["costly"] += w * p
                    if d < 1e-9:
                        st["flips"] += w * p
                    if pick[0] == "refuse":
                        st["refused"] += w * p
                    if has_sin:
                        # the plain and Sin-only twins carry no bank of their own choices: compare on this state's options
                        pv = [round(plain.value(o[1][0], o[1][1], o[1][2], 0), 9) for o in opts]
                        sv = [round(alone.value(*o[1]), 9) for o in opts]
                        fh = {i for i, v in enumerate(pv) if v == max(pv)}
                        fs = {i for i, v in enumerate(sv) if v == max(sv)}
                        if not (fh & fs):
                            st["asked"] += w * p
                            if vals[0][1] in fh:
                                st["hand_wins"] += w * p
                elif pick[0] not in (0, None):
                    st["lone"] += w * p
                reach[pick[1]] = reach.get(pick[1], 0.0) + w * p
            st["bust"] += w * (1.0 - mass)
    return st


def show(games):
    print("%-44s %5s %5s %5s %6s %6s %6s | %7s %6s %6s | %5s %9s" % (
        "the hand", "marks", "hand", "Sin", "busts", "dance", "throws", "choices", "costly", "flips", "asked", "hand wins"))
    out = []
    for g in games:
        s = study(g)
        c = s["choices"] or 1.0
        a = s["asked"]
        print("%-44s %5.2f %5.2f %5.2f %5.1f%% %5.1f%% %6.2f | %7.2f %5.0f%% %5.0f%% | %5.2f %8s" % (
            g.name, s["total"], s["hand"], s["sin"], 100 * s["bust"], 100 * s["dance"], s["throws"],
            s["choices"], 100 * s["costly"] / c, 100 * s["flips"] / c, a, ("%.0f%%" % (100 * s["hand_wins"] / a)) if a > 1e-9 else "-"))
        out.append((g, s))
    print()
    print("DRAWS: share of throws at each number of dice, by skulls showing; and refusals a hand")
    for g, s in out:
        parts = []
        for sk in sorted(s["mix"]):
            t = sum(s["mix"][sk].values())
            parts.append("%d sk " % sk + "/".join("%d:%.0f" % (n, 100 * v / t) for n, v in sorted(s["mix"][sk].items())))
        print("%-44s %s%s" % (g.name, "   ".join(parts), ("   refused %.2f" % s["refused"]) if g.refuse else ""))


def lone6(row):          # a lone 6 pays 4, each 2 costs 1 (the one shape in the demand pitch)
    return (4 if row.count(6) == 1 else 0) - row.count(2)

def keep_low(m):         # the Sin pays when you keep the lowest face thrown, if there was a higher one to take
    return lambda row, f, pips: m if len(set(pips)) > 1 and f == min(pips) else 0

def keep_new(m):         # the Sin pays when you keep a face you do not hold, though one you hold was thrown
    return lambda row, f, pips: m if f not in row and any(x in row for x in pips) else 0

def send_back(m):        # the Sin pays for each die you send back that matched your row
    return lambda row, f, pips: m * sum(1 for x in pips if x in row and x != f)


if __name__ == "__main__":
    print("THE HAND WITH NO SIN")
    show([
        Hand("today: draw 1 to 3, three skulls bust"),
        Hand("draw 2 or 3", min_draw=2),
        Hand("draw 2 or 3, four skulls bust, bag 8", min_draw=2, bust_at=4, bag=8),
        Hand("draw 2 to 4", min_draw=2, max_draw=4),
        Hand("draw 2 to 4, four skulls bust, bag 8", min_draw=2, max_draw=4, bust_at=4, bag=8),
        Hand("always draw 3", min_draw=3),
        Hand("you may refuse (a die is lost)", refuse=True),
        Hand("you may refuse, bag 8", refuse=True, bag=8),
        Hand("draw 2 or 3, you may refuse, bag 8", min_draw=2, refuse=True, bag=8),
    ])
    print()
    print("WITH THE LONE 6 (pays 4, each 2 costs 1)")
    show([
        Hand("today + lone 6", end_bonus=lone6),
        Hand("draw 2 or 3 + lone 6", min_draw=2, end_bonus=lone6),
        Hand("draw 2 or 3, 4 skulls, bag 8 + lone 6", min_draw=2, bust_at=4, bag=8, end_bonus=lone6),
        Hand("you may refuse, bag 8 + lone 6", refuse=True, bag=8, end_bonus=lone6),
    ])
    print()
    print("A SIN ON THE DRAW (today's hand)")
    show([
        Hand("keep the lowest thrown: pays 1", keep_bonus=keep_low(1)),
        Hand("keep the lowest thrown: pays 2", keep_bonus=keep_low(2)),
        Hand("keep a new face over a match: pays 1", keep_bonus=keep_new(1)),
        Hand("keep a new face over a match: pays 2", keep_bonus=keep_new(2)),
        Hand("each match you send back: pays 1", keep_bonus=send_back(1)),
        Hand("each match you send back: pays 2", keep_bonus=send_back(2)),
        Hand("draw 2 or 3 + keep the lowest: pays 1", min_draw=2, keep_bonus=keep_low(1)),
    ])
