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
const IDLE_HINT := 4.0       # seconds idle before the primary action is hinted
const HINT_SCALE := 1.18

# ---- Motion ----
const FLY_ARC := 120.0       # px a flying value bows upward
const STAGGER := 0.08        # between several things doing the same job (dice landing, numbers flying)
const COUNT_UP := 0.45       # destination counts up after the value arrives

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

# ---- Text ----
const FLY_FONT := 72
const STAMP_FONT := 150


static func k_of(value: float) -> float:
	return clampf(absf(value) / BIG_VALUE, K_MIN, 1.0)


## A phase length at the current speed.
static func t(seconds: float) -> float:
	return maxf(MIN_PHASE, seconds / speed)
