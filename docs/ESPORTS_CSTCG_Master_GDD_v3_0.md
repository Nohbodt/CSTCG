# ESPORTS: CSTCG

## Unified Game Design · Version 3.0

**COLLECT THE TALENT. BUILD THE CLUB. MAKE THE CALL.**

Design recommendation · 2 November 2026 · Godot 4 · PC first, mobile target

**The pitch:** The collection excitement and squad-building choices of FIFA Ultimate Team, combined with the roles, equipment economy, coaching, and tense rounds of Counter-Strike. You manage the club and watch its players execute your ideas. A great pull creates a new tactical possibility; a great match gives you a reason to open the next pack.

**Document status.** This is a recommended synthesis of the uploaded 26-page Master GDD v2.0 and the current Club Circuit prototype design. Recommendations that change a v2.0 “LOCKED” rule are identified in section 19 and the accompanying merge notes. They are proposals for the next baseline, not claims of separate creator approval or completed implementation. “Most fun” is a design hypothesis to validate through playtesting.

**What exists today:** a local six-screen Godot prototype with 30 fictional cards, two pack types, a five-role lineup, local AI exchanges, aggregate match probabilities, rewards, and local saves. The old document describes other legacy and 3D experiments; their source projects and map assets were not supplied with this PDF and have not been inspected or integrated here. This GDD defines the fuller potential game.

---

## 01 · The recommended game

Make **one club-building game**, with a large collection feeding a small, meaningful squad. The player should feel like a collector when opening packs, a sporting director when comparing signings, and a coach when preparing for a match. Each activity should create the next decision in the other two.

The four main pleasures are discovery, attachment, experimentation, and watching a plan work. Preserve the surprise of discovering an unusual player, the history of developing a named Pubstomper, the satisfaction of assembling complementary roles, and the moment when a well-timed flash produces an actual traded entry. Higher rarity should create interesting strengths and higher ceilings; ownership alone should not settle the match.

### Six decisions that define this version

1. **The club is the center.** An unlimited binder supports a match squad of five starters and two reserves. Players remember their own club's partnerships; the game supports experimentation without repeatedly wiping chemistry.
2. **Collecting creates choices.** Map Scout packs contain a player and two mods; Squad packs deliver five players; Spotlight packs guarantee a high-rarity player in an advertised role. Duplicates support development, trade, collection goals, or release.
3. **Rarity and promotion stay separate.** Keep the eight original rarity classes and T5–T1 development. A promotion adds build options without rerolling a card's natural abilities.
4. **Competitive team construction has a budget.** Owned cards retain their identities and differences. A roster selection budget makes a cheaper support or prospect useful alongside a star.
5. **The match is caused by ten agents.** Position, information, weapons, utility, timing, and the bomb produce the result. A rating-based probability roll is a prototype tool, not the final competitive engine.
6. **Progress must respect players' time.** Losses move the club forward; development has an earned path; training does not disappear while someone sleeps; permanent collectibles survive seasons.

### What “FIFA meets CS2” means

| From the sports-card fantasy | The CSTCG expression |
| --- | --- |
| Pack walkout and star reveal | Sealed wrapper, identity/role reveal, individual roll, edition, and provenance |
| Squad building | Five distinct players, two reserves, side roles, tactical fit, and a selection budget |
| Evolutions and academy attachment | Named Pubstompers, promotion slots, controlled mods, and earned development |
| Divisions and cups | Club Divisions, seasonal goals, scheduled cups, and repeatable AI circuit fixtures |
| Transfer market | Exact-instance listings, unopened packs, direct exchanges, and verified card history |
| On-field identity | A real CS-style team: entry spacing, trades, utility, map control, economy, and clutch decisions |

Avoid importing disposable contracts, mandatory fitness consumables, escalating weekly power requirements, or permanent upgrades that require continual spending to remain usable. Those would weaken the club attachment this design needs.

## 02 · The connected loop and session rhythm

**Earn or acquire a pack → discover a player → inspect their fit → try a lineup → prepare a plan → play → understand the result → develop the club → collect again.**

Every pack summary should offer useful next actions: try the player, compare with the incumbent, use a duplicate for development, list an eligible card, or keep the pack contents in the binder. Every post-match review should produce a manageable question, such as “Do I need a more reliable support, a different buy policy, or better trade spacing?” The next pack or transfer can then answer a real need.

| Session | Intended activity | Initial duration target |
| --- | --- | --- |
| A short visit | Claim earned progress, open a pack, compare one player, prepare a saved lineup | 2–4 minutes |
| Quick circuit | One MR8 AI or eligible quick fixture and a brief review | 4–7 minutes including preparation |
| Competitive club match | Scouting, MR12 accelerated shared-clock play, optional calls, and rewards | 8–15 minutes; measure before promising |
| A club evening | Several fixtures, a squad experiment, development choices, and a larger reward | 25–45 minutes |

No daily streak is required to preserve progress. Optional weekly goals remain attainable on a few longer sessions. Returning players find their club intact, with a clear next fixture and a useful path toward a chosen signing.

## 03 · Club career, modes, and seasons

The club owns its identity, collection, badge, history, and development. The match squad is five active cards plus two reserves, selected from the binder before queue entry. Reserves support planning across maps and fixtures; they are not unrestricted mid-round substitutions.

**Club Circuit** is the accessible AI career and collection path. A short regional schedule leads into promotion matches and cup fixtures. Opponents have visible tactical tendencies and identifiable strengths. The career introduces new tactical problems instead of merely increasing every opponent's Aim. AI rematches and practice remain available when a player loses; a card purchase is never required to unblock the schedule.

**Club Divisions** is the main owned-collection PvP ladder. It uses MR12, skill matchmaking, and the roster budget described below. Auto Coaching is the default. Manual interventions use the same pause rules and match information. Begin with one flagship ranked queue rather than many population-fragmenting formats.

