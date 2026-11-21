# Demand probe
The exact solver for dice poker with a Sin's demand, in Python, for the pitch `docs/superpowers/specs/2026-11-21-sin-demand-pitch.md`. Not game code.
Its no-Sin value (3.581 marks a hand) matches `sim/dice_sim.gd`.

- `python -I demand.py`: one face, skulls, draw count.
- `python -I demand2.py`: two faces at different prices, dice thrown in danger.
- `python -I demand3.py`: marks from poker and from the Sin.
- `python -I demand4.py`: best play against players who only break ties toward the Sin (greedy+, poker+).
- `python -I demand5.py`: how many keeps and draws a demand changes, prices, and the draw mix (the revised pitch's table).
- `python -I demand6.py`: more shapes tried, among them "a lone 6 pays 4, each 2 costs 1".
