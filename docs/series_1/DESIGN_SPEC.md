# CSTCG Series 1 — launch collection and art specification

**Design version 1.0.** This defines the four requested launch products and all 90 collectible card designs. It is a content and art specification, separate from the playable alpha 0.2 catalogue. Exact pools, eight-attribute profiles, per-card art briefs and odds are supplied as structured data and spreadsheets.

The confirmed format is approximately 50 eligible cards per pack product, with three- or five-card openings. Every product below has exactly **50 eligible definitions**, including ten designs for each of the five assigned roles.

## 1. The launch shelf

| Exact product name | Opening | Pool | Identity | Guaranteed final slot | Acquisition target |
| --- | ---: | ---: | --- | --- | --- |
| CSTCG Series 1 Alpha | 3 players | 50 | Burnt orange / first contact | 1 Rare or better | 240 earned CR |
| CSTCG Series 1 Bravo | 3 players | 50 | Arctic blue / the next move | 1 Rare or better | 240 earned CR |
| CSTCG Series 1 Elite | 5 players | 50 | Black glass and champagne metal | 1 Legendary-or-better Elite Showcase | 1,000 earned CR |
| CSTCG Series 1 Beta Event | 5 players | 50 | Violet and mint / First Circuit | 1 Rare-or-better Beta Event edition | Event track; no credit price |

Prices are balance candidates. Names, opening sizes, pool membership, art hierarchy and guarantee wording are the settled Series 1 design baseline. Randomized outcomes use earned progression for this launch specification. Opening a pack needs no additional key or fee.

All four products are player packs. Workshop modifications and strategy plans belong in separately labelled rewards/products, rather than unexpectedly occupying a guaranteed player slot.

Alpha and Bravo are complementary collections at the same price and odds. Their shared cards are the **same collectible definitions**, with the same collector numbers, artwork and gameplay data. A shared card does not acquire orange or blue stats depending on which wrapper contained it. The choices are about wanted players and collector preferences.

## 2. Ninety designs, sixty players

| Collection | Designs | Gameplay profiles | Presentation |
| --- | ---: | ---: | --- |
| Series 1 Original | 60 | 60 | Six rarity frames, a player-specific portrait and background motif |
| Elite Showcase | 10 | Existing profiles | Alternate portrait take, black-glass stage, embossed nameplate and controlled metal foil |
| Beta Event / First Circuit | 20 | Existing profiles | Alternate portrait take, violet contour art, mint ribbon and event stamp |
| Master checklist | 90 | 60 | One global collector number per design |

Each role has twelve base profiles: four Common, two Uncommon, two Semi-Rare, two Rare, one Legendary and one Peak. Each role also has two Elite Showcase and four Beta Event designs. The full card checklist is in [CARD_DETAILS.md](CARD_DETAILS.md) and [card_checklist.csv](card_checklist.csv).

Alpha and Bravo each contain fifty base cards and share forty. Alpha contains five exclusive Common and five exclusive Uncommon definitions; Bravo has the complementary ten. Together they expose all sixty base players. Elite contains forty base cards, excluding Commons, and ten Showcases. Beta Event contains thirty base cards and twenty Event editions. See [pack_pools.csv](pack_pools.csv) for every membership and [POOL_ANALYSIS.md](POOL_ANALYSIS.md) for overlaps.

The pool count measures collectible designs: Alpha and Bravo each contain fifty professionals, Elite forty professionals across fifty designs, and Beta Event thirty-four professionals across fifty designs. The master set has sixty unique identities.

An alternate edition has the same eight natural attributes, role and game tendency as its base profile. It adds **zero** stat points. A lineup may field one version of a professional, enforced by `player_id`, including across legacy and future editions. No fake autograph or invented player quote appears on the artwork.

## 3. A shared visual language

The direction is a premium esports trading card: a recognizable athlete, restrained tactical geometry, a large readable handle, and materials that become richer with rarity. The portrait carries the card. Abstract map lines support it without crossing the eyes, obscuring the silhouette, or pretending to show a verified historical match.

Use a graphite foundation `#10151D`, warm white `#F1F0E8`, and muted secondary type `#9CA7B4`. Headers use DejaVu Sans Condensed Bold; supporting text uses Open Sans. Both already have bundled notices in the project. Avoid ornate fantasy shields, excessive HUD text and official game/team logos. Jerseys remain unbranded until a specific approved asset is available.

### Wrapper family

All four wrappers share the same tall foil pouch, crimp height, CSTCG wordmark position, SERIES 1 line, large product name and bottom guarantee band. Each wrapper remains recognizable from its silhouette/emblem as well as color. A full product title is used in the locker and receipt; large face copy may stack CSTCG / SERIES 1 / ALPHA.