**Club Cups** are scheduled variations using the same engine and owned club: a roster-budget cap, a map pool, a development restriction, or a themed collection bonus. Rewards primarily celebrate achievement and broaden the collection. They must not introduce a permanently exclusive, competitively mandatory mechanic.

Practice scrims, free lineup trials, and replay review are tools, not additional ranked queues. Draft challenges and unrestricted all-star exhibitions can be added after the main loop is healthy. A full five-star roster remains enjoyable in the circuit and exhibitions even when it exceeds a ranked budget.

Seasons refresh ranking goals, fixtures, events, and cosmetic presentation. Cards, promotions, developed Pubstompers, trophies, and collection history remain. No annual forced collection wipe is recommended. Asynchronous participation requires explicit per-mode opt-in and a locked Auto Coaching snapshot; owning an account is not permission to schedule its roster while the owner is absent.

## 04 · The first twenty minutes

Retain the original **four named Pubstompers + one chosen Common T5 professional**, followed by the guaranteed Peak welcome gift. These give both a personal academy story and an immediate star moment.

1. Name the club and choose colors. Introduce the four customizable Pubstompers through suggested roles; naming can be skipped and changed later.
2. Choose one of twenty Common T5 professionals using a readable role comparison. Show three recommended choices while keeping the full pool available.
3. Receive a legal five immediately. Auto Coaching and basic tactics are already usable.
4. Open the **Welcome Gift: one guaranteed Peak player, two additional player cards, and two beginner mods**. The four extras were unspecified in v2.0; this is the proposed composition. Starter odds/pools are published separately from ordinary packs.
5. Compare the Peak with the incumbent and try a substitution for free. A mixed squad of prospects and professionals should be normal, not a tutorial failure.
6. Play a short guided bot scenario showing one opening, a utility-assisted trade, a plant/retake, and an economy choice. Only the actual events in that run are described.
7. Choose an initial club objective: strengthen a role, rehearse a style, or develop a Pubstomper. Earn the next pack through a real fixture.

The welcome cards and rewards are account-bound academy editions: usable in normal eligible play and developable, but not sellable, giftable, or consumable as transferable-value promotion material. This prevents starter-account farming from supplying the market. Opening the gift is once per account and is not represented as evidence of ordinary Peak odds.

Onboarding does not force a listing, sacrifice a favorite, consume a valuable mod without a preview, or demand knowledge of grenade lineups. The player reaches a second meaningful lineup decision before seeing advanced economy screens.

## 05 · Card identity and the collector's experience

Keep professional identity, card-instance ID, template/era, rarity, promotion tier, edition, acquisition source, and ownership separate. Two cards depicting the same professional may have different rolls, styles, mods, histories, and prices. A lineup can use only one instance of that professional, including alternate editions. Each Pubstomper has a distinct character identity.

| Collectible | Function and ownership rule |
| --- | --- |
| Professional player instance | An individually rolled, developable player; eligible instances can trade with their visible build and history |
| Pubstomper character | A named custom academy player; account-bound in the recommended first release |
| Modification card | A tradable workshop component before application; an applied attachment becomes part of its player-card build |
| Strategy/playbook card | A reusable tactical-policy variant; core progression unlocks are bound, with an eligible alternative subset tradable |
| Sealed pack | An owned, versioned container; transferability is explicit and welcome/reward restrictions stay attached |
| Event/club collectible | Edition cards, cosmetics, badges, or rewards with their own disclosed ownership rules |

### Rarity is the discovery layer; tier is the development layer

Retain **Floor → Common → Uncommon → Semi-Rare → Rare → Legendary → Peak → Divine**, and **T5 → T4 → T3 → T2 → T1**. Remove the prototype's separate Epic terminology from the proposed production taxonomy; existing prototype saves are not silently converted.

Rarity conditions natural distributions, specialist ceilings, and how unusual a roll can be. It does not guarantee all-round superiority or define a fixed +X bonus. A Peak can be a volatile specialist; a Legendary can fit a particular team better. Floor is reserved for transparent practice/scouting or explicitly eligible archive content, rather than ordinary-store filler. Divine stays outside the initial ordinary paid/credit pack pools until its role and supply are tested; prestige/event availability is a separate product decision.

Display two modes of inspection: a readable collectible face and a detailed sporting-director view. The face shows identity, edition, rarity, tier, role suitability, and a compact attribute panel. The inspector shows exact natural values, modification deltas, temporary readiness effects, effective values, sniper profile, observations, and ownership restrictions. A summary rating may help sorting but must not be presented as a match-win predictor.

### The eight attributes remain

| Attribute | What it should change in the match |
| --- | --- |
| Aim | Shot placement, recoil execution, and accuracy after a legal opportunity exists |
| Reaction | Detection-to-action timing and first-contact response |
| Positioning | Exposure, spacing, cover, routes, and angle selection |
| Utility | Grenade selection, timing, execution error, and coordination |
| Gamesense | Decisions from incomplete evidence, adaptation, and saves |
| Clutch | Execution and choices under genuinely pressured numerical situations |
| Teamwork | Communication, support, synchronization, and credible trade attempts |
| Consistency | Performance variance; low consistency is not a hidden average-stat penalty |

Passive, Active, and Combat Sniping remain visible in the inspector rather than on the main face. Values usually occupy roughly 0–100; exceptional natural profiles and mods can exceed 100. Conversion curves need diminishing returns and scenario tests, not a universal hard ceiling or automatic hit chance.

A professional's immutable natural roll comes from a permitted historical/career or event template plus controlled instance variation. Promotion never rerolls it. Synthetic behavior describes a game card, not a claim about a real person's personality. Licenses and data rights remain prerequisites for real identities; fictional content supports development in the meantime.

