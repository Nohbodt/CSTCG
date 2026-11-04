# GDD v3.0 · Source reconciliation and recommended changes

This is a design recommendation, not a record that every proposed change has already been approved or implemented. The uploaded v2.0 PDF has been read in full; it remains unmodified in `reference/ESPORTS_CSTCG_Master_GDD_v2_0.pdf`. Its reported historical prototypes are source claims, not runtime evidence from the current repository.

The new master is [ESPORTS_CSTCG_Master_GDD_v3_0.md](ESPORTS_CSTCG_Master_GDD_v3_0.md). The earlier [GAME_DESIGN.md](GAME_DESIGN.md) remains a reference for the playable v0.1 prototype's actual rules.

## What each source contributes

| Source | Keep because it strengthens the game |
| --- | --- |
| Old master: vision, identities, development | Unique tradable instances, independent rarity/tier, eight useful attributes, specific sniper profiles, named Pubstompers, permanent history, mod sockets |
| Old master: coaching and simulation | Default automation with optional real calls; Playbook–Midrounding preferences; causal rounds, information asymmetry, real equipment, 3D authority, meaningful support attribution |
| Old master: collecting and supply | Sealed transferable packs, versioned pools, event editions, Artifact source-first draws, provenance, exact-instance market transactions |
| New prototype: accessibility | A complete starter lineup, immediate pack access, a readable pack room, five-card reveals, filters, squad actions, local save recovery, and a clear loop back from results |
| New prototype: honest evidence | Godot executable/runtime checks, state regression tests, UI button-flow tests, and a clear distinction between aggregate probability simulation and a future causal engine |

## Decisions that deliberately change v2.0

The previous “LOCKED” labels are preserved as historical design status, not silently reassigned. The user requested an optimized synthesis; the entries below make the recommended revisions explicit for normal design review. They do not require blocking independent document work.

| Topic and source | Previous rule | v3.0 recommendation | Reason / status |
| --- | --- | --- | --- |
| Chemistry, §11 pp. 9–10 | Hidden ceiling solely from A/B/C composition; new roster starts at 0 | Visible familiarity/fit, competent new-pair baseline, hidden tendencies influence actions rather than a secret permanent ceiling | **Proposed change to locked rule:** give the manager an actionable problem |
| Substitutions, §11 p. 9 | Immediate penalty then 3-match decline; one replacement trends to C0−30; reverting also disrupts | Preserve known pair relationships; evaluate once at queue entry; no delayed tax or penalty for UI edits | **Proposed change to locked rule:** opening a useful player should invite experimentation |
| Pair identity | Chemistry keyed to exact roster/card history in legacy design | Club familiarity keyed to base player pairs; printing upgrades retain it; instance differences still affect fit | **Proposed new contract:** edition collecting should not erase learned partnerships |
| Promotion, §8 pp. 7–8 | Same-pro sacrificed cards only; 10/25/40/55 PP; exact natural rolls never change | Keep costs, duplicate values, sockets, and immutable rolls; add one earned focus PP per eligible appearance toward the current step | **Proposed extension to locked material rule:** duplication accelerates progress rather than being its sole access route |
| Pubstompers, §4 p. 5 | 10× promotion costs; conversion details open | Ordinary promotion schedule, earned development, academy achievements, initial account binding | **Proposed change to locked multiplier:** protect attachment to named starters |
| Mod cooldown, §9 p. 8 | 10 eligible matches or 10 real hours before another application | Free preview, explicit replacement loss, immutable queued builds; no wall-clock cooldown | **Proposed change to locked cooldown:** reduce unnecessary waiting while retaining investment decisions |
| Mod replacement, §9 p. 8 | Cannot cleanly remove; fate of replaced mod open | Destroy replaced attachment and refund a disclosed portion of release value; no recovered full-value mod | **Recommended resolution of open rule:** understandable and testable sink |
| Training, §9 p. 8 | Temporary effective stats for 3 matches or 2 hours, first expiry wins | Free 3-match preparation plan affecting familiarity/execution; no idle expiry or purchased ranked stat boost | **Proposed change to locked duration/effect model:** avoid loss from time away |
| Pack shelf, §26 p. 17 | Standard 1 player + 2 mods; seven offerings in 3 cheap/3 mid/1 expensive split | Keep 1+2 Map Scouts; add five-player Squad/Spotlight families; start with three clear families | **Proposed change to locked shelf/count:** increase player discovery and reduce redundant store choices |
| Welcome Gift, §4 p. 5 | Peak player + 4 additional generated items; categories unresolved | Peak + 2 additional players + 2 beginner mods; account-bound academy editions | **Recommended resolution of open contents:** useful first squad/bench choices and supply protection |
| Rarity distribution, §7 p. 7 | Eight named classes; ordinary Peak 0.001%–0.50%; Divine table open | Keep names; publish candidate normalized slot tables and pack-level Peak chances; no ordinary Divine initially | **New candidate tuning, not approved odds:** preserves ordinary Peak range and distinguishes welcome guarantee |
| Artifact, §27 p. 18 | Source-first draw, one item, no floor; Shiny Rare+; ratios 1.10P and 1.595P | Retain rules and ratios; show conditional source/item tables; treat as later collector products | **Retained with clearer semantics:** avoid confusing archive collecting with reliable roster upgrades |
| Ranked team construction | Ranked rules open | Test a 100-point effective squad-selection budget; cost is not a match bonus | **New recommendation:** cheaper specialists remain useful beside rare stars |
| Monetization, §28 p. 18 | Earned/purchased Credits financing tradable random packs | Earned-only economy testing; prefer cosmetic monetization, with paid Credits requiring a fresh explicit product decision | **Proposed change to locked commercial intent:** protect fairness and evaluate actual costs before committing |
| Mobile, §§1–2 pp. 3–4 | PC and mobile target | Keep both targets; mobile-aware design, PC validation first, staged native mobile | **Scope sequencing recommendation:** not a permanent removal of mobile |
| Market modes, §28 p. 18 | Fixed prices, auctions, direct trades; fee amount open | Fixed listings/direct trades first, auctions later; 5% listing fee is only a test candidate | **Retain target, stage delivery:** solve atomic ownership before auction breadth |
| Match overtime, §14 p. 11 | MR12/MR8; overtime open | Candidate MR3; pathological runtime failure handled explicitly, not by silently assigning a winner | **Recommended resolution of open rule:** competitive integrity over prototype convenience |

