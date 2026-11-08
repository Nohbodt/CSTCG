# Player portraits

Alpha 0.6 includes **25 source-based, AI-edited transparent PNG headshots** with plain jerseys. Common uses graphite, Rare cobalt blue, Epic violet and Legendary champagne. [SOURCES.md](SOURCES.md) and [portrait_sources.json](portrait_sources.json) retain pinned source URLs, original credits, source hashes, edited hashes and edit notes. These outputs are image edits, not unchanged photographs or pixel-identical reproductions.

The five cards without an accepted source photo are **syrsoN, RUSH, ALEX (Alex McMeekin), interz and F1KU**. They retain monograms. A source for a different professional named alex was excluded.

The renderer prefers canonical `player_id.png`, then `.webp`, then `.jpg`. Older saved fixtures requesting JPEGs still find the current PNG without a save migration. The image resource stays referenced while its card is drawn or captured into a 3D print. Transparent portraits are fitted into the frame without clipping the top of the hair. Names and numbers are separate live text layers, and the foil shader protects the portrait rectangle.

The full image-editing outputs are preserved as PNGs. Godot imports at up to 768px with mipmaps for the 2D cards and 3D inspection. The per-file manifest distinguishes source hashes from installed artwork. Future revisions should use the original reference photo, retain identity and hair, use the same plain color per rarity, and review the output and alpha edges before replacing it. Use the image-editing tool rather than inventing a different face. Update source/edit notes and hashes together.

Direct-source preparation remains available through `python3 tools/fetch_hltv_portraits.py --list`. Its nickname checks and raw-file isolation still apply. The installed portraits require no network access during play.
