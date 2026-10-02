# Beat UP! v17.3.7 — Song Library Info & Sorting Polish

## Song sorting
- Added `BPM Asc` and `BPM Desc` sort modes.
- `BPM Asc` is now the default Song Library sort.
- Existing Title, Star Rating, Best Rank, and Unplayed First modes remain available.

## Custom dropdown alignment
- Replaced the previous chevron glyph with a cleaner triangular chevron.
- Chevron now occupies a full-height right-side slot so it remains vertically centered across 30 px / 32 px dropdown variants.
- Open/closed chevron state remains cyan/pink.

## Song information hierarchy
- Re-enabled the BPM / Length / Notes quick-stat cards.
- Added restrained per-stat accents and stronger value typography.
- Simplified the chart descriptor line so it no longer duplicates BPM, duration, and note count.
- Difficulty color is now reflected directly in the selected chart descriptor.
- Progress / recommendation line spacing and hierarchy were refined.

## Personal record redesign
- Personal Best statistics now use three horizontal metric cards: Score, Accuracy, and Max Combo.
- Added stronger typography, subtle accent borders, and rank-based color emphasis.
- Judgement breakdown now uses full PERFECT / GREAT / GOOD / MISS labels.

## Song metadata cleanup
Manually normalized display title / artist metadata across all 25 songs. Key fixes include:
- Starting Over / Bow For Me / Flying Temple → Tricks & Traps
- Aresenes Bazaar → James Landino
- Bad Apple!! → Alstroemeria Records feat. nomico
- Beethoven Virus (Full Version) → Diana Boncheva feat. BanYa
- FREEDOM DiVE↓ → xi
- MEGALOVANIA → Toby Fox
- Existing new-song metadata was normalized to consistent display casing.

## Frozen systems
- Gameplay note events, timing, special notes, and difficulty data were not regenerated.
- Audio and song backgrounds were not modified.
- No `VALIDATION*.txt` files are included.
