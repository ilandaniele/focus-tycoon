# Focus Tycoon

Cozy isometric zoo builder powered by real focus and meditation sessions. Godot 4.7, typed GDScript, mobile-first (portrait).

> Focus Tycoon does not measure or verify real concentration. It rewards the time you choose to dedicate. Meditation content is general wellbeing, not medical or psychological treatment.

## Requirements
- Godot 4.7.x (standard build, not .NET). On Windows: `winget install GodotEngine.GodotEngine`.
- No plugins, accounts or network services are needed to run the vertical slice.

## Run
```bash
godot --path . --import
godot --path .
```
Desktop controls: left/middle drag to pan, wheel to zoom, click to place. Debug builds show "Advance clock" buttons in Profile to simulate elapsed focus time.

## Tests
```bash
godot --path . --headless --import
godot --path . --headless -s res://tests/run_tests.gd
```
Exit code 0 means all tests passed. Run a subset with the `TEST_FILTER` environment variable (substring of the test file name), e.g. `TEST_FILTER=ledger`.

## Smoke boot
```bash
godot --path . --headless --quit-after 120
```
Must print no `SCRIPT ERROR`.

## Android debug APK
Needs JDK 17, Android SDK (build-tools) and Godot 4.7.2 export templates, with their paths set in Editor Settings > Export > Android.
```bash
godot --path . --headless --export-debug "Android" build/android/focus-tycoon-debug.apk
adb install -r build/android/focus-tycoon-debug.apk
```

## Layout
| Path | Content |
|---|---|
| `docs/` | PRD, GDD, TRD, UX, data schema, milestone plan, status |
| `data/` | All balance numbers (economy, catalog, species, meditations, objectives) |
| `scripts/domain/` | Pure logic, no engine nodes, injectable clock |
| `scripts/persistence/` | Atomic save store |
| `scripts/autoload/` | Services wiring domain to engine |
| `scripts/world/`, `scenes/world/` | Isometric park, camera, placement, animals |
| `scripts/ui/`, `scenes/ui/` | HUD and screens |
| `scripts/platform/` | Store and notification interfaces with mock backends |
| `assets/` | Optional final art; placeholders are generated when files are missing |
| `locale/` | ES/EN strings |
| `tests/` | Headless test runner, unit and integration tests |

## Not included yet (needs confirmation)
Real in-app purchases, local notifications, Supabase sync and store publishing require plugins, accounts or paid developer programs. See `docs/01-PRD.md` risks R3–R6 and `docs/06-plan-implementacion.md` tasks 5.5–5.7 and 6.4–6.6.
