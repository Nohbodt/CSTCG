# Implementation notes

## Project layout

| File | Responsibility |
| --- | --- |
| `project.godot`, `scenes/main.tscn` | Godot project and root scene |
| `scripts/catalog.gd` | Immutable card definitions, pack odds, rarity colors, release values |
| `scripts/club_state.gd` | `Game` autoload; inventory, lineup, economy, trades, progression, transactional saves |
| `scripts/match_simulator.gd` | Seeded, synchronous, deterministic aggregate round simulation |
| `scripts/main.gd` | UI routing, state presentation, confirmations, pack reveal, match playback |
| `scripts/ui.gd` | Shared theme, typography, colors, controls |
| `scripts/card_art.gd`, `pack_art.gd`, `arena_art.gd` | Procedural printed art and abstract battlefield |
| `scripts/spatial/dust_world.gd` | Uploaded map, shared render/collision faces, derived navigation, physical movement and ray queries |
| `scripts/spatial/route_probe.gd` | Bounded, collision-checked route traversal for a player-sized probe |
| `scripts/spatial/spatial_lab.gd`, `scenes/spatial_lab.tscn` | Interactive map authoring viewer and input smoke flow |
| `assets/maps/dust2/` | Original STL, derived OBJ, source manifest, provisional landmark seeds |
| `tests/test_game.gd` | Deterministic gameplay and persistence regression checks |
| `tests/test_spatial.gd` | Source fidelity, 12 collision-walked routes, movement bounds, and sightline regressions |
| `tools/check.sh` | Isolated import, state tests, and UI smoke checks with error-output detection |

Game logic is separate from rendering. `CardCatalog` and `MatchSimulator` are `RefCounted` helpers; `Game` is a Node autoload. State mutations return success/failure, emit `changed` only after committing, and do not depend on animation callbacks. UI routes rebuild their view after an action, while the persistent top bar listens to the state signal.

## Transaction boundaries

- **Acquire pack:** subtract its price and add one owned pack in the same save.
- **Open pack:** consume one owned pack, choose all five results, update quantities, and record the pending reveal in one save.
- **Reveal:** only advance persisted presentation state; do not generate new cards.
- **Trade:** remove one available copy, add the requested copy, and mark the offer used in one save.
- **Match:** resolve the complete seeded match, grant credits/XP/milestones, and store its report once. Playback and history views read this saved result.

All mutations take a deep state snapshot before attempting the local file write. On failure, restore that snapshot. RNG state itself is not restored; no result is exposed when a commit fails. This is acceptable for a local offline prototype and is not a protocol for online pack generation.

Saves use `FileAccess` and `DirAccess` with a `.tmp` write-and-rename. Godot JSON decodes numbers as floats, so integral counters are normalized on load. Schema checks verify the inventory, five role slots, pending reveal, and report structures before presentation. There is no local encryption, tamper protection, transaction server, or cloud sync.

## Tests and diagnostics

`bash tools/check.sh` creates temporary XDG directories, imports assets, runs state tests, and launches the UI with `--ephemeral --ui-smoke`. The UI test uses button signals and assertions; headless mode exercises layout and control construction but cannot capture pixels. On a graphical display, add `--capture-dir=...` to produce a PNG for each route plus the sealed pack, reveal, and result.

The state suite uses fixed seeds and exercises actual pack generation, lineup and trade mutations, 180 starter-vs-elite simulation pairs, progression, and disk writes. Thousands of checks include per-round budget and probability bounds; this is not a claim of thousands of independent scenarios.

The spatial suite imports the actual map and queries Godot physics/navigation. It traverses each key route in both directions, verifies capsule clearance at every step, and checks floor/wall occlusion. The spatial scene is separate from `MatchSimulator`; it grants no rewards and does not implement combat. [Map integration](MAP_INTEGRATION.md) documents the source transform, authoring controls, limitations, and geometry tests.

## Extension boundaries

Keep a stable card ID when editing display text. New editions should introduce separate edition IDs and preserve a base player identity. If save shape changes, introduce a schema version and a tested migration rather than overwriting version-one saves.

For a fuller game, move large card sets into typed Resources or validated data files. Split the procedural UI into reusable scenes once its interaction structure settles. Replace aggregate match probabilities with a seeded event stream behind the simulator interface, preserving report serialization. Online inventory and trades require a new authoritative service; do not trust quantities supplied by a local save.

`export_presets.cfg` defines Windows x86_64 and Linux x86_64 portable exports with explicit JSON metadata inclusion. `tools/check_exports.py` tests the Linux executable and Windows PCK; `tools/package_builds.py` packages committed source and validated builds with notices and checksums. Official release templates disable CLI scene overrides, so `--ephemeral --spatial-smoke` opens the map through the actual management-menu button. See [TESTING.md](../TESTING.md) for the test and rebuild steps.

Godot's standard GDScript build is sufficient; .NET, npm, and Python packages are not runtime dependencies. Authoring/package helpers use Python's standard library, apart from the optional GDD document exporter.
