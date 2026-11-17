# Focus Tycoon

[![CI](https://github.com/ilandaniele/focus-tycoon/actions/workflows/ci.yml/badge.svg?branch=dev)](https://github.com/ilandaniele/focus-tycoon/actions/workflows/ci.yml)

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

## Android builds
Needs JDK 17, Android SDK (build-tools) and Godot 4.7.2 export templates, with their paths set in Editor Settings > Export > Android. Exports use the Gradle build (`android/` is generated and gitignored), which packages the billing and notification plugins.
```bash
godot --path . --headless --install-android-build-template --export-debug "Android" build/android/focus-tycoon-debug.apk
adb install -r build/android/focus-tycoon-debug.apk
```
Release AAB for Google Play. The keystore and its password live outside the repo and are passed through environment variables:
```bash
set -a; . ~/.focus-tycoon/release.env; set +a
godot --path . --headless --export-release "Android AAB" build/android/focus-tycoon-release.aab
```
`release.env` defines `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER` and `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. Back up the keystore: Play rejects updates signed with a different key.

## Platform integrations
| Feature | Android | Without the plugin (desktop, tests) |
|---|---|---|
| In-app purchases | `addons/GodotGooglePlayBilling` (MIT). Works only in builds installed from Play with products created in Play Console | `MockStore` |
| Local notifications | `addons/NotificationSchedulerPlugin` (MIT) | `NullNotificationBackend` |
| Cloud sync | Cloudflare Worker + D1 in `server/`, enabled when `data/sync.json` has a `url` | Disabled when `url` is empty |

Sync uploads the resource ledger with one idempotent key per transaction. Each install gets an anonymous player id and a random bearer token (the server stores only its SHA-256 hash). D1 triggers recalculate balances and ignore keys already stored, so retries never duplicate resources. The server mirrors the local ledger as a backup; it is not an anti-cheat authority.

API (`https://focus-tycoon-api.ilandaniele.workers.dev`):
| Endpoint | Purpose |
|---|---|
| `POST /v1/players` | Create an anonymous player, returns `{player_id, token}`. Rate limited per IP |
| `POST /v1/transactions` | Upload up to 100 ledger entries, returns `{received, accepted}`. Rate limited per player |
| `GET /v1/resources` | Server balance for the token's player |

Server commands (run in `server/`):
```bash
npm ci
npm run typecheck
npm test
npm run db:migrate
npm run deploy
```
`npm test` runs the Worker against a local D1 with `@cloudflare/vitest-plugin`; no Cloudflare account needed. `db:migrate` and `deploy` need `npx wrangler login`. To point a dev build at another server, write `data/sync.local.json` (gitignored) with `{"url": "..."}`.

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
| `scripts/platform/` | Store, notification and sync backends (plugin, mock and null) |
| `addons/` | Third-party Godot plugins (billing, notifications) |
| `server/` | Cloudflare Worker sync API, D1 migrations and tests |
| `assets/` | Optional final art; placeholders are generated when files are missing |
| `locale/` | ES/EN strings |
| `tests/` | Headless test runner, unit and integration tests |

## Not included yet
Store publishing needs paid developer accounts (Google Play USD 25 one-time, Apple USD 99/year). iOS export needs a Mac. Device profiling needs a phone. See `docs/ESTADO.md`.
