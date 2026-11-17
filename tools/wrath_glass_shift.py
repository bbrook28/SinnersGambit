# REPLY 32-33: split a kept window into frame and glass and shift the glass up (Wrath: 56 px, no scaling), so his
# eyes land on the other Sins' eye line. Frame = the rim, the gold connected to it, and the lead hugging its inner
# edge; glass = the rest, its pixels under the frame filled from the glass beside them.
# python -I tools/wrath_glass_shift.py <window.png> <out.png> <px up>
import sys
import numpy as np
from PIL import Image

src, out, shift = sys.argv[1], sys.argv[2], int(sys.argv[3])
im = np.asarray(Image.open(src).convert('RGBA')).astype(np.float32)
H, W = im.shape[:2]
solid = im[..., 3] > 128
inside = np.zeros_like(solid)  # the window's shape: each row filled from its first to its last solid pixel
for y in range(H):
    xs = np.nonzero(solid[y])[0]
    if xs.size:
        inside[y, xs[0]:xs[-1] + 1] = True

# distance (in px, chessboard) from the outside, by repeated erosion
dist = np.zeros((H, W), np.int32)
cur = inside.copy()
for d in range(1, 40):
    n = cur.copy()
    n[1:, :] &= cur[:-1, :]
    n[:-1, :] &= cur[1:, :]
    n[:, 1:] &= cur[:, :-1]
    n[:, :-1] &= cur[:, 1:]
    dist[cur & ~n] = d
    cur = n
dist[cur] = 40

r, g, b = im[..., 0], im[..., 1], im[..., 2]
gold = (r > 120) & (g > 80) & (b < g * 0.75) & (r > b + 60) & (np.abs(r - g) < 110)
BAND = 26
# the frame: the rim, then the gold connected to it (so a skin or glass highlight near the edge stays glass),
# then the dark lead hugging the gold's inner edge
frame = inside & (dist <= 6)
cand = inside & gold & (dist <= BAND)
for _ in range(BAND + 4):
    g2 = frame.copy()
    g2[1:, :] |= frame[:-1, :]
    g2[:-1, :] |= frame[1:, :]
    g2[:, 1:] |= frame[:, :-1]
    g2[:, :-1] |= frame[:, 1:]
    g2 &= cand | frame
    if (g2 == frame).all():
        break
    frame = g2
lead = inside & ((r + g + b) < 150) & (dist <= BAND + 3)
for _ in range(2):
    g2 = frame.copy()
    g2[1:, :] |= frame[:-1, :]
    g2[:-1, :] |= frame[1:, :]
    g2[:, 1:] |= frame[:, :-1]
    g2[:, :-1] |= frame[:, 1:]
    frame = frame | (g2 & lead)
# grow the frame by 1 px so its edge carries its own dark outline
f2 = frame.copy()
f2[1:, :] |= frame[:-1, :]
f2[:-1, :] |= frame[1:, :]
f2[:, 1:] |= frame[:, :-1]
f2[:, :-1] |= frame[:, 1:]
frame = f2 & inside

# the glass alone: frame pixels filled from the neighbouring glass (grown inward), so no ornament moves with it
gl = im.copy()
known = inside & ~frame
for _ in range(40):
    if known[inside].all():
        break
    acc = np.zeros_like(gl)
    cnt = np.zeros((H, W), np.float32)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        sk = np.roll(known, (dy, dx), (0, 1))
        sg = np.roll(gl, (dy, dx), (0, 1))
        acc += sg * sk[..., None]
        cnt += sk
    grow = ~known & inside & (cnt > 0)
    gl[grow] = acc[grow] / cnt[grow][:, None]
    known |= grow
# glass shifted up by `shift`, the bottom padded with its last row (below every crop the game uses)
glass = np.concatenate([gl[shift:], np.repeat(gl[-1:], shift, axis=0)], axis=0)
outim = glass.copy()
outim[frame] = im[frame]
outim[~inside] = im[~inside]  # outside the window: as it was (transparent); its glass keeps the shifted leading
Image.fromarray(outim.clip(0, 255).astype(np.uint8)).save(out)
Image.fromarray((frame * 255).astype(np.uint8)).save(out.replace('.png', '_frame_mask.png'))
print('ok', W, H, 'shift', shift)
