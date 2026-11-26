## The game's version (restored for the restart). VERSION is bumped by hand: the minor for each build Ben plays and judges,
## the patch for fixes to it; 1.0.0 is the App Store release. .github/workflows/ios.yml reads VERSION into the
## export preset's short version, and writes BUILD (100 + the run number) and COMMIT before it exports; both
## stay empty in the repo, so a build made here shows "local" and the commit git reports.
extends RefCounted

const VERSION := "0.19.0"
const BUILD := ""
const COMMIT := ""

static var _commit := ""


## The short commit: the one CI wrote, else git's (from source only; an exported local build has none).
static func commit() -> String:
	if COMMIT != "":
		return COMMIT
	if _commit == "" and not OS.has_feature("template"):
		var out := []
		if OS.execute("git", ["rev-parse", "--short=7", "HEAD"], out) == 0 and not out.is_empty():
			_commit = str(out[0]).strip_edges()
	return _commit
