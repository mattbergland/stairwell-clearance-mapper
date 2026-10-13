# Clearance Mapper (Stairwell Clearance Mapper)

An iPhone app for antique-piano crew leads on a site visit. Pick a piano,
list each doorway, stair, and turn along the route, and the app tells you —
for every obstacle — whether it **Fits**, is **Tight**, or **Won't fit**,
plus the best way to carry the piano through it.

It works fully offline. No accounts, no servers, nothing leaves the phone.

## Who it's for

Movers and crew leads scoping a job in an old house. It's a planning aid,
not a guarantee — **estimates only, always confirm on site.**

## How the fit check works

* Every piano dimension gets padded (blankets and a skid board) — you set
  how much.
* For each obstacle the app tries every sensible way to carry the piano
  (standing, on its back, on its side on a skid, stood on its tail) and
  keeps the best one.
* Doorways compare the padded piano against the opening. Stairs also tilt
  the headroom to the stair angle. Turns compute the longest line that can
  pivot around the corner and let you lift the leading end up to 60°.
* If the tightest spot still leaves your safety margin → **Fits**. Under
  the margin but not negative → **Tight**. Negative → **Won't fit**, with
  practical suggestions (pull the door stops, remove the handrail, hoist).

## Run it

1. Open `StairwellClearanceMapper.xcodeproj` in Xcode.
2. Pick an iPhone simulator (or your own phone) from the device menu.
3. Press **Run** (⌘R).

If you ever regenerate the project: `xcodegen generate` (XcodeGen required).

## Install on your own iPhone

**Option A — free, with Xcode and any Apple ID:**

1. Plug your iPhone into the Mac.
2. On the phone: Settings → Privacy & Security → Developer Mode → on.
3. In Xcode, select the project → Signing & Capabilities → pick your
   personal team.
4. Press Run. The app works for 7 days, then just press Run again to
   refresh it.

**Option B — share with the crew via TestFlight:** join the Apple Developer
Program ($99/year), archive the app, and invite testers.

## Project layout

* `StairwellClearanceMapper/App` — app entry and shared state (auto-saves
  your route to the phone between launches).
* `StairwellClearanceMapper/Models` — pianos, obstacles, settings, display
  formatting.
* `StairwellClearanceMapper/Engine` — the fit math (pure Swift, no UI).
* `StairwellClearanceMapper/Views` — one file per screen.
* `StairwellClearanceMapper/Resources` — the built-in piano library and icons.
* `StairwellClearanceMapperTests` / `…UITests` — unit and UI tests.

## Lint and tests

```sh
swiftlint --strict
xcodebuild build -project StairwellClearanceMapper.xcodeproj \
  -scheme StairwellClearanceMapper \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild test -project StairwellClearanceMapper.xcodeproj \
  -scheme StairwellClearanceMapper \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

## Next ideas (not in v1)

* Saved jobs — keep multiple site visits on file
* Photos per obstacle
* Shareable PDF report for the customer
* Turn diagrams that show the piano pivoting
* AR measuring with LiDAR

## Disclaimer

Dimensions in the built-in library are typical values — measure the actual
piano if unsure. Clearance estimates are a starting point for planning, not
a guarantee. Always confirm on site.
