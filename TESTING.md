# Test this prototype

## Windows build

Extract the complete `CSTCG-Windows-x86_64.zip` and run **CSTCG.exe**. Keep `CSTCG.pck` beside the executable. Godot does not need to be installed to run the portable build.

## Godot project

Extract `CSTCG-Godot-Project.zip`, import `CSTCG/project.godot` with **Godot 4.6.3 standard**, and press **F5**. The project ZIP includes the source, map, design documents, and tests. Godot recreates its import cache on first import.

On Linux, the portable build runs with `./CSTCG.x86_64` after extracting its archive. Keep the adjacent PCK file in place.

## Suggested first test

1. Open **Packs**. You begin with two Contender packs and 800 credits.
2. Click a wrapper to inspect its foil, guarantee and exact odds. Open a pack, tear the wrapper, reveal one card, then press **Escape** during a flip. **Resume opening** should return to the same secured cards and committed reveal position. Inspect a revealed card, return to the opening, reveal the rest and select **Build your five**.
3. Add a new player to the lineup. The previous player should remain in your collection.
4. Search **Collection** by player handle or real name. Clear the filters, inspect a card and choose **View card back**. If multiple source copies are owned, select each in the dropdown and verify its matching back. Use **Tab** within the dialog, then **Escape** to return focus to that card. Choosing a source alone must not change the lineup.
5. Try a local AI trade at **Trades**. The last copy of an active player and its selected source stays protected. AI acquisitions without an original pack recorded use an Archive back.
6. Set a tactic in **Matches**, then select **Play match**. Cancel the choice once; your match count and wallet should stay unchanged.
7. Select **Play out match**. Watch the automatic Dust II match, follow a player, change cameras, pause, and change speed. At full time, check full rewards: 160 CR / 100 XP for a win or 85 CR / 60 XP for a loss.
8. For the next fixture choose **Skip to result (less rewards)**. The report appears immediately, with 80 CR / 50 XP for a win or 43 CR / 30 XP for a loss. Viewing this report again must not repeat its payout.
9. Start another played match. After a completed round, return to the club and reopen the match. Its current round restarts with the same seed; the previous score remains. Reopening the whole app should also preserve it.
10. Open **Help & settings → Open 3D map lab**. Try an overhead/angled view, select a route, and use **Reset & walk route**.
11. In the map lab, Shift-click two walkable surfaces to inspect a sightline. Middle-drag pans; the wheel zooms; V changes the view.
12. Return to the club, resize to 1100×740, and check the menus, player profile, pack reveal, and match choice. Primary actions should fit, with longer pages scrolling vertically.
13. Buy an **Elite Circuit** pack for 600 CR and compare its longer charge/slow tear, raised crest, denser sparks and burst sound with Contender. A new club starts with enough credits to try one. The seam should peel before the shockwave and explosive card fan. Use **Skip animation** during the tear, burst and a reveal; it should finish only the current transition and clear its effects.
14. Enable **Reduce motion**. In **Help & settings**, also try disabling **3D collectible previews** and **Pack sound effects**. Close and reopen the game. Your preferences, cards, credits, lineup, and match history should remain.

This is **alpha 0.5 / pack-origin card backs**, with 3D collectible presentation and premium pack animations. The playable collection remains thirty players with Contender and Elite Circuit packs; the four Series 1 products are design specifications. Dust II is the alpha's only match map. The separate map lab remains a geometry tool and does not affect your club. Played matches use causal movement, combat and bomb objectives; skipped matches use the original aggregate simulation. See [current build notes](docs/CARD_BACKS_0_5.md) and [match rules](docs/ALPHA_0_2.md) in the source ZIP. Real public player identities have custom alpha roles/stats and neutral monograms; photographic portraits are not bundled. Trades use local AI managers.

## Saves and reports

The game saves locally. On Windows the default directory is `%APPDATA%\Godot\app_userdata\CSTCG · Club Circuit\`; engine logs are in its `logs` subdirectory. Back up `club_v1.json` before deliberately starting over. Schema-2 clubs gain an origin ledger, preserving quantities, progression, pending openings and matches; the exact original is backed up as `club_v1.json.before-card-backs.bak`. Their earlier completed pulls use Archive backs because their packs were not recorded. Older schema-1 identity migration retains `club_v1.json.before-alpha2.bak`. The `--ephemeral` launch argument starts an unsaved test session. A played fixture locks roster, packs and strategy until it finishes.

For a useful bug report, include the build's `BUILD_INFO.txt`, your operating system, the screen/action, expected behavior, observed behavior, and a screenshot or log if available. Mention whether the issue repeats after reopening the game.

## Validation scope

The source project passes headless gameplay/state checks, UI button flows, twelve collision-walked map routes, complete causal matches, wall/smoke occlusion, bomb rules, overtime, save migration and deterministic match resume. Graphical scenes have been reviewed under Linux/Mesa at 1440×960 and 1100×740. Exported Linux and packaged-resource checks are recorded with the test artifacts. A Windows export is not a claim that it has already been exercised on native Windows hardware.

## Rebuild the portable exports

Install Godot 4.6.3's matching official export templates. From the project directory:

```bash
mkdir -p builds/windows builds/linux
godot --headless --path . --export-release "Windows Desktop" builds/windows/CSTCG.exe
godot --headless --path . --export-release Linux builds/linux/CSTCG.x86_64
```

The presets include JSON map metadata explicitly and omit source-only documents, tests, tools, and the raw STL. The imported map resource is included in the game pack. Windows executables use the standard export template without resource-editing or signing tools.