### Collections that matter without mandatory links

Collections can celebrate a tournament era, role, map affinity, club, or commemorative edition. Completing a set awards a cosmetic club item, a nontradable choice reward, or a pack—not a permanent combat boost that forces everyone to collect the same set. Early milestones should reward partial progress, such as three, six, and ten distinct identities.

Collection challenges should use a **show or loan** pattern by default: register eligible owned cards, play a themed fixture, and retain them. Any optional sacrifice challenge must state exactly what is destroyed and show its full reward before confirmation. No essential tactic or player identity is permanently available only by sacrificing a rare card.

## 06 · Squad construction: make a cheaper card useful

Automatic roles create a valid baseline. Experts can assign separate T-side and CT-side duties: entry/second entry, support, lurk, IGL, AWPer, anchor, and rotator. Five slots do not mean exactly one of five rigid roles. A double-rifle setup, secondary AWPer, or flexible caller is legal when the plan and equipment can support it. The interface warns about uncovered jobs rather than silently forbidding every unconventional five.

Assign one lead caller per side. IGL is a leadership duty that can overlap an armed role; carrying an AWP is an equipment decision, not a mandatory sixth job. Map-specific assignments should expose what a player is being asked to do before a newcomer replaces them.

### Ranked roster selection budget — new recommendation

Start Club Divisions testing at a **100-point squad budget**. A server-authored selection cost describes the card's effective capabilities, including advanced sniping, traits, permanent mods, and unusually favorable distributions. Costs are not simply rarity labels or a sum of the eight face stats. The budget is an eligibility rule, not a coefficient added to the simulator.

Illustrative construction: a 34-point star, a 20-point caller, an 18-point support, a 15-point entry, and a 13-point anchor total 100. Replacing the anchor with a 27-point all-rounder requires another tradeoff. These are example costs, not assessed ratings of any named player.

A useful lower-rarity card therefore has a job: leave room for an expensive AWPer, provide dependable utility, fit the playbook, or hold a site efficiently. A player can be collectible and desirable even when their rarity is common. The uncapped circuit still allows the fantasy of eventually fielding five exceptional players.

Budget values and mod effects are disclosed before commitment. A workshop preview shows both tactical and eligibility consequences. Competitive updates must offer respec relief if a balance patch makes a saved squad ineligible; a match already started retains its version. Do not add both a tight rarity cap and a tight stat cap on top without evidence that another restriction helps.

Matchmaking primarily uses manager skill and division. The budget constrains team construction; it does not replace skill rating. Exact costs, variance treatment, specialist efficiency, and the 100-point threshold require simulation and player testing. A single universal cost formula should not be frozen before the causal engine can measure those capabilities.

## 07 · Chemistry that supports a collection game

**Recommended change:** retire the old delayed substitution penalties and personality-only hidden chemistry ceiling. Those rules can make a good pack pull feel like three matches of punishment and can strand an invested squad against an unknowable ceiling. Keep hidden behavioral tendencies, but move chemistry toward visible preparation and remembered partnerships.

### Proposed model

Display **cohesion = 65% shared familiarity + 35% tactical fit**, on a 0–100 presentation scale. These weights are playtest candidates. Familiarity is the mean of the ten player-pair bonds in the active five. Tactical fit summarizes assigned duties, the selected playbook, and observed comfort with the coaching style. The UI breaks these components out and recommends an action instead of a mysterious grade.

Pair familiarity belongs to the club and the pair of base player identities, not the printing. A new edition of the same professional retains the club's learned partnership; its particular roll and behavioral tendencies can still change fit. Selling a card does not transfer the seller's club relationships. New pairs begin at a competent baseline of 40. A proposed eligible-match update is `F_next = F + 6 × (1 − F/100)`, with bounded gains and no passive offline decay. Focused practice can provide a small, capped preparation contribution.

Example: ten established pair bonds at 80 give familiarity 80. Replacing one professional creates four new bonds at 40 and preserves six at 80, producing familiarity 64. With unchanged tactical fit, displayed cohesion falls by about 10.4 points—not a delayed 30-point cliff. Three eligible shared matches lift the new pairs to about 50.2. Restoring the previous lineup restores its remembered bonds. Editing a lineup screen creates no extra penalty; the roster snapshot is evaluated once at match entry.

Cohesion influences communication delay, synchronized utility, trade readiness, and consistency of coordinated actions. It does not add invisible Aim or predetermine a winner. A more suitable replacement can help immediately despite reduced familiarity. There is no global same-club/nationality stat-link requirement.

### Keep the discovery in behavioral fit

Keep Alpha/Bravo/Charlie as hidden, permanent backend tendencies if they produce distinct and testable choices. Never expose the labels or invent a match journal to imply evidence that was not simulated. Observations should describe the behavior, such as repeated conflicting rotation calls or strong follow-up trades, with context and uncertainty. Scouting and free trials let players investigate a fit problem without buying blind repeatedly.

The new recommendation removes a composition-only absolute ceiling, not personality or emergent friction. That is a deliberate change to v2.0. Personality should create an understandable coaching puzzle, not an unrecoverable secret roster defect.

## 08 · Development, Pubstompers, mods, and training

### Promotion and duplicate use

Keep the ordinary ladder and two new compatible mod sockets at each step:

| Promotion | Required PP for this step | Cumulative PP | Total unlocked sockets |
| --- | ---: | ---: | ---: |
| Initial T5 | — | 0 | 2 |
| T5 → T4 | 10 | 10 | 4 |
| T4 → T3 | 25 | 35 | 6 |
| T3 → T2 | 40 | 75 | 8 |
| T2 → T1 | 55 | 130 | 10 |