## Prototype rules that must not accidentally become production promises

| Existing v0.1 behavior | Production design treatment |
| --- | --- |
| Four rarities, including Epic | Use the old eight-class taxonomy in the future model; migration needs its own implementation |
| One fixed entry per identity and quantity counts | Migrate to unique instances, with base identity used for lineup legality |
| Exactly Entry/AWPer/IGL/Support/Lurker | Make T/CT assignments flexible while keeping automatic role coverage readable |
| “Shared club” adds effective rating | Replace with actual partnership/plan preparation, not mandatory nationality/team links |
| Scalar team rating rolls the round, then flavor commentary | Keep as a UI demonstration only; final causal events produce outcomes and attribution |
| Three map labels share an abstract static diagram | Not proof of three playable maps or migrated 3D assets |
| Free starter roster, 800 CR, two Contender packs | Preserve prototype behavior; production onboarding uses the proposed Pubstomper/Common/Peak sequence |
| Contender 200 / Elite 600, fifth Rare/Epic guarantee | Preserve existing build; proposed Map Scout/Squad/Spotlight definitions are different products |
| Six tied OTs then one deciding round | Prototype-only completion cap; do not present it as a standard CS or ranked rule |
| Local AI offers, JSON wallet, local RNG | Useful demonstrations; not player-to-player exchange or authoritative paid inventory |

## Economy and table checks

The five proposed player-rarity rows each sum to 100%. Ordinary pack-level Peak chances are computed as `1 − product(1 − p_slot)` under independent slots: Map Scout 0.01%; Squad about 0.2997%; Spotlight about 0.4990%. The two mod-slot rarity and tier distributions independently sum to 100%; content validation must guarantee every supported combination exists.

At the proposed highest ordinary price of 1,000 CR, Artifact is 1,100 CR and Shiny Artifact is 1,595 CR. The chemistry example preserves six of ten established pair bonds, yielding familiarity 64 after one new player; with 65% familiarity weight the displayed change is 10.4 at unchanged fit. Three candidate growth updates take a new pair from 40 to approximately 50.2. Ordinary promotion still totals 130 PP and ten sockets at T1.

These are internal consistency checks, not playtest results or proof that the economy is balanced. Production release/refund values, player-selection costs, full pools, development reward eligibility, and fee policy still need measured calibration.

## Source preservation and deliverables

- Original PDF SHA-256: `ec6dd5646367a89f3090fd65942e1f5e4067a4583eb32e6704676ba28a8caf13`.
- New master: editable Markdown, PDF, and Word exports of the same recommended design.
- Legacy prototype spec remains in place with a pointer to the new master.
- No game logic, saves, tests, lockfiles, or in-game numerical values are changed by this design merge.
- The PDF does not contain the legacy Godot code, radar source, or STL. Their availability/integration is an engineering prerequisite, not a completed migration.
