import sys, os; sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); import demand
from demand import Game

class G2(Game):
    """danger: marks per die thrown while `at` or more skulls show (not the Last Dance)."""
    def __init__(self, danger=0, at=2, **kw):
        super().__init__(**kw)
        self.danger, self.at = danger, at
        self._sk = 0
    def outcomes(self, row, skulls, bag, bank, n):
        self._sk = skulls
        yield from super().outcomes(row, skulls, bag, bank, n)
    def gain(self, n, dance):
        g = super().gain(n, dance)
        if not dance and self._sk >= self.at:
            g += self.danger * n
        return g

def near(face, top):
    return {f: top - abs(f - face) for f in range(2, 7) if top - abs(f - face) > 0}

games = [
    Game(name="no Sin"),
    Game(face=near(6, 2), name="near 6: 6+2 5+1"),
    Game(face=near(2, 2), name="near 2: 2+2 3+1"),
    Game(face=near(4, 2), name="near 4: 4+2 3,5+1"),
    Game(face=near(3, 2), name="near 3: 3+2 2,4+1"),
    Game(face=near(6, 3), name="near 6: 6+3 5+2 4+1"),
    Game(face=near(4, 3), name="near 4: 4+3 3,5+2 2,6+1"),
    Game(face={6: 1, 5: 1}, name="6 and 5 +1"),
    Game(face={6: 1, 2: -1}, name="6 +1, 2 -1"),
    G2(danger=1, at=2, name="danger: die at 2 skulls +1"),
    G2(danger=2, at=2, name="danger: die at 2 skulls +2"),
    G2(danger=1, at=1, name="danger: die at 1+ skulls +1"),
    G2(danger=1, at=2, face=near(6, 2), name="near 6 + danger 1"),
]
for g in games:
    g.report()
