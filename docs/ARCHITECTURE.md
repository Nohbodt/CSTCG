# Implementation notes

## Project layout

| File | Responsibility |
| --- | --- |
| `project.godot`, `scenes/main.tscn` | Godot project and root scene |
| `scripts/catalog.gd` | Immutable card definitions, pack odds, rarity colors, release values |
| `scripts/club_state.gd` | `Game` autoload; inventory, lineup, economy, trades, progression, transactional saves |
| `scripts/match_simulator.gd` | Seeded aggregate round simulation used by Skip to result |
| `scripts/main.gd` | UI routing, state presentation, confirmations, pack reveal, pre-match chooser, saved reports |
| `scripts/ui.gd` | Shared theme, typography, colors, controls |
| `scripts/presentation/collectible_stage.gd` | Isolated physical pack/card meshes, local 3D viewport, foil materials, sound and cancellable visual tweens |
| `scripts/presentation/pack_opening.gd` | Opening controls and presentation synchronization against already committed contents |
| `scripts/presentation/*.gdshader` | GL Compatibility foil/interference treatments; printed text protected from effects |
| `scripts/card_art.gd`, `pack_art.gd`, `arena_art.gd` | Optional photographic cards with neutral fallback, printed pack art, rendered Dust II menu artwork |
| `scripts/card_back_art.gd` | Pack-specific back geometry/typography shared by openings, 3D inspection and 2D fallback |
| `tools/capture_menu_map.gd`, `assets/ui/dust2_preview.png` | Reproducible menu thumbnail captured from the supplied 3D map |
| `scripts/spatial/dust_world.gd` | Uploaded map, shared render/collision faces, derived navigation, physical movement and ray queries |
| `scripts/spatial/spatial_match_sim.gd` | Fixed-tick causal ten-agent match engine; combat, utility, bomb, equipment and MR12/MR3 |
| `scripts/spatial/played_match.gd`, `scenes/played_match.tscn` | 3D spectator view, playback/cameras, checkpoints and final settlement |
| `scripts/spatial/route_probe.gd` | Bounded, collision-checked route traversal for a player-sized probe |
| `scripts/spatial/spatial_lab.gd`, `scenes/spatial_lab.tscn` | Interactive map authoring viewer and input smoke flow |
| `assets/maps/dust2/` | Original STL, derived OBJ, source manifest, provisional landmark seeds |
| `tests/test_game.gd` | Deterministic gameplay and persistence regression checks |
| `tests/test_spatial.gd` | Source fidelity, 12 collision-walked routes, movement bounds, and sightline regressions |
| `tests/test_live_match.gd` | Full causal fixture, blocked shots, bomb rules, overtime, serialized resume and once-only settlement |
| `tools/check.sh` | Isolated import, state tests, and UI smoke checks with error-output detection |

Game logic is separate from rendering. `CardCatalog` and `MatchSimulator` are `RefCounted` helpers; `Game` is a Node autoload. State mutations return success/failure, emit `changed` only after committing, and do not depend on animation callbacks. UI routes rebuild their view after an action, while the persistent top bar listens to the state signal.

Alpha 0.3 uses native window dimensions rather than scaling a fixed canvas. The sidebar stays fixed, collection columns adapt to the available width, and long pages scroll vertically. Dialogs fit within the window, scroll their content, trap Tab focus, and restore the triggering control on dismissal. Collection filtering rebuilds only the card grid so search typing retains focus. Closing a pack dialog cancels its presentation tween; secured inventory and reveal progress remain in `Game`.

The reduced-motion preference is stored separately in `user://ui_preferences.cfg`; ephemeral tests neither read nor write it. The existing club schema, catalogue identities, odds, prices and reward calculations are unchanged. Regenerate the menu map image on a graphical display with `godot --path . --script res://tools/capture_menu_map.gd -- --ephemeral`, then review and commit the PNG. The helper is excluded from portable exports.

Alpha 0.4 uses the Phase Shift palette and adds 3D collectible/sound preferences to that same settings file. `PackOpening` commits a requested reveal through `Game` before asking `CollectibleStage` to flip cards. Closing the stage kills its tween. Skipping finishes only the current presentation target, and reduced motion uses immediate static states. These components never use `Game.rng`. The more expensive Elite product chooses a richer visual profile through catalogue metadata; that profile cannot alter its existing odds or contents. Collection grids remain static 2D controls. A selectable 2D stage fallback supports lightweight previews.

Pack art and card faces are rendered once into local textures, with printed values coming from existing definitions. Shared meshes provide physical thickness and foil layers; the material masks protect bright printed text. Only the selected stage renders in 3D, and reduced-motion stages freeze after warming their textures. `tools/capture_phase_shift_brand.gd` renders the lightweight menu wordmark; `tools/generate_pack_audio.py` synthesizes the original bundled sounds without external dependencies.

Alpha 0.5.1 bundles 25 temporary real-player photos with pinned source metadata in `assets/players/portrait_sources.json`; five players retain neutral monograms. `CardArt.portrait_path_for()` resolves PNG, WebP and JPEG by the same canonical basename, so a reviewed PNG can replace temporary art and old JPEG paths in frozen fixtures still resolve. All card surfaces share this renderer. Photo loading has no network, inventory or simulation dependency. `tools/capture_player_gallery.gd` renders the roster and verifies texture decoding, coverage and legacy-path compatibility.

## Transaction boundaries