Same-professional duplicate values remain: Floor 1, Common 1, Uncommon 2, Semi-Rare 3, Rare 3, Legendary 4, Peak 5, Divine 6 PP. The target card survives and its natural roll stays unchanged. A lower-tier mod can use a higher-tier socket; the reverse is invalid. Investments in a sacrificed card do not increase its PP value. Locking a favorite or active/queued card prevents accidental sacrifice.

**Add an earned path:** designate one active development-focus card before an eligible fixture. It earns one account-bound PP of progress toward its current promotion step after a qualifying appearance in the locked starting roster. Benched cards and parallel queues do not gain extra focus progress. Duplicate sacrifices accelerate that same step. On this candidate rate, the first promotion is reachable in ten qualifying appearances without purchasing duplicates; T1 remains a longer-term goal. Eligibility and the rate are tuning values. This broadens the old duplicate-only rule and must be measured alongside supply.

Overpayment from a sacrifice does not roll into the next step. The interface recommends a low-waste combination and discloses the small credit refund before confirmation. Earned focus progress stops at a completed step until the player confirms promotion, so ordinary play does not accidentally overflow it. No universal transferable PP currency is introduced.

### Pubstompers should be a credible career choice

Retain naming, custom presentation, role assignment, separate character IDs, and the ability to turn a new Pubstomper pull into a new character or development material. Give their initial profiles viable low-budget roles. Keep immutable base profiles after creation; progression develops options and identity rather than repeatedly rerolling an academy player.

**Retire the 10× promotion requirement** in favor of the ordinary 10/25/40/55 schedule, earned focus progression, and academy-specific achievements. The tenfold grind conflicts with attachment to the four starter characters. In the initial online release, keep Pubstomper characters account-bound while the naming, moderation, and identity-transfer rules are resolved. Preserve trophies, appearances, cosmetics, and named-character history.

For an initial material rule, an unassigned Pubstomper prospect can become one new character or one bound PP for an existing Pubstomper. Once created, a named character is not automatically generic fodder for another character. This conversion is new candidate tuning, not a claim that v2.0 specified it.

### Permanent mods are a build system

Keep tier compatibility, individual attachments, transparent positive/negative deltas, and the ability to trade eligible developed professional cards with their attached mods. For the initial design, the same mod family cannot stack on one player; cap the combined positive mod delta at +12 per visible attribute for testing. This is a mod-effect cap, not a cap on the underlying natural stat. Budget costing must include the effective build and relevant special effects.

Recommend free workshop previews and unlimited practice trials before committing. Replacing a mod destroys that attachment and refunds a disclosed portion of its release value in Credits; it does not magically return a full-value duplicate to inventory. Preview and confirm destruction. During queueing or an active match, all attachments are locked.

**Remove the 10-match/10-hour application cooldown** in the recommended baseline. The opportunity cost of the mod, tier sockets, replacement loss, and ranked budget already constrain builds. A cooldown on top discourages trying the new card just opened. If rapid opponent-specific refitting becomes a problem, solve it through pre-queue snapshots and information timing rather than forcing a ten-hour wait.

### Training prepares a team

Replace expiring stat consumables with a free three-eligible-match coaching plan: rehearse the execute, improve trade spacing, or integrate a new role. It develops familiarity and observable execution within the players' existing capabilities; it does not rewrite natural stats or sell a temporary ranked Aim boost. Time away does not consume the plan. The choice of a focus is the management decision, not remembering to refresh a timer.

## 09 · Pack products, odds, and sealed ownership

Packs must feel like real collectible items. They have wrappers, stock quantities, immutable definitions, edition/source metadata, and a visible decision to open, keep, or list an eligible sealed pack. Buying does not auto-open. No separate key is required.

### Three clear product families — candidate launch economy

| Family | Candidate price | Contents | Reason to choose it |
| --- | ---: | --- | --- |
| Map Scout | 100 CR | 1 player + 2 mods | Low-cost map collection and workshop development |
| Squad | 400 CR | 5 players; fifth guaranteed Rare+ | The main roster-discovery and reward pack |
| Spotlight | 1,000 CR | 5 players; fifth guaranteed Legendary+ in its advertised role | A focused club goal with a larger reveal |

These prices are paper-test values, not live offers. Keep several map collections behind the Map Scout family over time, with overlapping professional pools. Recommend three visible product families at initial release rather than requiring the old seven-offer 3/3/1 shelf on day one. Collections expand content; players should not have to decipher seven nearly identical prices during onboarding.

Spotlight's role is fixed and visible on the sealed item when acquired; it cannot be secretly changed by the opener or seller. The first four players use the versioned series pool, while the fifth uses the stated eligible role pool. Identity duplicates remain possible and must be disclosed. Welcome and event packs have their own explicitly defined contents.

### Candidate player-slot odds

All entries are percentages. These tables are a proposed simulation sandbox, not previously approved odds.

| Player slot | Floor | Common | Uncommon | Semi-Rare | Rare | Legendary | Peak | Divine |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Map Scout player | 0 | 60 | 26 | 10 | 3.70 | 0.29 | 0.01 | 0 |
| Squad players 1–4 | 0 | 45 | 30 | 18 | 6.50 | 0.45 | 0.05 | 0 |
| Squad player 5 | 0 | 0 | 0 | 0 | 95 | 4.90 | 0.10 | 0 |
| Spotlight players 1–4 | 0 | 0 | 25 | 40 | 30 | 4.90 | 0.10 | 0 |
| Spotlight player 5 | 0 | 0 | 0 | 0 | 0 | 99.90 | 0.10 | 0 |

Each row sums to 100%. Under independent slots, the chance of at least one Peak is 0.01% in Map Scout, approximately 0.2997% in Squad, and approximately 0.4990% in Spotlight. Define both per-slot and per-pack odds; do not conflate them. These ordinary-pack Peak chances stay within the old 0.001%–0.50% range. The explicitly guaranteed welcome Peak is a separate exception.

