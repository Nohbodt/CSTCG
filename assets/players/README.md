# Player portraits

The runtime loads a reviewed `player_id.png` here, with `player_id.jpg` as a legacy fallback. Transparent PNG cutouts are preferred. Keep faces, hair and identifying features accurate; use plain charcoal, black, white or another flat jersey color without team/sponsor marks. Portrait changes do not alter player stats or pack origin.

HLTV image sourcing was requested by the user. The current environment blocks HLTV network requests, so this change bundles no new photographic portraits. A configuration draft adds only `hltv.org`, `www.hltv.org` and `img-cdn.hltv.org`; it must be reviewed, saved and published in environment settings before downloads can run. This is an environment access limitation.

`python3 tools/fetch_hltv_portraits.py --list` lists candidate profile IDs/URLs. They are verified against the fetched nickname before an image is accepted. Fetching keeps raw photos outside the game in `/workspace/portrait-sources/hltv/`, records the source URLs and file hashes, and never automatically installs unedited jerseys into the runtime. Recheck source identity visually, edit jerseys with the image-editing tool, preserve the face, and review the result before installing a processed PNG here.

Use the same crop convention across players. Keep filenames keyed to canonical game IDs from `catalog.gd`, not handles or current team names. Retain source attribution and edit notes with any final installed assets. Until a reviewed file exists, the existing neutral monogram remains visible.
