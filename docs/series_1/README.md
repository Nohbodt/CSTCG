# CSTCG Series 1 design kit

Start with **index.html** in a desktop browser. Keep its `art` and `vectors` folders beside it. The catalogue works offline, lets you choose any of the four 50-card pools, filter/sort the cards, and inspect every card's eight attributes and production brief.

The pack/card art boards are generated visual references. All 90 definitions have accurate vector layout proofs and specific art instructions; this kit does not contain ninety completed portrait paintings. The current playable game remains alpha 0.2. Game integration and production portraits are the next implementation work.

## Files

| File | Use |
| --- | --- |
| `CSTCG_Series_1_Design_Lookbook.pdf` | 51-page printable lookbook, including all 90 card entries |
| `DESIGN_SPEC.md` | Complete product, card, rarity, opening and production specification |
| `CARD_DETAILS.md` | All individual card profiles and art briefs as editable text |
| `card_checklist.csv` | 90-row review spreadsheet, with eight attributes and card-specific design fields |
| `pack_pools.csv` | All 200 product memberships, plus exact per-design opening odds |
| `slot_odds.csv` | Every slot's rarity percentages and finish filter |
| `series1_manifest.json` | Structured release-content source of truth |
| `POOL_ANALYSIS.md` | Pool overlaps, probability method and direct release-value analysis |
| `vectors/cards/` | Ninety precise face-layout proofs with portrait-position guides |
| `vectors/packs/` | Four editable wrapper layout proofs |
| `vectors/inspection-example.svg` | Eight-attribute inspection reverse |
| `vectors/sealed-sleeve.svg` | Concealed opening cover shared by every card |
| `art/` | Full-resolution illustrated wrapper/card direction boards |
| `VALIDATION.md` | Completed content, PDF and browser checks |

If your browser blocks local files, start a local preview from this extracted folder with `python -m http.server 8766 --bind 127.0.0.1`, then open `http://127.0.0.1:8766/` on the same computer.

## Rebuild from the repository

The authoring source is `tools/build_series1_design.py`; the optional PDF renderer is `tools/series1_lookbook.py`. From the full CSTCG repository, run:

```bash
python3 tools/build_series1_design.py --pdf
```

The base exports use Python's standard library. PDF export also uses ReportLab and the repository's bundled fonts. Regeneration produces the manifest, spreadsheets, gallery, vector proofs and card register. CSV files are review exports; changes to them are not automatically imported back into the authoring source. Original art-board PNGs remain separate inputs.