For the Map Scout's two mod slots, a starting proposal is independent rarity weights Common 70%, Uncommon 25%, Semi-Rare 4%, Rare 1%, and independent tier weights T5 80%, T4 18%, T3 2%. All other rarities/tiers are zero in that ordinary table. Every nonzero tier/rarity cell must have eligible authored mods; otherwise the table is invalid and cannot ship. Higher-tier mods can enter through disclosed career, workshop, or event rewards. Slot category, mod tier, and rarity must be shown separately.

After selecting rarity, select from the versioned eligible identity/definition pool using published weights, then generate the instance within the template's permitted distribution. Initial testing can use uniform weights within each eligible pool; featured exceptions require disclosure. No personalized odds, outcome reroll after a failed connection, or hidden win-streak bonus is recommended.

### The opening sequence

Show the wrapper and guarantee; let the player tear it; stage the card backs; reveal identity, role, rarity and instance; make a notable pull feel special; then compare its actual squad role. Allow reveal-all, reduced motion, and a quick summary. Avoid a near-miss reel implying that the next adjacent rarity was almost won.

Opening is one server transaction: consume the sealed item, resolve all results, mint exact instances, and save an opening receipt before animation. A disconnect resumes the same result. The collection inventory and the presentation cannot independently grant rewards.

“NEW” means a newly collected identity/edition, while “NEW ROLL” identifies another distinct instance of a known professional. The summary explains why the latter can still matter: better utility, a cheaper build, a different behavior profile, or promotion/trade value. A duplicate of a favorite is not simply failed filler.

## 10 · Rewards and a route to a wanted player

Keep one account **Credits** wallet, clearly separate from match equipment dollars. Avoid introducing a premium gem, energy, pack key, and crafting coin alongside it. Nontransferable development progress and objective counters are progress records, not exchangeable currencies.

### Candidate recurring rewards

| Eligible event | Credits | Other progress |
| --- | ---: | --- |
| Completed qualifying match | 100 | Club XP, focus PP, and shared familiarity |
| Victory | +60 | Additional XP and competition progress |
| Every fourth qualifying match | — | One Squad pack |
| Every twelfth qualifying match | — | One Spotlight pack in addition to the fourth-match Squad |
| Club objective path | Defined before play | A player-choice reward, mod, cosmetic, or pack |

At these candidate rates a Squad costs 2.5 wins or four completed losses before milestone packs. That is deliberately accessible for a generous test; no production inflation claim follows from it. Reward value, market supply, and time-to-target must be simulated together. Direct kill/ADR credit bonuses are avoided so players are not paid to abandon support or farm easy kills.

A chosen **scouting objective** supplies an alternative to luck. For example, complete a short role-themed sequence and choose a Rare support from a small disclosed pool. Track the objective without a separate currency. Broad player identities and essential tactics remain earnable again after an event; an original edition can retain its stamp and appearance without keeping an exclusive permanent match advantage.

Eligible economic matches require server-validated participants, rules, and completion. Ranked fixtures and designated career fixtures advance the normal track. Private customs, replay viewing, workshop trials, and unlimited scrims do not mint ordinary economic rewards. Story/career first-clear bonuses are once per account; repeatable reward fixtures are explicitly marked and bounded. Practice can contribute capped preparation without becoming a credit printer. These distinctions must be visible before entry.

Duplicates have four clear uses: keep another build, develop the same professional, trade/list an eligible instance, or release for a posted value. Release returns and replacement refunds must remain below expected pack acquisition value after all outputs and fees; jackpot results can individually be worth more. Validate this by pack and by closed conversion cycle before enabling a live economy. No specific release schedule is locked in this document.

## 11 · Archive packs, events, and the market

Retain original editions, limited event presentation, free challenge rewards, and return paths for gameplay-relevant content. A collection's edition and acquisition provenance should be valuable to collectors without implying that an identical reissue is counterfeit or competitively inferior.

**Artifact:** one collectible from an eligible retired source. Choose the inactive source first, then one item from its published eligible-item distribution. There is no rarity floor; a Common or an explicitly eligible Floor/mod output is possible. This is an archive-collection product, not the recommended way to improve a starting squad.

**Shiny Artifact:** one Rare-or-better item. Choose among published sources with eligible Rare+ outputs, then sample within that source's conditional Rare+ table. Publish source-selection weights and resulting item/rarity odds. This rule must not silently resample until it finds a favorite source.

Keep the old price relationships: if the highest ordinary pack is P, Artifact is 1.10P and Shiny Artifact is 1.45 × Artifact = 1.595P. At the proposed P = 1,000 CR, those prices are **1,100 CR** and **1,595 CR**. Approximately six weeks after retirement remains a candidate archive-eligibility delay, not an approved lock.

Artifact openings carry the A acquisition-origin mark. Opening a genuinely original sealed event pack months later retains its original edition without adding an Artifact mark. “Shiny” denotes a disclosed pack/guarantee class; a foil appearance, rarity, source edition, and provenance are separate fields. Event Shiny packs retain at least one Rare+ guarantee, with their exact item categories and enhanced odds defined per product before issue.

### Market sequence

Start online commerce with fixed-price eligible-card and sealed-pack listings plus secure direct trades. Add auctions only after ownership locking, settlement, and pricing behavior are reliable. A seller transfers the exact instance and its visible build/history, not a generic portrait. Applied mods travel with a developed card unless an explicit, separately confirmed workshop transaction changed them first.

The inspector discloses natural/effective stats, tier and sockets, attachments, edition/provenance, eligibility, and verified observations. It never displays backend behavioral labels or treats a seller's description as verified fact. Queue-locked, listed, account-bound, and development-locked cards cannot be transferred or sacrificed concurrently.

