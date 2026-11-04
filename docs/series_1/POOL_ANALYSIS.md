# Series 1 — pool and odds validation

Generated analytically from `series1_manifest.json`; percentages refer to exact collectible designs unless stated otherwise. Repeated results are allowed.

| Product | Pool | Opening | Common | Uncommon | Semi-Rare | Rare | Legendary | Peak | At least one Peak | Expected release |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Alpha | 50 | 3 | 15 | 5 | 10 | 10 | 5 | 5 | 0.199875% | 37.1500 CR |
| Bravo | 50 | 3 | 15 | 5 | 10 | 10 | 5 | 5 | 0.199875% | 37.1500 CR |
| Elite | 50 | 5 | 0 | 10 | 10 | 10 | 10 | 10 | 0.499001% | 136.6250 CR |
| Beta Event | 50 | 5 | 5 | 5 | 10 | 10 | 10 | 10 | 0.299650% | 51.4250 CR |

Each pack contains ten eligible designs for each of the five assigned roles. Every definition is reachable under a nonzero slot distribution. Each slot sums to exactly 10,000 basis points. Across four pools there are 200 memberships and 90 unique designs.

## Exact pool overlap

| Pool | Alpha | Bravo | Elite | Beta Event |
| --- | ---: | ---: | ---: | ---: |
| Alpha | 50 | 40 | 35 | 28 |
| Bravo | 40 | 50 | 35 | 27 |
| Elite | 35 | 35 | 50 | 25 |
| Beta Event | 28 | 27 | 25 | 50 |

Alpha and Bravo have identical slot odds, prices and rarity counts. Their twenty total pool-exclusive definitions contain five Common and five Uncommon cards per product. Neither product is a power tier above the other.

## Reading individual odds

For slot s and exact design c, P(c,s) = rarity_weight(s,c.rarity) / eligible_design_count(s,c.rarity). A finish-filtered guaranteed slot only counts eligible editions in that finish. The chance of at least one copy in the opening is 1 − product_s(1 − P(c,s)). Expected copies is sum_s P(c,s).

Two editions of one player are separate collectible results, so that player's combined identity odds can exceed the odds of a single design. Per-design opening probabilities need not sum to 100%; expected-copy counts sum to the opening size. `pack_pools.csv` lists both values for every one of the 200 memberships.

## Supply and release limits

Release candidates are Common 4, Uncommon 6, Semi-Rare 10, Rare 20, Legendary 75 and Peak 200 Credits. Finish adds no release multiplier. The expected direct release return is below every proposed purchasable pack price; this is a narrow direct-buy/release check, not a full market, promotion or live-economy proof. Beta Event is an earned reward with no ordinary purchase loop. Credit prices, target reward rates and release values remain playtest candidates.

No empty weighted pool, unreachable advertised card, repeated definition inside a product pool, per-product role imbalance, attribute mismatch between finishes, or nonunit slot table was found.
