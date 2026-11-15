## Every presentation duration and intensity, in one place. Seconds are at speed 1.0.
## `speed` is the global multiplier (the debug slider and the speed seal both set it).
## Docs/UXPass.md.
extends RefCounted

static var speed := 1.0
static var muted := false          # sound effects off (Settings: Sound slider at 0)
static var sfx_vol := 1.0          # Settings: Sound, 0..1
static var music_vol := 0.7        # Settings: Music, 0..1
static var haptics := true         # Settings: Haptics
static var reduce_motion := false  # Settings: no shake, tilt, idle breathing, flicker or figure reactions
const SPEED_MIN := 0.25
const SPEED_MAX := 4.0
const SHOW_DEBUG_SLIDER := false  # the on-screen speed slider (debug only)
const RUN_MODE := false  # debug: the parked run game on the menu ("Run (old)", Docs/RunDesign.md); off in tester builds
const BOT_SUMMARY := false  # the bot-turn summary paragraph on the thumb page (off at the table, TableDesign §5)
const LINE_CHANCE := 0.5   # a Sin says a line on about this share of events (TableDesign §3)
const LINE_HOLD := 0.8     # a line stays up this long, at reading speed even on a bot's turn
const MARKS_FONT := 36     # mark pips, claims and debt chips under each window

# ---- The four phases of every beat ----
const ANTICIPATION := 0.3    # the element lifts / pulses
const ACTION := 0.4          # it moves (values travel)
const IMPACT := 0.15         # scale punch, flash, shake, particles, haptic
const HOLD := 0.4            # stillness so the result can be read
const MIN_PHASE := 0.05      # no phase shrinks below this at high speed (unless skipped)
const BOT_MIN_PHASE := 0.02  # on a bot's turn: its many short phases would otherwise add up past 2.5 s

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
const THINK := 0.6           # visible "thinking" before a bot's attack card
const CARD_HOLD := 0.5       # the chosen move (attacks only), enlarged at centre, before it resolves
# Pacing: a bot's turn should come in under 4 s at 1x (tests/bot_pace.gd measures it).
static var pace := 1.0       # set per beat by the director: 1 on your turn, BOT_PACE on a bot's
const BOT_PACE := 6.0        # a bot's beats play this much faster than yours (table: a bot turn in 2.5 s, TableDesign §5)
const FIRST_GAME_BOT_PACE := 0.5  # First Game: bots play at half that speed, so you can follow them
static var bot_pace_scale := 1.0  # set by main._start
const BOT_THINK := 0.5       # "thinking" before a bot's first throw of the turn only (scaled by BOT_PACE)
const BOT_BANNER_HOLD := 0.3 # turn-change band hold for a bot (yours: BANNER_HOLD)
const BOT_ANTICIPATION := 0.0  # a bot's beats skip the wait before the action (the lift still plays under it)
const BOT_HOLD := 0.3        # and hold this fraction of HOLD afterwards

# ---- Table ----
const TABLE_SIZES := [4, 7]  # you plus 3 or 6 bots; the first is the default
static var table_size := 4

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
	"tick": -22.0, "throw": -4.0, "throw_one": -4.0,
	"seal": -6.0, "plaque": -12.0,
	"nail": -6.0, "nail_last": -3.0, "nail_toll": -10.0, "bell": -4.0, "crack": -8.0,
	"coins": -10.0, "coins_small": -14.0, "buy": -8.0,
	"banner_in": -10.0, "banner_out": -14.0,
	"glass": -14.0, "glass_light": -10.0, "hit": -6.0, "stamp": -6.0, "card": -12.0, "win": -6.0,
	"sting_wrath": -8.0, "sting_greed": -10.0, "sting_lust": -9.0, "sting_envy": -9.0,
	"sting_pride": -9.0, "sting_gluttony": -9.0, "sting_sloth": -8.0,
}
## Base pitch per sound (Docs/AudioStyle.md: low and dark). 1.0 = as recorded / as synthesized.
const SFX_PITCH := {
	"lift": 0.8, "whoosh": 0.8, "banner_in": 0.75, "banner_out": 0.75, "card": 0.8,
	"seal": 0.85, "stamp": 0.8, "nail": 0.85, "nail_last": 0.8, "crack": 0.85,
	"impact_light": 0.9, "impact": 0.9, "impact_heavy": 0.85, "buy": 0.8, "hit": 0.8,
	"glass_light": 0.8, "plaque": 0.9,
}
## Close, dry touches; everything else rings into the Nave bus (ui/sfx.gd).
const SFX_DRY := ["plaque", "tick"]
## The Nave bus: AudioEffectReverb plus a low-pass on everything but SFX_DRY.
const NAVE_PREDELAY_MS := 40.0
const NAVE_ROOM := 0.85
const NAVE_DAMPING := 0.7
const NAVE_WET := 0.28
const NAVE_LOWPASS_HZ := 7000.0
const PITCH_JITTER := 0.06          # random pitch spread so repeats don't sound identical
const TICK_PITCH := Vector2(0.8, 1.35) # count-up bell pings rise from .x to .y across the count
const TICK_GAP := 0.045             # count-up ticks never come faster than this
const SFX_GAP := 0.04               # the same sound never retriggers faster than this
const SFX_VOICES := 16
const SOLO_CUT := 0.12              # a solo sound (play_solo) fades out this fast when the next one starts

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
# Main menu windows (main._build_menu): centred row, lit glass, shafts onto the table.
const MENU_WINDOW_MARGIN := 0.05   # side margin, fraction of screen width
const MENU_SHAFT_LEN := 0.36       # shaft length, fraction of screen height
const MENU_SHAFT_STRENGTH := 0.5
const MENU_SHEEN_PERIOD := 9.0     # seconds between sheens across each window
const MENU_SEAL_TEXT := 0.2       # menu seal word size, fraction of the seal (Play)
const MENU_SEAL_ROOM := 0.56       # widest a word may be, fraction of the seal (inside the recess)
const MENU_HALO := 0.75            # halo and rim glow round each window (breathes 0.7x-1.35x)
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