A candidate 5% seller fee provides a measurable sink; it remains provisional. Direct trades must preview exact outgoing/incoming item IDs and any Credits, require both confirmations, lock assets, and settle once. The fee policy for direct trades requires separate testing to avoid an obvious free substitute for every listing. No cash-out has been approved.

**Monetization recommendation:** test the full loop with earned Credits only; for a commercial baseline, prefer cosmetics, club presentation, and a pass without exclusive competitive power. Paid Credits and randomized tradable packs were a v2.0 locked intent, but are not inherited as an approved requirement of this optimized recommendation. If retained later, the paid-credits route needs an explicit product/fairness decision and applicable platform/region review. Do not promise “no pay-to-win” while money directly purchases scarce stronger inventory.

## 12 · Coaching: a few decisions with visible consequences

Auto Coaching is the normal way to play. It uses the chosen lineup, side roles, playbook, economy policy, and IGL tendencies. Manual Coaching changes authorized decisions; it does not add an accuracy bonus or let the customer aim a weapon. Both use the same engine.

Before a match, choose a small prepared playbook: a default, one rehearsed execute, an alternative route/fake, and a defensive/retake plan. Full control of every grenade lineup is optional depth, not a prerequisite. The old **Playbook ↔ Midrounding** slider remains, with readable presets such as Structured, Adaptive, and Freeform. Moving it changes decision preferences, timing tolerances, and player autonomy rather than adding a round-win percentage.

### Strategy cards and Coach Level

Core actions must be freely available early: a default, viable site takes, defensive holds, a retake, and an economy save. Club XP raises **Coach Level**, unlocking a recommended progression of nontradable preparation options without hidden combat bonuses. An eligible tradable strategy-card subset offers alternative policies and execution patterns through drops, objectives, events, or the market. Owning a card enables a reusable plan; playing it does not consume a new copy every round. Do not sell the only answer to a common tactical problem.

An execute is a policy for legal routes, staging, available grenades, angle clearing, and reassessment under delivered information. It is never “A execute: +10% win chance.” Strategy asset/definition versions are recorded in the match snapshot; a queued or listed asset cannot simultaneously change ownership in a way that invalidates the match.

During MR12, retain three tactical pauses per team plus calls at rounds 1 and 13. During MR8, retain one tactical pause without automatic half-start calls. A candidate pause lasts at most 20 real seconds, consumes no match time, and has a visible shared clock; tune its duration. Permitted changes are next-round plan, pace, buy/save priority, pressure lane, and eligible in-game role duties. Cards, mods, rarity, and natural stats cannot change mid-match. Unused input falls back to Auto Coaching.

Recommend that a pause request during a live round takes effect at the next legal freeze/buy boundary, rather than freezing a bullet in flight. Half-start calls are separate from the three tactical-pause allowance. This resolves timing as a candidate rule for testing; both participants see the same authorization and clock.

The manager acts through **observe → hypothesize → call → see the effect**. If repeated dry entries fail, call for staged utility and closer trade spacing. The engine should show teammates arriving in time and real flashes changing contact—not a canned success message. A perfectly reasonable call can still fail, and the review distinguishes a bad idea, bad information, and failed execution.

## 13 · CS-style simulation and match formats

Retain MR12 standard and MR8 quick formats. For this recommendation, test MR3 overtime after tied regulation, with full-bank overtime rules explicitly versioned. Ranked simulations should complete a real tiebreak rather than silently substituting the prototype's one-round cap; a pathological runtime limit is an operational exception with a disclosed retry/no-contest policy, not a fabricated winner. Tournament variations publish their rules before entry.

The result must follow ten simulated agents with health, equipment, ammunition, position, perception, intent, and legal movement. Buy, setup, information, contest, execute, plant, post-plant, retake, save, and settlement are stateful intentions. A teammate can only act on acquired or communicated evidence, with delay and uncertainty. Omniscient spectator information is not delivered to the agents or exposed as a live coaching advantage.

**Physical control** is what can actually be occupied safely. **Information control** is what a team believes it knows. **Threat control** is space an enemy cannot enter safely. A strong support card matters when those distinctions cause better trades, safer entries, denied rotations, or a timely save.

### Causal capability requirements

| System | Required behavior |
| --- | --- |
| Movement and 3D geometry | Legal connected routes, player clearance, stairs/ramps, distinct elevations; no corrective teleports across floors |
| Combat | Actual LOS or justified material-aware penetration; Aim/Reaction execute an opportunity, Positioning helps create it |
| Team attack | Staged utility, staggered trade spacing, sensible bomb-carrier position, angle clearing |
| Commitment | A genuine site breach leads to clear/plant/hold/recovery; retreat needs an explicit reason, not route oscillation |
| Information | Own observations and delivered reports; no tracking hidden enemies through walls |
| Utility | Purchased inventory, flight/collision, detonation, actual smoke/fire/flash effects, missed lineups |
| Objective | Legal plant volume and true bomb coordinates; physical defuse, kits, time, and post-plant coverage |
| Equipment economy | Per-player wallets, prices, buy policies, rewards, saved gear, legal drops, and halftime resets |

Use an authoritative 3D world and a readable overhead tactical presentation. A graph can support navigation/planning, but a radar image cannot decide vertical collision or bullet visibility. Dust II remains a desired reference/map subject to obtaining the actual assets and appropriate rights. One trustworthy map is a better first deliverable than several decorative maps with unreliable routes.

Retain the eventual full armory scope from v2.0. Validate a representative pistol/SMG/rifle/AWP plus armor, kits, and grenade set before expanding the first causal slice to every weapon. Weapon prices, damage, ammunition, fire rates, and payouts live in a versioned rules dataset. Match dollars remain separate from persistent Credits. Buy/save decisions, recovered equipment, and won objectives must settle exactly once.