| Product | Main / secondary color | Central emblem | Surface and pattern | Copy |
| --- | --- | --- | --- | --- |
| Alpha | `#F36C3D` / `#E9E2D0` | Split A with one forward slash | Matte graphite, brushed orange diagonal, shallow topographic grain | FIRST CONTACT / Your first five starts here. |
| Bravo | `#4BB7E8` / `#C6F3FF` | Folded B formed by two angular chevrons | Satin navy, ice-blue route lattice, two offset folds | THE NEXT MOVE / Find another way to win. |
| Elite | `#DDB56E` / `#F4E6BB` | Faceted five-point crest | Black glass, restrained embossed metal, five narrow stage-light rays | THE HEADLINERS / The names. The stage. The moment. |
| Beta Event | `#A28AF5` / `#65E3CC` | Split beta glyph and event ribbon | Violet contour-map film, mint perimeter, iridescent seam | FIRST CIRCUIT / Be part of the first circuit. |

The front says **3 PLAYER CARDS** or **5 PLAYER CARDS** and the actual guarantee. A smaller **50-CARD POOL** line explains the pool; it never implies fifty cards are inside one wrapper. The back/detail view lists the eligible catalogue version, exact slot odds, repeat-draw rule and acquisition source. Price remains live UI text rather than permanent wrapper art.

### Opening sequence

Present the sealed wrapper and guarantee, tear along the top seam, fan three or five identical concealed sleeves, and reveal individually or all at once. Keep the guaranteed slot last. The cover sleeve does not leak rarity or identity; the first reveal exposes the actual card face. No near-miss reel, rarity roulette or fake reveal outcome is used.

Rarity reveals use light and sound to identify a real result: Common has a clean click, Uncommon a brief edge sweep, Semi-Rare a cyan line, Rare a blue panel lift, Legendary a warm stage flare, and Peak a quiet white-gold opening with a longer optional portrait hold. Elite and Beta Event add their edition treatment after the rarity is legible. Reduced motion shows the same result in a still frame; reveal-all remains available.

The summary separates **NEW PLAYER**, **NEW EDITION** and **DUPLICATE**. It offers Compare, Add to lineup, Keep and eligible Trade/Release actions. Merely finishing an animation never creates a second card or reward.

## 4. The general player-card face

Master face artboard: **840 × 1,200 px**, aspect 7:10, 40 px safe margin. The frame and text are separate layers. In a small squad tile, the handle, overall, primary role and rarity must remain legible; the inspector carries the complete eight-attribute model. There is no market price permanently printed on the card.

| Element | Position / rule |
| --- | --- |
| Brand | Top left CSTCG; top right SERIES 1 |
| Overall | Large upper-left numeral, labelled OVR |
| Role, country, tier | Left rail below OVR; literal ENTRY/AWPER/IGL/SUPPORT/LURKER and T5, with country code |
| Portrait | Chest-up, face in the upper central region, shoulders safely within crop; background effect stays behind the face |
| Rarity | Written label and a distinct rail/notch pattern; does not rely on color alone |
| Handle | Largest identity text near the lower portrait edge; preserve stylized public capitalization |
| Full name | Smaller line under the handle; no invented team contract |
| Edition | SERIES 1 / ORIGINAL, ELITE SHOWCASE, or BETA EVENT / FIRST CIRCUIT |
| Face indices | Three large values: AIM / IQ / UTIL |
| Tendency | One short game-policy name such as First Contact or Angle Holder |
| Collector footer | Stable global number such as S1-012/090, plus the individual collector title |

Exact rectangles are supplied under `layout` in [series1_manifest.json](series1_manifest.json). The vector faces are precise layout proofs; their portrait-position monograms are asset placement guides, not the proposed finished player art.

### Face indices and the eight attributes

OVR is the rounded arithmetic mean of Aim, Reaction, Positioning, Utility, Gamesense, Clutch, Teamwork and Consistency. It is a sorting aid, not a win percentage. AIM is the authored Aim value. IQ is the rounded mean of Positioning, Gamesense, Clutch and Consistency. UTIL is the rounded mean of Utility and Teamwork. Reaction remains explicit in detailed inspection and contributes to OVR.

| Attribute | Intended simulation effect |
| --- | --- |
| Aim | Placement and accuracy after a legal firing opportunity exists |
| Reaction | Detection-to-action timing and first-contact response |
| Positioning | Legal exposure, spacing, cover and angle selection |
| Utility | Grenade choice, timing, placement error and coordination |
| Gamesense | Decisions from incomplete evidence, rotations and saves |
| Clutch | Execution and decisions under genuine numerical pressure |
| Teamwork | Communication, synchronization and credible trade attempts |
| Consistency | Execution variance; low consistency is not a hidden average-stat penalty |

