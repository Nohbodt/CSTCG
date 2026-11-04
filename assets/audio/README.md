# Original collectible sound effects

These short sounds are synthesized by `python3 tools/generate_pack_audio.py`, using deterministic noise and oscillators from Python's standard library. No external samples are used. They are 16-bit mono PCM at 22,050 Hz.

- `pack_tear.wav`: brief foil rustle and rising sweep.
- `elite_charge.wav`: a restrained three-note charge with foil tear.
- `card_reveal.wav`: short contact click and decaying tone.

Playback is attached to the collectible stage, stops when the stage closes, and can be disabled in Help & settings. Game playback uses a lower volume than the source files. These are project assets; this file does not choose a license for the repository.