Keep the specific legacy regression contracts: no Mid-to-Cat floor jumps, no false open B walls, no routine retreat from a secured B site, legal long-range sniper LOS without an arbitrary universal range cutoff, fire escape attempts, non-omniscient blind spray, inventory-bound utility, and the documented 1 HP direct-flash contact rule. Full implementation details remain in the preserved v2.0 reference; the new design does not declare the old spatial experiments validated.

## 14 · Watching, learning, and player attachment

The default spectator presents the radar, score, team equipment state, round time, living players, and a restrained feed of eliminations, completed plants, and defuses. Detailed play-by-play, utility trajectories, impacts, and tactical overlays are optional. A top-down view can communicate a true 3D world without an expensive first-person broadcast.

Live coaching views show the team's legal knowledge. An omniscient broadcast must be delayed or reserved for completed rounds/replays when it could reveal information to a manager. Live matches share one server-authorized accelerated clock; instant/fast-forward viewing applies to already determined auto fixtures or replays, not unrevealed future manual decisions.

The post-match screen leads with the score, rewards, one standout contribution, and **one useful coaching lesson**. A player can inspect the evidence: a missed trade window, an underfunded retake, a rotation based on weak contact, or an execute whose utility arrived separately. Do not automatically blame chemistry or recommend buying a higher rarity whenever the team loses.

Impact Attribution stays event-based. One elimination has one shared contribution budget; a flash helper, killer, trader, and space creator do not each receive full independent kill credit. Effective damage is capped at HP actually removed; flash impact requires a verified blind; space impact requires a changed action or timing. A support can be valuable without topping kills. Performance Rating is separate from card ability and selection cost; v2.0's provisional weights require calibration before being treated as a competitive truth.

Exact card-instance history, club trophies, and named Pubstomper milestones create attachment. Compare performances by role and opportunity, with sample size visible. A limited preview or trial can reveal fit without exposing hidden archetype labels or secretly altering a card roll.

## 15 · Interface and presentation

Keep the current prototype's clear dark management desk, orange action color, restrained rarity accents, strong card frames, and physical-looking wrappers. Add information by progressive disclosure rather than turning every screen into a spreadsheet.

| Main destination | Primary decision |
| --- | --- |
| Clubhouse | What is my next fixture or objective? |
| Squad | Which five, which reserves, and which tactical jobs? |
| Pack Room | Open, keep, or trade this sealed pack? |
| Collection / Inspector | What makes this exact card useful or collectible? |
| Coach / Workshop | Which plan or build should I try? |
| Matchday | What am I seeing, and is a call worth making? |
| Transfer Hub | Is this exact instance worth buying, selling, or exchanging? |

The post-pack screen links directly to a compare-and-trial panel. The squad screen shows a budget meter, required tactical jobs, familiarity change, and both base/effective stats before a swap. The post-match screen returns to the same club goals. These transitions are more important than adding another shop tab.

Support reduced motion, reveal-all, written rarity/outcome labels, scalable text, and keyboard/controller navigation on PC. Mobile uses the same game rules with touch-friendly cards and collapsible inspectors. Design mobile layouts from the start; stage the native mobile release after PC game-flow validation rather than promising simultaneous feature parity before the loop is proven.

## 16 · Technical boundaries and ownership

Godot 4 remains the client and development environment. Keep catalog data, owned instances, team preparation, simulation, events, and presentation separate. First prove the full round in a headless engine test. A .NET server rewrite is a profiling/deployment choice, not a prerequisite invented to delay that proof.

The production trust boundary is server-side: accounts, inventories, pack receipts, credit ledger, market locks, roster eligibility, match choices, outcomes, rewards, and archives. Clients request permitted actions and animate accepted results. The local prototype's JSON is useful for offline iteration and cannot be treated as online ownership.

Match records include exact card IDs, effective loadouts, allowed coaching commands, map/rules/content versions, and deterministic random streams. Same snapshot + same command timing + same versions must replay the same ordered events. Live spectator speed and cosmetic animation never change the outcome.

Validate determinism on the supported authoritative runtime and its physics configuration. Clients replay accepted events; do not assume that unrelated platforms reproduce raw physics bit-for-bit from a seed alone.

Pack versions are immutable for minted sealed items. Transfer/open/consume operations are mutually exclusive, use idempotency keys, and create audit receipts. Credits require reconciled debits/credits and atomic settlement. Unknown network outcomes are resolved by reading the original operation, not resubmitting a fresh paid opening.

## 17 · Build order and evidence gates

Do not treat the entire game as a launch-sized checklist. Build a loop that proves collection decisions matter in a trustworthy match, then add breadth.

| Stage | Deliverable | Evidence needed to continue |
| --- | --- | --- |
| 1. Reconciled design | This master, decision log, preserved prototype spec, and source reference | Clear target/prototype distinction; proposed legacy changes identified |
| 2. Causal tactical slice | One 3D map/greybox, ten agents, legal combat, bought utility, bomb and economy | Seeded full rounds and MR8; route/LOS/objective tests; no invented killfeed |
| 3. Connected club slice | Exact card instances, 5+2 squad, starter flow, three pack families, compare/trial, focus development | A new pull changes an actual tactical capability and remains useful after restart |
| 4. Career and balance alpha | Short AI circuit, cohesion, role costs, budget competition tests, objective rewards | Players can explain losses, use cheaper specialists, and progress without required purchases |
| 5. Online club competition | Authoritative accounts, inventory, one ranked queue, coaching calls, opt-in snapshots | Replay determinism, no duplicate grants, stable matches and reconnection |
| 6. Market and live content | Fixed listings, direct trade, sealed packs, later auctions and archive products | Atomic ownership/credit settlement; published valid pools; no profitable mint loops |
| 7. Release depth | Expanded maps/content, native mobile, audio/pack polish, distribution and commercial decisions | Hardware/platform tests, rights readiness, economic evidence, and accessible playtests |