The revealed card's inspection reverse shows all eight exact values, the full tendency rule, edition, base player identity, tier, provenance and ownership/build fields. It labels natural and effective values separately when development or mods are implemented. The concealed opening sleeve is a separate uniform CSTCG Series 1 cover, so the reverse does not spoil the opening.

Vector examples: [revealed NiKo inspection reverse](vectors/inspection-example.svg) and [uniform concealed sleeve](vectors/sealed-sleeve.svg).

Tendency labels describe game decision policies, not claims about a real person's personality. They alter intent selection under legal information and routes; they do not award a canned round-win percentage, invent a flash the agent never threw, or give access to hidden opponents. These policies are implementation requirements for the Series 1 update, not a claim that alpha 0.2 already implements them.

## 5. Rarity, tier and finish

This set follows the fuller GDD's **Common → Uncommon → Semi-Rare → Rare → Legendary → Peak** ordinary-player taxonomy. Floor and Divine have zero supply in these four launch products. The earlier prototype's Epic label is retained only in legacy data; it is not a seventh Series 1 rarity. Every listed Series 1 card starts at **T5**. Tier, rarity and artwork finish remain separate fields.

| Rarity | Rail | Frame structure | Material |
| --- | --- | --- | --- |
| Common | Steel `#9AA8AE` | One clean rail, square corner cut | Matte card stock; silver-white type |
| Uncommon | Sage `#93C99D` | Double corner notch | Satin edge and a narrow green reflection |
| Semi-Rare | Cyan `#65CED6` | Three broken line segments | Fine brushed foil on the side rail |
| Rare | Blue `#729BF4` | Framed aperture and four small corner ticks | Controlled blue foil window |
| Legendary | Champagne `#DDB56E` | Faceted metal cap and five ticks | Embossed warm-metal frame; strong portrait separation |
| Peak | Pearl `#F4E8CE` | Pearl arch and six fine ticks | White-gold interference foil, restrained spectral edge |

Elite Showcase adds a black-glass stage, alternate portrait take and raised champagne nameplate to its Legendary/Peak cards. Beta Event adds a violet contour backdrop, mint ribbon and FIRST CIRCUIT stamp while keeping the original rarity rail visible. A violet event ribbon does not mean Epic or Divine. No card claims a unique physical serial number or an actual athlete autograph.

All face values and policies are authored gameplay templates spanning several eras. Rarity controls discovery and edition supply; it does not imply every stat is higher. A Semi-Rare ropz can be an exceptional lurker. A Common support can be more useful to a plan than an expensive shooter. No label claims to reproduce current rankings or contracts.

## 6. Five role motifs and representative cards

| Role | Shared visual motif | Representative original |
| --- | --- | --- |
| Entry | Diagonal breach planes and a short contact slash | NiKo / First Bullet / Peak / S1-012 |
| AWPer | Offset optic circle, a narrow sightline and distant horizon | s1mple / Long Sight / Peak / S1-024 |
| IGL | Five route nodes and a folded tactical line | Aleksib / Round Blueprint / Rare / S1-033 |
| Support | Protective arcs, a useful crossing and soft utility plume | RUSH / Open for Others / Common / S1-037 |
| Lurker | Offset doorway, strong negative space and a late route | ropz / The Long Way / Semi-Rare / S1-055 |

Each of the sixty originals also has its own named motif, pose and lighting direction in the card register. Every Showcase/Event version has a separate alternate-take brief, not just a color replacement. Do not bury the country or role under a foil gradient. Portraits should remain convincing at 168 px wide and clear at full inspection.

Examples of the intended gameplay distinction: Common RUSH has AIM 72 / IQ 77 / UTIL 87; Peak NiKo has AIM 97 / IQ 94 / UTIL 87. Rare Aleksib has AIM 78 / IQ 90 / UTIL 96. Different jobs remain visible without making every support card a disguised Entry.

## 7. Exact opening rules

Select rarity using the immutable per-slot table, then sample uniformly from eligible card definitions of that rarity in that product. The guaranteed Elite slot filters to Showcase; the guaranteed Beta Event slot filters to Event editions. Draws are with replacement. Cards and editions of one professional can appear together in an opening, but the lineup still has one professional identity.

