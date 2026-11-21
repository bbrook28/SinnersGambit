"""The refusal, checked two more ways (the review of the refusal pitch). Exact, on demand7.py's engine.
1. Is refusing a skill or a rule of thumb? Best play against players who draw and keep exactly as best play
   does, but decide whether to refuse by a simple rule:
     never        never refuses (so: how much is the option worth at all, with the draws tuned for it)
   A refusal worth exactly the same as keeping counts as a keep here (demand7.py counts it as a refusal,
   which is why its refusals a hand read higher).
     no gain      refuses when no thrown die improves the hand's poker marks now (never on an empty row)
     no match     refuses when no thrown die matches a face in the row (never on an empty row)
     no match 2+  the same, but only once the row holds two dice or more
     knows the 6  no match 2+ for the lone 6: a first 6 counts as a match; a second 6 or a 2 is never kept
                  (if nothing else was thrown, it refuses); among the dice it may keep, it keeps as best play does
   and "today's best" plays the no-refusal game exactly right and never refuses.
   Each is scored in the refusal game; gap = (best - player) / player; refusals a hand for each.
2. The Last Dance: how many hands reach it, how many of those only because of a refusal (a hand that
   refused at least once before the Dance), and what share of busts are Last Dance losses.
python -I demand8.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from functools import lru_cache
from demand import PAY, classify
from demand7 import Hand, ROW, lone6


def best_keep(g):
    def keep(row, skulls, bag, bank, opts):
        return max(opts, key=lambda o: g.value(*o[1]))
    return keep

def best_die(g, opts):
    dice = [o for o in opts if o[0] != "refuse"]
    return max(dice, key=lambda o: g.value(*o[1]))

def refuse_opt(opts):
    return [o for o in opts if o[0] == "refuse"][0]

def rule_never(g):
    return lambda row, skulls, bag, bank, opts: best_die(g, opts)

def rule_no_gain(g):
    def keep(row, skulls, bag, bank, opts):
        now = PAY[classify(row)]
        gain = not row or any(PAY[classify(o[1][0])] > now for o in opts if o[0] != "refuse")
        return best_die(g, opts) if gain else refuse_opt(opts)
    return keep

def rule_no_match(g, least=1):
    def keep(row, skulls, bag, bank, opts):
        if len(row) < least or any(o[0] in row for o in opts if o[0] != "refuse"):
            return best_die(g, opts)
        return refuse_opt(opts)
    return keep


def rule_knows_six(g):
    def keep(row, skulls, bag, bank, opts):
        ok = [o for o in opts if o[0] != "refuse" and o[0] != 2 and not (o[0] == 6 and 6 in row)]
        wanted = [o for o in ok if o[0] in row or o[0] == 6]
        if not ok or (len(row) >= 2 and not wanted):
            return refuse_opt(opts)
        return max(ok, key=lambda o: g.value(*o[1]))
    return keep


def play(g, draw, keep):
    """Exact (marks, refusals a hand, bust, dance reached, dance reached after a refusal, bust on the dance)."""
    @lru_cache(maxsize=None)
    def ev(row, skulls, bag, bank, refused):
        if len(row) >= ROW or bag == 0:
            return (float(g.split(row, bank)[0]), 0.0, 0.0, 0.0, 0.0, 0.0)
        n = draw(row, skulls, bag, bank)
        dance = bag == 1
        out = [0.0] * 6
        mass = 0.0
        for p, opts in g.outcomes(row, skulls, bag, bank, n):
            mass += p
            pick = opts[0] if len(opts) == 1 else keep(row, skulls, bag, bank, opts)
            ref = pick[0] == "refuse"
            r = ev(*pick[1], refused or ref)
            for i in range(6):
                out[i] += p * r[i]
            if ref:
                out[1] += p
        out[2] += 1.0 - mass
        if dance:
            out[3] += 1.0
            out[4] += 1.0 if refused else 0.0
            out[5] += 1.0 - mass
        return tuple(out)
    return ev((), 0, g.bag, 0, False)


def report(name, g, today, extra=()):
    bd = lambda row, skulls, bag, bank: g.best_draw(row, skulls, bag, bank)
    td = lambda row, skulls, bag, bank: today.best_draw(row, skulls, bag, bank)
    players = [("best play", bd, best_keep(g)),
               ("today's best, never refuses", td, lambda r, s, b, k, opts: best_die(today, opts)),
               ("never (draws as best play)", bd, rule_never(g)),
               ("refuse when nothing gains", bd, rule_no_gain(g)),
               ("refuse when nothing matches", bd, rule_no_match(g)),
               ("nothing matches, row of 2+", bd, rule_no_match(g, 2))]
    players += [(who, bd, make(g)) for who, make in extra]
    print(name)
    print("  %-30s %6s %8s %9s %6s | %6s %14s %16s" % ("player", "marks", "best is", "refusals", "busts", "Dance", "after refusing", "busts on Dance"))
    best = None
    for who, d, k in players:
        r = play(g, d, k)
        best = best if best is not None else r[0]
        print("  %-30s %6.2f %+7.0f%% %9.2f %5.1f%% | %5.1f%% %13.0f%% %15.0f%%" % (
            who, r[0], 100 * (best - r[0]) / max(r[0], 1e-9), r[1], 100 * r[2], 100 * r[3],
            100 * r[4] / r[3] if r[3] else 0.0, 100 * r[5] / r[2] if r[2] else 0.0))
    print()


if __name__ == "__main__":
    for bag in (7, 8):
        today = Hand("today", bag=bag)
        r = play(today, lambda row, s, b, k: today.best_draw(row, s, b, k), best_keep(today))
        print("NO REFUSAL, bag %d: marks %.2f, busts %.1f%%, Dance reached %.1f%%, busts on the Dance %.0f%% of busts\n" % (
            bag, r[0], 100 * r[2], 100 * r[3], 100 * r[5] / r[2]))
        report("YOU MAY REFUSE, bag %d" % bag, Hand("refuse", bag=bag, refuse=True), today)
    report("YOU MAY REFUSE, bag 8, with the lone 6 (pays 4, each 2 costs 1)",
           Hand("refuse", bag=8, refuse=True, end_bonus=lone6), Hand("today", bag=8, end_bonus=lone6),
           extra=[("knows the 6: no match, row 2+", rule_knows_six)])
    # why "today's best, never refuses" earns less with a bag of 8 than with 7: the Last Dance's wild die
    for bag in (7, 8):
        t = Hand("today", bag=bag)
        d = lambda row, sk, b, k, t=t: t.best_draw(row, sk, b, k)
        r = play(t, d, best_keep(t))
        print("no refusal, bag %d: %.2f marks; the Last Dance (and its wild die) comes in %.0f%% of hands" % (bag, r[0], 100 * r[3]))
