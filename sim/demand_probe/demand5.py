"""How often does a demand change a decision, and what does it do to the draw? Extends demand4.py.
For each demand, all exact, weighted by how often best play reaches each state:
  marks: best play, from the hand and from the Sin; busts
  gaps:  best play over greedy+ and over poker+ (see demand4.py), both scored with the Sin paying
  keeps: keeps a hand with two or more different faces to choose from; of those, how many best play makes
         differently from poker+ ("changed": poker+'s die is worth less under the demand), and how many of
         those cost poker+ a quarter mark or more ("costly")
  hands: share of hands with 0, 1, 2+ costly changed keeps (is it one decision a hand?)
  draws: throws where best play draws a different number of dice than poker+ would, a hand
  asked: keeps where no die is best for both the poker alone (the no-Sin game played on) and the Sin alone
         (a game that pays only the Sin), a hand; and whether best play then keeps the hand's die, the Sin's,
         or a third ("the hand wins" is still a question asked, though poker+ answers it the same way)
  mix:   share of throws at 1/2/3 dice with 0, 1, 2 skulls showing (the Last Dance left out)
python -I demand5.py
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from collections import Counter
from demand import BAG, ROW, MAXD
from demand4 import Game, players, faces, singles, lone, lone_or_cost, no_face


class SinOnly(Game):
    """The same demand with the poker hand worth nothing: what the Sin alone wants."""
    def split(self, row):
        if 0 in row:
            r = [f for f in row if f != 0]
            return max((self.split(tuple(sorted(r + [f]))) for f in range(2, 7)), key=lambda t: t[0])
        b = self.bonus(row)
        return (b, 0, b)   # not floored at 0: a cost must still steer the Sin's wish


def tiered(row):   # the first three faces held once pay 1 each, the fourth and fifth pay 2 each
    n = sum(1 for c in Counter(row).values() if c == 1)
    return n + max(0, n - 3)

def lone_two(a, b, m):   # two faces that each pay while they stand alone
    return lambda row: m * ((row.count(a) == 1) + (row.count(b) == 1))


def study(g, plain):
    pl = players(g, plain)
    best = g.play(*pl["best"])
    gaps = {w: g.play(*pl[w])[0] for w in ("greedy+", "poker+")}
    pdraw, pkeep = pl["poker+"]
    alone = SinOnly(g.name, g.bonus)
    # reach under best play; the state carries the count of costly changed keeps so far (capped at 2)
    reach = {((), 0, BAG, 0): 1.0}
    st = {"keeps": 0.0, "changed": 0.0, "costly": 0.0, "draw_changed": 0.0, "throws": 0.0,
          "mix": {k: [0.0] * 4 for k in (0, 1, 2)}, "hands": [0.0, 0.0, 0.0], "done": 0.0,
          "asked": 0.0, "hand_wins": 0.0, "sin_wins": 0.0, "third": 0.0}
    for bag in range(BAG, -1, -1):
        for key, w in [(k, w) for k, w in reach.items() if k[2] == bag]:
            row, skulls, _, cc = key
            if len(row) >= ROW or bag == 0:
                st["hands"][cc] += w
                st["done"] += w
                continue
            n = g.best_draw(row, skulls, bag)
            if bag > 1:
                st["throws"] += w
                st["mix"][skulls][n] += w
                pn = pdraw(row, skulls, bag)
                if pn != n and g.throw_value(row, skulls, bag, n) - g.throw_value(row, skulls, bag, pn) > 1e-9:
                    st["draw_changed"] += w
            mass = 0.0
            for p, opts in g.outcomes(row, skulls, bag, n):
                mass += p
                c2 = cc
                if len(opts) == 1:
                    nxt = opts[0][1]
                else:
                    nxt = max(opts, key=lambda o: g.value(*o[1]))[1]
                    loss = g.value(*nxt) - g.value(*pkeep(row, skulls, bag, opts))
                    st["keeps"] += w * p
                    pv = [round(plain.value(*o[1]), 9) for o in opts]
                    sv = [round(alone.value(*o[1]), 9) for o in opts]
                    for_hand = {o[0] for o, v in zip(opts, pv) if v == max(pv)}
                    for_sin = {o[0] for o, v in zip(opts, sv) if v == max(sv)}
                    if not (for_hand & for_sin):
                        kept = [o[0] for o in opts if o[1] == nxt][0]
                        st["asked"] += w * p
                        st["hand_wins" if kept in for_hand else ("sin_wins" if kept in for_sin else "third")] += w * p
                    if loss > 1e-9:
                        st["changed"] += w * p
                    if loss >= 0.25:
                        st["costly"] += w * p
                        c2 = min(cc + 1, 2)
                k2 = nxt + (c2,)
                reach[k2] = reach.get(k2, 0.0) + w * p
            st["hands"][cc] += w * (1.0 - mass)   # busted here
            st["done"] += w * (1.0 - mass)
    return best, gaps, st


def mix_text(st):
    out = []
    for sk in (0, 1, 2):
        t = sum(st["mix"][sk]) or 1.0
        out.append("%d sk %s" % (sk, "/".join("%2.0f" % (100 * st["mix"][sk][i] / t) for i in (1, 2, 3))))
    tot = sum(sum(v) for v in st["mix"].values())
    dice = sum(i * st["mix"][sk][i] for sk in (0, 1, 2) for i in (1, 2, 3))
    return "  ".join(out) + "   dice a throw %.2f, throws a hand %.2f" % (dice / tot, tot)


if __name__ == "__main__":
    plain = Game("no Sin")
    games = [
        plain,
        Game("Pride 0.12.0: 6 +2, 5 +1", faces({6: 2, 5: 1})),
        Game("Envy 0.12.0: 6 +1, 2 -1", faces({6: 1, 2: -1})),
        Game("a lone 6 pays 3", lone(6, 3)),
        Game("a lone 6 pays 4", lone(6, 4)),
        Game("a lone 6 pays 5", lone(6, 5)),
        Game("first 6 pays 3, each more costs 2", lone_or_cost(6, 3, 2)),
        Game("a lone 6 and a lone 5 pay 2 each", lone_two(6, 5, 2)),
        Game("each face held once pays 1", singles(1)),
        Game("each face held once pays 1.5", singles(1.5)),
        Game("held once: three pay 1, the rest 2", tiered),
        Game("each face held once pays 2", singles(2)),
        Game("a lone 6 pays 4, each 2 costs 1", lambda row: (4 if row.count(6) == 1 else 0) - row.count(2)),
        Game("no 6 in a full row pays 2", no_face(6, 2)),
        Game("no 6 in a full row pays 3", no_face(6, 3)),
        Game("no 6 in a full row pays 4", no_face(6, 4)),
    ]
    rows = []
    for g in games:
        best, gaps, st = study(g, plain)
        rows.append((g, best, gaps, st))
    print("MARKS AND GAPS")
    print("%-36s %5s %5s %5s %6s  %8s %8s" % ("demand", "best", "hand", "Sin", "busts", "greedy+", "poker+"))
    for g, b, gaps, st in rows:
        print("%-36s %5.2f %5.2f %5.2f %5.1f%%  %+7.0f%% %+7.0f%%" % (g.name, b[0], b[1], b[2], 100 * b[3],
            100 * (b[0] - gaps["greedy+"]) / gaps["greedy+"], 100 * (b[0] - gaps["poker+"]) / gaps["poker+"]))
    print()
    print("DECISIONS THE SIN CHANGES (against poker+), a hand")
    print("%-36s %5s %7s %6s  %-22s %5s" % ("demand", "keeps", "changed", "costly", "hands with 0 / 1 / 2+", "draws"))
    for g, b, gaps, st in rows:
        h = st["hands"]
        print("%-36s %5.2f %7.2f %6.2f  %5.0f%% /%4.0f%% /%4.0f%%     %5.2f" % (g.name, st["keeps"], st["changed"], st["costly"],
            100 * h[0], 100 * h[1], 100 * h[2], st["draw_changed"]))
    print()
    print("QUESTIONS ASKED: keeps where the hand and the Sin want different dice, a hand")
    print("%-36s %5s %6s   %-30s" % ("demand", "keeps", "asked", "the hand wins / the Sin / a third die"))
    for g, b, gaps, st in rows:
        a = st["asked"] or 1.0
        print("%-36s %5.2f %6.2f   %4.0f%% /%4.0f%% /%4.0f%%" % (g.name, st["keeps"], st["asked"],
            100 * st["hand_wins"] / a, 100 * st["sin_wins"] / a, 100 * st["third"] / a))
    print()
    print("DRAWS: share of throws at 1/2/3 dice, by skulls showing")
    for g, b, gaps, st in rows:
        print("%-36s %s" % (g.name, mix_text(st)))
