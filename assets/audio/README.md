# Original collectible sound effects

These short sounds are synthesized by `python3 tools/generate_pack_audio.py`, using deterministic noise and oscillators from Python's standard library. No external samples are used. They are 16-bit mono PCM at 22,050 Hz.

- `pack_tear.wav`: sustained foil rustle, timed to the slow tear by playback pitch.
- `elite_charge.wav`: a restrained three-note anticipation charge.
- `pack_burst.wav`: foil crack, short low impact and a sparkling release.
- `elite_burst.wav`: the release with an additional resonant finish.
- `card_reveal.wav`: short contact click and decaying tone.

Playback is attached to the collectible stage, stops when the stage closes, and can be disabled in Help & settings. Game playback uses a lower volume than the source files. These are project assets; this file does not choose a license for the repository.
