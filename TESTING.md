# Test this prototype

## Windows build

Extract the complete `CSTCG-Windows-x86_64.zip` and run **CSTCG.exe**. Keep `CSTCG.pck` beside the executable. Godot does not need to be installed to run the portable build.

## Godot project

Extract `CSTCG-Godot-Project.zip`, import `CSTCG/project.godot` with **Godot 4.6.3 standard**, and press **F5**. The project ZIP includes the source, map, design documents, and tests. Godot recreates its import cache on first import.

On Linux, the portable build runs with `./CSTCG.x86_64` after extracting its archive. Keep the adjacent PCK file in place.

## Suggested first test

1. Open **Pack room**. You begin with two Contender packs and 800 credits.
2. Open a pack, tear the wrapper, reveal its five cards, and select **Build your five**.
3. Add a new player to the lineup. The previous player should remain in your collection.
4. Try a local AI trade at **Trade desk**. The last copy of an active player stays protected.
5. Choose a map and tactic in **Match room**, then play a simulated match. Check the result and rewards.
6. Open **Match room → Open 3D map lab**. Try an overhead/angled view, select a route, and use **Reset & walk route**.
7. In the map lab, Shift-click two walkable surfaces to inspect a sightline. Middle-drag pans; the wheel zooms; V changes the view.
8. Return to the club, close the game, and reopen it. Your cards, credits, lineup, and match history should remain.

The Dust II map lab tests geometry, movement, and sightlines. Combat and bomb objectives are not yet connected to it. The management game's match engine currently uses aggregate round probabilities. Trades are with local AI managers. The v3 GDD describes the fuller proposed game rather than the contents of this prototype.

## Saves and reports

The game saves locally. On Windows the default directory is `%APPDATA%\Godot\app_userdata\CSTCG · Club Circuit\`; engine logs are in its `logs` subdirectory. Back up `club_v1.json` before deliberately starting over. The `--ephemeral` launch argument starts an unsaved test session.

For a useful bug report, include the build's `BUILD_INFO.txt`, your operating system, the screen/action, expected behavior, observed behavior, and a screenshot or log if available. Mention whether the issue repeats after reopening the game.

## Validation scope

The source project passes headless gameplay/state checks, UI button flows, and twelve collision-walked map routes. Graphical scenes have been reviewed under Linux/Mesa at 1440×960 and 1100×740. Exported Linux and packaged-resource checks are recorded with the test artifacts. A Windows export is not a claim that it has already been exercised on native Windows hardware.

## Rebuild the portable exports

Install Godot 4.6.3's matching official export templates. From the project directory:

```bash
mkdir -p builds/windows builds/linux
godot --headless --path . --export-release "Windows Desktop" builds/windows/CSTCG.exe
godot --headless --path . --export-release Linux builds/linux/CSTCG.x86_64
```

The presets include JSON map metadata explicitly and omit source-only documents, tests, tools, and the raw STL. The imported map resource is included in the game pack. Windows executables use the standard export template without resource-editing or signing tools.
