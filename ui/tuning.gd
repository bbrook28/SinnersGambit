## Every presentation duration and intensity, in one place. Seconds are at speed 1.0.
## `speed` is the global multiplier (the debug slider and the speed seal both set it).
## Docs/UXPass.md.
extends RefCounted

static var speed := 1.0
const SPEED_MIN := 0.25
const SPEED_MAX := 4.0
const SHOW_DEBUG_SLIDER := true

# ---- The four phases of every beat ----
const ANTICIPATION := 0.3    # the element lifts / pulses
const ACTION := 0.4          # it moves (values travel)
const IMPACT := 0.15         # scale punch, flash, shake, particles, haptic
const HOLD := 0.4            # stillness so the result can be read
const MIN_PHASE := 0.05      # no phase shrinks below this at high speed (unless skipped)

# ---- Focus ----
const DIM := 0.4             # brightness of everything that isn't the focal point
const INFO_DIM := 0.8        # on your turn: information you need but can't tap (dice, turn total)
const FOCUS_SCALE := 1.08    # the focal element grows a little
const FOCUS_FADE := 0.2      # dim / undim time
const LIFT_SCALE := 1.12     # anticipation lift
const PUNCH_SCALE := 1.25    # impact punch at full intensity

# ---- Turn change ----
const BANNER_IN := 0.35
const BANNER_HOLD := 0.8
const BANNER_OUT := 0.35

# ---- Bots ----
const THINK := 0.6           # visible "thinking" before every bot action
const CARD_HOLD := 0.5       # the chosen move, enlarged at centre, before it resolves

# ---- Your turn ----
const PULSE_PERIOD := 1.2    # interactables breathe
const PULSE_SCALE := 1.05
const RING_PULSE := 1.6      # the selected seal's gold ring glows up and down this often
const ENTER_STAGGER := 0.04  # seals enter one by one, this far apart
const ENTER_SCALE := 0.55    # and spring up from this size
const ENTER_SPRING := 0.35
const PRESS_SQUASH := Vector2(1.08, 0.86)  # a seal under the thumb
const RELEASE_WOBBLE := 0.4  # spring back after release
const WOBBLE_DEG := 4.0       # the seal rocks this far on release
const IDLE_HINT := 4.0       # seconds idle before the primary action is hinted
const HINT_SCALE := 1.18

# ---- Motion ----
const FLY_ARC := 120.0       # px a flying value bows upward
const STAGGER := 0.08        # between several things doing the same job (dice landing, numbers flying)
const COUNT_UP := 0.45       # destination counts up after the value arrives
const DUST_K := 0.22         # dust puff where each thrown die lands
const SETTLE_DEG := 7.0      # a landed die rocks this far before it settles

# ---- Size of the outcome (rule 6) ----
# Intensity k in [K_MIN, 1] = value / BIG_VALUE. Scales punch, shake, particles and the action phase.
const BIG_VALUE := 300.0
const K_MIN := 0.25
const ACTION_STRETCH := 0.6  # action phase lasts up to (1 + this) times longer at k = 1
const SHAKE_PX := 26.0       # screen shake at k = 1
const PARTICLES_MIN := 6
const PARTICLES_MAX := 48
const HAPTIC_MS_MIN := 15
const HAPTIC_MS_MAX := 70

# ---- Sound (ui/sfx.gd) ----
# dB per sound, 0 = as recorded. Bigger results add up to +3 dB (k = 1) or take off 3 (k = 0).
const MUTE := false
const VOL_MASTER := 0.0
const VOL := {
	"lift": -16.0, "shake": -10.0, "whoosh": -14.0,
	"impact_light": -10.0, "impact": -8.0, "impact_heavy": -6.0,
	"tick": -18.0, "throw": -4.0, "throw_one": -4.0,
	"seal": -6.0, "plaque": -10.0,
	"nail": -6.0, "nail_last": -3.0, "bell": -2.0, "crack": -6.0,
	"coins": -4.0, "coins_small": -8.0, "buy": -6.0,
	"banner_in": -8.0, "banner_out": -12.0,
	"glass": -10.0, "glass_light": -10.0, "hit": -6.0, "stamp": -6.0, "card": -10.0, "win": -4.0,
}
const PITCH_JITTER := 0.06          # random pitch spread so repeats don't sound identical
const TICK_PITCH := Vector2(0.9, 1.7)  # count-up ticks rise from .x to .y across the count
const TICK_GAP := 0.045             # count-up ticks never come faster than this
const SFX_GAP := 0.04               # the same sound never retriggers faster than this
const SFX_VOICES := 16

# ---- Materials (ui/shaders) ----
const GLINT_PERIOD := 5.5        # seconds between specular sweeps across a seal
const GLINT_STRENGTH := 0.45
const GLINT_STAGGER := 0.06       # sweep phase between neighbouring seals, so the glint travels along the row
const SHIMMER_PERIOD := 3.2       # gold numerals catch the light this often
const SHIMMER_STRENGTH := 0.6
const PAGE_LIGHT := 0.14          # how much the candle pool brightens the parchment
const CANDLE_FLICKER := 0.25     # how much the candle pool wavers (0 = steady)
const TILT_PX := 7.0              # the page slides this far at full tilt
const TILT_SMOOTH := 4.0          # higher = follows the phone faster
const TILT_DRIFT := 0.35          # desktop / no accelerometer: slow drift amplitude (in tilt units)
const MARGINALIA_SCALE := 1.0     # corner figures drawn this much bigger than painted on the page

# ---- Text ----
const INK_IN := 0.5           # prompts and the turn line ink in left to right over this long
const WASH_TIME := 0.45      # screen transition: ink floods in, then draws away, each this long
const PAGE_TURN := 0.3       # the Chronicle turns open or shut
const INK_GRAIN := 0.35       # uneven ink density in the lettering
const CAP_SCALE := 1.35       # the illuminated first capital, relative to the line (more steals seal room)
const PROMPT_FONT := 57       # prompt lettering (was 44: +30%)
const FLY_FONT := 72
const STAMP_FONT := 150


static func k_of(value: float) -> float:
	return clampf(absf(value) / BIG_VALUE, K_MIN, 1.0)


## A phase length at the current speed.
static func t(seconds: float) -> float:
	return maxf(MIN_PHASE, seconds / speed)
