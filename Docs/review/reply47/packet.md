# Packet: REPLY 47, push 0.6.0 to TestFlight (pushed once, as allowed; 0 credits)
**Suite:** 15 of 15 pass, load check 113 (run at 475a8e4, before the push).
**Pushed:** `main` moved from 2eb88eb to 475a8e4, 54 commits, everything since build 120: REPLY 32-46 work and packets.
- Checked before pushing: no keys, emails or local paths in the added lines. `project.godot` and the uncommitted `.import` files stayed local.
**Run:** https://github.com/bbrook28/SinnersGambit/actions/runs/44686420710 (run 21, preset "iOS (table)"). Result: success, with every step green. The stamp worked first time under BSD sed.
**Stamped lines from the log:** `const VERSION := "0.6.0"`, `const BUILD := "121"` and `const COMMIT := "475a8e4"`.
**TestFlight:** "Upload succeeded", and the package went into processing as 0.6.0 (121), the values the step wrote into the preset. This was not checked in App Store Connect itself: there is no key for it here. Ben should see 0.6.0 (121) once processing ends.
**Label shipped:** yes. db02ca9, the version label above the Settings page, is in 475a8e4, so Settings reads `0.6.0 (121) 475a8e4`.
**Expect:** an older Continue save is not offered (save version 6). Bets are on in the First Game and offered only to a single human seat, as built.
**Note:** Apple warned at upload that the app was built with the iOS 26.2 SDK and that a newer SDK becomes required from April 2027. Nothing was rejected.
