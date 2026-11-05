# Player portraits

Alpha 0.5.1 includes **25 temporary real-player photos**. The user requested available headshots now and a later art revision, so this pass preserves source photos, faces and jerseys without image edits. See [SOURCES.md](SOURCES.md) and [portrait_sources.json](portrait_sources.json) for pinned sources, original profile/image links and hashes. Photography rights remain with the original owners; an upstream code license is not treated as a photography license.

The five players without an accepted photo are **syrsoN, RUSH, ALEX (Alex McMeekin), interz and F1KU**. Their cards retain neutral monograms. A similarly named Spanish `alex` was excluded. The 24 WebP profile portraits were matched by handle, name and profile ID and visually reviewed. broky uses a temporary event JPEG.

The renderer tries canonical `player_id.png`, `player_id.webp`, then `player_id.jpg`, including for older saved fixtures whose requested path ends in `.jpg`. Files are bundled locally; play never downloads portraits. Replacing a photo does not change stats, card origin or ownership.

For the later art pass, preserve accurate faces and hair with plain charcoal, black, white or another flat jersey color without team/sponsor marks. Reviewed transparent PNG cutouts take precedence over temporary WebP/JPEGs. Use the image-editing tool, review identity and jersey cleanup, and update source/edit notes when installing replacements. These temporary files are not claimed to have completed that treatment.

`python3 tools/fetch_hltv_portraits.py --list` lists candidate direct HLTV profiles. A permitted fetch checks the returned nickname, stores raw images outside the game in `/workspace/portrait-sources/hltv/`, and records source hashes. Direct HLTV access remains unavailable in the current environment; it is not needed to use the installed local photos.