Stage 3 can use UI tools from the current prototype, but the ranked balance and post-match explanations cannot be validated using its current aggregate simulator. The 3D source assets described in the old GDD need to be obtained and inspected before any migration can be claimed. Until then, an original greybox is a valid development testbed.

## 18 · Test the fun, not only the feature count

Run a first moderated test with roughly 8–12 players spanning CS enthusiasts, sports-card collectors, and less-experienced managers. These are recruitment suggestions, not completed research. Use the same resources and candidate pools; include both a star pull and a useful low-rarity specialist.

| Question | Observable evidence |
| --- | --- |
| Does opening connect to management? | Player compares or trials a pull and can explain its intended job |
| Is a good pull exciting rather than disruptive? | Player willingly tries a newcomer without fearing an unexplained chemistry collapse |
| Do players care about their club? | They remember a Pubstomper or specific card's contribution and make a deliberate keep/sell decision |
| Is the simulation readable? | After a loss they identify an evidence-supported adjustment besides buying a stronger card |
| Can cheaper cards matter? | Budget-constrained teams retain specialists for a reason, and several viable builds appear |
| Are duplicates useful? | Player understands a development, alternate-build, trade, or release route without prompting |
| Is the return goal clear? | At session end they name a wanted role, player, build, or club milestone |

Record first-use timing, compare/trial rate after a pack, roster diversity, tactical changes, frustration with unfamiliarity, progression rate, and reward/value confusion. Treat win-rate targets as experiments by equal budget, manager skill, and preparation. Neither a few anecdotes nor the prototype's current star-heavy win rates establishes balance.

Engineering gates remain mandatory: Godot import/runtime tests, identity legality across editions, promotion invariants, nonzero drop-pool validation, probability normalization, no double minting, trade atomicity, seeded replay, legal navigation/LOS, no opponent knowledge leaks, inventory-bound utility, causal attribution, and isolation of unrewarded scrims.

## 19 · Decision summary and boundaries

| Topic | Recommended disposition |
| --- | --- |
| Five active players, unique identities, eight attributes, eight rarities, separate tiers | Carry forward |
| Pubstompers, selected Common starter, guaranteed Peak gift | Carry forward; fill gift extras and bind starter value |
| True 3D authority, readable top-down spectator, causal events, Impact Attribution | Carry forward as target; do not mislabel current implementation |
| Severe substitution depreciation and hidden composition-only ceiling | Replace with remembered pair familiarity, visible tactical fit, and actionable observations |
| Duplicate-only promotion and Pubstomper 10× cost | Add earned focus PP; remove the Pubstomper multiplier |
| Ten-match/ten-hour mod cooldown and two-hour training expiry | Replace with queue locks, preview/commit costs, and match-based preparation |
| Standard 1-player/2-mod packs and seven-offer shelf | Keep Map Scout contents; add five-player families and simplify the initial shelf |
| Market, sealed packs, archive provenance, exact Artifact price ratios | Carry forward; stage auctions and archive products after supply/settlement proof |
| Paid Credits financing randomized tradable packs | Do not assume approval; recommend earned-only testing and cosmetics-led commercial evaluation |
| PC and mobile | Retain target platforms; recommend staged PC validation and mobile delivery |

Before implementation, confirm the high-impact product choices in this register through normal design review; this document itself makes them concrete and reviewable. That does not block prototype experiments within the user's chosen scope. Candidate numbers are tunable; no unpublished numerical Divine odds, licensed roster, source-map ownership, production backend, or approval of new monetization is inferred.

## Appendix A · One connected example

A manager loses a match because the entry pair keeps arriving separately. The review points to three real untraded deaths and one useful smoke that arrived too late. Instead of merely asking for a higher overall rating, the player chooses to rehearse trade spacing and sets a scouting objective for a reliable support.

The next Squad pack reveals a Rare support with high Teamwork and Utility but ordinary Aim. The card is cheaper than the existing all-rounder under the ranked budget. Comparing them shows reduced familiarity with two teammates, better playbook fit, and enough saved budget to keep the manager's favorite Peak AWPer. The player trials the change, keeps the old card on the bench, and chooses the new support for a circuit fixture.

During the match, the new support's purchased flash blinds an actual defender, the entry takes a legal duel, and the second player arrives in a real trade window. The objective is planted; the AWPer covers the remaining retake lane. They can still lose the round, but the difference is visible and attributable. The card's first useful contribution becomes part of its history.

Rewards advance the next pack and one promotion step. An extra instance of the former starter becomes a development choice or a market listing rather than a useless duplicate. The collector decision caused a management decision; the management decision changed the match; the match gave meaning to the collection.

## Appendix B · Sources and implementation status

Source 1: **ESPORTS: CSTCG Master GDD v2.0**, 26 pages, supplied PDF dated 2 November 2026. Key material: vision/onboarding pp. 3–5; instances/stats/development pp. 5–9; coaching/chemistry pp. 9–11; simulation/spatial/utility/economy pp. 11–17; packs/events/market pp. 17–19; architecture/QA/roadmap/decisions pp. 19–26. The original PDF is preserved in `docs/reference/`.

Source 2: **Club Circuit prototype GDD v0.1**, `docs/GAME_DESIGN.md`, plus the existing Godot source. It contributes the usable pack-room presentation, five-card reveal, clear six-screen management loop, immediate squad comparison, local save/reveal transaction behavior, and tested prototype workflow. Its four-rarity fixed-card model and aggregate probability simulator are not adopted as final production rules.

This turn creates design documents and exports. It does not implement the new instance model, budget rules, chemistry, career, market, or 3D simulator. Existing game behavior and saved clubs remain unchanged. See `docs/DESIGN_MERGE_NOTES.md` for the explicit source-to-recommendation decisions.