## The playback rate right now: the global speed times the beat's pace (bots play faster).
static func rate() -> float:
	return speed * pace


## A phase length at the current rate.
static func t(seconds: float) -> float:
	return maxf(MIN_PHASE if pace <= 1.0 else BOT_MIN_PHASE, seconds / rate())

# ---- Legibility (Phase 2) ----
const CAUSE_HOLD := 1.5        # a score change's cause ("Banked", "The Vig") stays beside the score, real seconds
const CAUSE_FADE := 0.25       # its fade in and out
const CAUSE_SIZE := 32         # its text size
const RESULT_SIZE := 38        # the one-line throw result under the throw total
const PLATE_CAPTION := 24      # "Score" / "Dice" captions on the player plates
const CANDLE_SIZE := Vector2(40, 110)  # each Strike candle (shorter in Phase 6, so the dice get the height)
const SNUFF := 0.25            # a candle going out

# ---- Sin select (Phase 4: ui/sin_carousel.gd) ----
const SELECT_SNAP := 0.45          # a page springs into place
const SELECT_TURN := 0.2           # drag this fraction of the width to turn the page
const SELECT_FLICK := 900.0        # or flick faster than this (px/s)
const SELECT_PAGE_PAD := 40.0      # px each side of a page's content
const SELECT_LIGHT := 0.95         # the Sin-coloured glow behind the window
const SELECT_LIGHT_FADE := 0.35    # it cross-fades to the next Sin's colour this fast
const SELECT_LIGHT_BREATHE := 0.7  # and breathes down to this much (off with Reduce Motion)
const SELECT_LIGHT_PERIOD := 4.0
const SELECT_CHOOSE := 260         # the Choose seal

# ---- Game layout (Phase 5) ----
const ZONE_GLANCE := 21.0          # stretch ratios of the board's three zones: windows and plates,
const ZONE_TRAY := 49.0            # the tray (about 44% of the screen with the safe areas; Phase 5 was 24 / 46 / 30),
const ZONE_THUMB := 30.0           # the parchment page (prompts, seals, the bot-turn summary)
const WINDOW_CROP := 1.8           # board windows show the arch and figure: height = width x this
const WINDOW_CROP_TOP := {}        # per Sin, where the crop starts (fraction of the height; default 0)
const CROWN_SIZE := Vector2(64, 44)  # the leader's crown over their window
const BADGE_SIZE := 46.0           # status badges down a window's right edge
const BADGES := {                  # badge colours, in the order they stack
	"purg": Color("9a1b1b"), "greater": Color("e0b042"), "drag": Color("2a58c8"), "pact": Color("c02c78"),
}
const PAUSE_ITEM_W := 560          # the pause menu's buttons
const SUMMARY_FONT := 34           # the bot-turn summary lines
const SUMMARY_ROWS := 6            # at most this many bot turns listed (fewer when they don't fit: _summary_fit)
const SUMMARY_NAME := {"Greed": Color("3d4a5c")}  # a Sin name too pale to read on parchment, darker

# ---- Feedback (Phase 6) ----
const DIE_SIZE := 150.0            # largest a die is drawn; the real size is what fits TRAY_DICE with TRAY_MARGIN (main.die_side), the same at any count
const DIE_GAP := 18.0              # between dice, both ways
const TRAY_MARGIN := 16.0          # clear leather round the block of dice
const DIE_MIN := 110.0             # tools/ui_audit.gd flags a tray whose dice come out smaller than this
const DICE_PER_ROW := 6
const TRAY_DICE := 18              # the tray always fits this many (12 bought plus added, with room)
const NOTE_SIZE := 46              # an ability note in the score strip ("Hubris  bets 100")
const ADDED_TINT := 0.45           # an ability-added die: its face washed this much toward the Sin's colour
const ADDED_RIM := 0.08            # and a glow of that colour this far round it (fraction of the die)