Alpha 0.5 adds schema-3 `card_origins` quantities per definition/source and `squad_origins` for the active copies. Aggregate card counts remain compatible with existing presentation/economy code. `_valid_origins` requires ledger sums to match inventory and the lineup's chosen sources to exist. Grant/removal helpers update both counts inside the same existing snapshot/commit boundary. Release and equip can select a source explicitly. AI receipts without origin information use a labelled unknown source rather than an invented pack. Card backs never modify the profile or simulation inputs.

Schema-2 migration preserves the original as `.before-card-backs.bak`, assigns old unproven sources to the archive, and recovers exactly the known copies in an unfinished opening. Schema-1 still runs canonical-identity migration first and preserves its original `.before-alpha2.bak` bytes. Both pending reveals and causal match checkpoints survive. The source getter returns copies of provenance metadata so inspector filtering cannot mutate it.

- **Acquire pack:** subtract its price and add one owned pack in the same save.
- **Open pack:** consume one owned pack, choose all five results, update quantities, and record the pending reveal in one save.
- **Reveal:** only advance persisted presentation state; do not generate new cards.
- **Trade:** remove one available copy, add the requested copy, and mark the offer used in one save.
- **Skip match:** resolve the complete aggregate match, grant half credits/XP and milestones, and store its report once.
- **Start played match:** save a unique ID, seed, frozen opponent/lineup/card profiles and strategy before opening the 3D scene. Lock collection transactions until completion.
- **Round checkpoint:** persist completed rounds, score, equipment, cash and individual statistics. Resume the current round from its start with the same per-round seed.
- **Complete played match:** grant full credits/XP/milestones, save the causal report and clear the pending fixture in one atomic commit. Matching active IDs and once-only settlement prevent repeat payouts. Reports only read saved results.

All mutations take a deep state snapshot before attempting the local file write. On failure, restore that snapshot. RNG state itself is not restored; no result is exposed when a commit fails. This is acceptable for a local offline prototype and is not a protocol for online pack generation.

Saves use `FileAccess` and `DirAccess` with a `.tmp` write-and-rename. Godot JSON decodes numbers as floats, so integral counters are normalized on load. Schema checks verify the inventory, five role slots, pending reveal, active-match snapshots/checkpoints, and report structures before presentation. Schema 1 IDs migrate one-for-one to real identities, preserving the exact original save as a backup; schema-2 provenance migration then prepares the schema-3 state. There is no local encryption, tamper protection, transaction server, or cloud sync.

## Tests and diagnostics

`bash tools/check.sh` creates temporary XDG directories, imports assets, runs state tests, and launches the UI with `--ephemeral --ui-smoke`. The UI test uses button signals and assertions, exercises 1100×740 and 1440×960 layouts, checks visible dialog actions, filters and focus, and dismisses/resumes a pack during its tear animation. Headless mode exercises layout and control construction but cannot capture pixels. On a graphical display, add `--capture-dir=...` to produce a PNG for each route plus dialogs, sealed pack, reveal, and result.

The state suite uses fixed seeds and exercises actual pack generation, lineup and trade mutations, 180 starter-vs-elite simulation pairs, progression, and disk writes. Thousands of checks include per-round budget and probability bounds; this is not a claim of thousands of independent scenarios.

The additional `--ephemeral --pack-smoke` flow runs both pack profiles, completes normal and skipped reveals, tests interrupted flip resume and mid-opening inspection, checks that visual actions preserve secured contents and gameplay RNG, loads the bundled audio, and exercises reduced motion and the 2D fallback. Use `--fixed-fps 60 --quit-after 2200`; add `--capture-dir=...` on a graphical display to review meshes/shaders. `--record-packs` captures sampled animation frames for a silent preview clip.

The spatial suite imports the actual map and queries Godot physics/navigation. It traverses each key route in both directions, verifies capsule clearance at every step, and checks floor/wall occlusion. The developer lab grants no rewards. `SpatialMatchSim` uses the same world for played matches: routes are physically validated once and cached for the static geometry, perception and shots query real rays, and significant actual events produce the saved report. Rendering and speed changes do not consume simulation RNG. [Map integration](MAP_INTEGRATION.md) documents the source transform, authoring controls, limitations, and geometry tests.

## Extension boundaries

Keep a stable card ID when editing display text. New editions should introduce separate edition IDs and preserve a base player identity. If save shape changes, introduce a schema version and a tested migration rather than overwriting version-one saves.

For a fuller game, move large card sets into typed Resources or validated data files. Split the procedural UI into reusable scenes once its interaction structure settles. Extend the causal engine while preserving its deterministic round restart, snapshot and event serialization contracts. Keep the aggregate simulator isolated to the explicit skip path. Online inventory and trades require a new authoritative service; do not trust quantities supplied by a local save.

`export_presets.cfg` defines Windows x86_64 and Linux x86_64 portable exports with explicit JSON metadata inclusion. `tools/check_exports.py` tests the Linux executable and Windows PCK; `tools/package_builds.py` packages committed source and validated builds with notices and checksums. Official release templates disable CLI scene overrides, so `--ephemeral --spatial-smoke` opens the lab through its menu button and `--ephemeral --live-match-smoke` chooses Play out match through the actual popup. The latter runs a complete causal fixture and verifies full reward settlement. See [TESTING.md](../TESTING.md) for the test and rebuild steps.

Godot's standard GDScript build is sufficient; .NET, npm, and Python packages are not runtime dependencies. Authoring/package helpers use Python's standard library, apart from the optional GDD document exporter.