| Slots | Common | Uncommon | Semi-Rare | Rare | Legendary | Peak | Finish restriction |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| Alpha / Bravo 1–2 | 45% | 30% | 18% | 6.50% | 0.45% | 0.05% | Eligible base pool |
| Alpha / Bravo 3 | 0 | 0 | 0 | 95% | 4.90% | 0.10% | Eligible base pool |
| Elite 1–4 | 0 | 25% | 40% | 30% | 4.90% | 0.10% | Any eligible Elite design |
| Elite 5 | 0 | 0 | 0 | 0 | 99.90% | 0.10% | Elite Showcase only |
| Beta Event 1–4 | 45% | 30% | 18% | 6.50% | 0.45% | 0.05% | Any eligible Event-product design |
| Beta Event 5 | 0 | 0 | 0 | 95% | 4.90% | 0.10% | Beta Event edition only |

The at-least-one-Peak chance is approximately **0.1999%** for Alpha/Bravo, **0.4990%** for Elite, and **0.2997%** for Beta Event. These are whole-opening probabilities; they are not per-player odds. All exact per-design probabilities appear in the pool CSV. A higher-rarity result is not an extra slot. There are no hidden pity or personalized-odds rules in this specification.

The extremely scarce ordinary Peak supply follows the GDD; roster improvement must not depend on it. Keep the separate guaranteed-Peak welcome reward, targeted role-choice progression, and the many strong lower-rarity profiles. Publish a role/player choice path alongside any future live pack implementation rather than asking users to complete ninety designs through random openings alone.

## 8. Beta Event and collecting goals

All four named products are visible at launch. The Beta Event product belongs to the inaugural **First Circuit** event, not to a later mandatory stat expansion. Both completed match modes count toward the event track; reduced skip credits/XP remain a separate rule.

Candidate event milestones at 3, 8, 15, 25 and 40 eligible completed matches award one five-card Beta Event pack each. At 20 matches, add a bound choice from the five Rare Event designs. At 40, add a bound choice of any of the twenty Event designs, including a Peak appearance. Those direct choices retain the same stat template and are visibly account-bound; they are separate from the odds of a sealed pack. The milestone schedule and event duration are tuning targets, not dated live offers.

Collection milestones at 5, 15, 30 and 50 distinct designs in a product can grant a club badge, banner, sleeve and trophy. They do not add permanent Aim or lock an essential tactic. One shared definition counts toward each eligible checklist when shown; collecting does not consume it. Broader player identities remain available outside the event, and an eventual archive return must distinguish original-event provenance from a reissue.

## 9. Production handoff

For each base player: supply an approved identity-accurate portrait, portrait cutout mask, named background composition, rarity frame, foil mask and role motif. Alternate editions receive another portrait take and the finish-specific background. Avoid applying purple/gold color grading to skin. Photographic and commissioned illustration routes can both work, but one release should use a consistent treatment. The generated reference art demonstrates composition and materials; it is not a source of verified photographs or athlete endorsement.

Export portrait/background layers at 840 × 1,200 or higher with consistent crop. Frames and masks use that same origin. Keep names, numbers, stats, country, rarity and ownership badges as live text/UI layers. Retain original source files; export display color in sRGB. Supply a static foil texture for reduced motion. No baked UI shadow, fake autograph, per-card price, invented match statistic or preprinted unique ownership serial is included.

The content schema separates `player_id`, immutable `template_id`, collectible `card_id`, eventual owned `instance_id`, `rarity`, `tier`, `finish`, `edition`, pool version and acquisition provenance. `pack.s1.alpha`-style product names must not expose or reuse the GDD's hidden Alpha/Bravo/Charlie behavior labels. The supplied manifest uses `s1.alpha` product IDs and explicit visible tendency names; hidden behavior remains a separate future field.

## 10. Implementation boundary

These files finalize the content/art baseline. The runtime still has the thirty-card, four-rarity, two-product alpha 0.2 catalogue. Installing Series 1 requires a separate catalogue/save migration, three-/five-slot opening UI, six-tier odds, finish-aware guarantees and duplicate labels, one-professional-per-lineup validation, full eight-attribute inspection and the authored decision policies.

Preserve existing inventories as legacy editions with their original data and a backup; do not silently reprice, relabel or overwrite old cards to make this sheet fit. New Series 1 templates have their own definition IDs. Existing credits, packs and history need an explicit deterministic migration before new packs become available. No live build, card supply or save format is changed by generating this design kit.

The builder validates counts, role coverage, weighted-pool eligibility, reachability, exact slot sums, shared-profile parity, overlaps and direct buy/release expectations. It does not claim to have validated combat balance, online market behavior, portrait rights or native-platform rendering for a new playable release.
