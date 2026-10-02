# Beat UP!

# Complete Product, Gameplay, UX & Mockup Design Documentation

Document status: CANONICAL DESIGN BRIEF
Last consolidated: 21 September 2026
Audience: Codex / UI Designer / Product Designer / Game UI Developer
Product: Beat UP!
Engine: Godot 4.x
Platform: PC / Desktop
Primary orientation: Landscape 16:9
Primary design canvas: 1920 × 1080
Primary runtime reference: 1600 × 900
Secondary runtime reference: 1366 × 768

---

# 0. PURPOSE OF THIS DOCUMENT

This document is the source of truth for designing the current Beat UP! interface.

It exists so a design agent such as Codex can understand:

- what Beat UP! is;
- how the game works;
- which gameplay rules are already locked;
- which features exist;
- how the player moves through the game;
- what every screen is supposed to do;
- the visual direction;
- the current Album Flow redesign;
- the required design system;
- what must not be redesigned;
- what old concepts are deprecated;
- what mockups must be produced.

The immediate task after reading this document is:

CREATE A COMPLETE HIGH-FIDELITY MOCKUP SET.

Do NOT implement the mockups into Godot before the mockups are reviewed and approved.

---

# 1. SOURCE-OF-TRUTH RULE

Beat UP! has gone through many iterations.

Older:

- screenshots;
- v16/v17 layouts;
- changelogs;
- experiments;
- UI prototypes;
- implementation leftovers

may contain ideas that are no longer valid.

When an old document conflicts with this document:

THIS DOCUMENT WINS.

Unless the project owner explicitly states otherwise.

---

# 2. IMPORTANT SUPERSEDED CONCEPTS

These rules are especially important because older files may contradict them.

## Bomb Notes

Bomb has been removed entirely.

Do NOT include Bomb in:

- Gameplay;
- How to Play;
- Chart Studio;
- difficulty descriptions;
- note legends;
- tutorials;
- settings;
- mockups.

Normal, Reverse, and Space are the relevant note categories.

---

## Reverse Visual

Reverse is NOT a different note silhouette.

Reverse must use:

Normal note silhouette
+
red outer outline.

Do NOT create:

- a red inner diamond solely for Reverse;
- a completely different Reverse shape;
- a Reverse number label.

---

## Automatic Chart Generation

Player-facing Chart Studio exists.

Players can manually create charts.

However:

AUTOMATIC CHART GENERATION IS DEVELOPER-ONLY.

Player UI must NOT expose:

- Generate All;
- Quick Generate;
- AI Generate;
- Auto Chart;
- developer audio-analysis controls.

---

## Scroll / Note Speed

Player does NOT get an independent note-speed setting.

Note movement speed automatically follows song BPM using a capped readability curve.

Do not create:

- Note Speed slider;
- Scroll Speed slider;
- Approach Rate setting.

---

## Main Menu

Older concepts used:

- giant central diamond;
- BEAT UP! text inside diamond;
- top media-player bar;
- more osu!-literal compositions.

The current target is the newer Album Flow Figma direction:

LEFT:
brand + navigation

CENTER / RIGHT:
large square album artwork

RIGHT:
featured track metadata

BOTTOM:
Now Playing bar.

---

## Song Library

Older versions used:

- giant banners;
- large artwork backgrounds;
- expanded difficulty entries below the selected song;
- ranking/details-heavy UI.

Current target:

LEFT:
compact song browser

CENTER:
large square selected artwork + PLAY

RIGHT:
metadata + difficulty + Your Best + modifiers + Practice.

---

# 3. GAME OVERVIEW

Beat UP! is a PC rhythm game centered around directional keyboard input.

Its signature control scheme turns the numpad into an eight-direction rhythm instrument.

Canonical directional layout:

7 = ↖
8 = ↑
9 = ↗

4 = ←
5 = UNUSED
6 = →

1 = ↙
2 = ↓
3 = ↘

The player reads notes moving toward a hit zone and presses the corresponding direction in time with the music.

The experience should feel like:

music
→ musical phrase
→ direction
→ input
→ judgement
→ combo
→ score
→ mastery

The game is NOT centered around:

- characters;
- enemies;
- combat;
- HP;
- terrain;
- RPG progression;
- story battles.

Beat UP! is fundamentally a rhythm-performance game.

---

# 4. ONE-SENTENCE PRODUCT PITCH

A direction-based rhythm game where eight keyboard directions become an instrument, challenging players to read musical phrases, master directional patterns, and perform increasingly complex charts in sync with the music.

Short marketing identity:

EIGHT DIRECTIONS. ONE BEAT.

---

# 5. PLAYER FANTASY

At lower difficulty:

“I can read this song through directional patterns.”

At higher difficulty:

“I know this musical phrase, and my hands naturally perform the pattern.”

The game should avoid creating the feeling:

“I am pressing random arrows as quickly as possible.”

Charts must remain learnable.

---

# 6. DESIGN PILLARS

## 6.1 Music First

Music is the primary structural authority.

Charts should react to:

- phrase;
- section;
- rhythm;
- build-up;
- drop;
- chorus;
- climax;
- rest;
- transition;
- outro;
- musical accents.

Visual presentation should also reinforce the song.

Album artwork, track identity, audio continuity, transition, and selected-song state should remain connected.

---

## 6.2 Readable Directional Rhythm

Difficulty should not come from visual chaos.

Difficulty can come from:

- faster subdivision;
- longer patterns;
- diagonals;
- alternation;
- directional vocabulary;
- Reverse;
- Space;
- burst patterns;
- hand routing;
- memorization;
- musical phrasing.

Hard charts should be demanding.

Master charts should be very difficult.

But both should remain learnable.

---

## 6.3 Fast Session Flow

Ideal player loop:

Launch
↓
Main Menu
↓
Song Library
↓
Select Song / Difficulty / Modifier
↓
Play
↓
Gameplay
↓
Result
↓
Retry / Song Library

Avoid unnecessary friction.

---

## 6.4 Context Continuity

A song should feel like one persistent context.

Song Library
→ Song Launch
→ Gameplay
→ Pause
→ Result

should feel visually connected.

Do not repeatedly reset the user's sense of context.

---

## 6.5 Deterministic Skill

Normal / Hard / Master charts remain stable.

Random Mode changes direction mapping only.

Players should be able to learn charts.

---

# 7. PLATFORM & PRESENTATION TARGET

Primary platform:

PC / Desktop

Primary orientation:

16:9 landscape.

Reference design:

1920 × 1080.

Primary runtime test:

1600 × 900.

Minimum important laptop target:

1366 × 768.

The interface must not behave like a mobile UI stretched onto desktop.

---

# 8. CORE INPUT SYSTEM

## 8.1 Eight-Key Mode

Signature Beat UP! mode.

Directional mapping:

7 ↖
8 ↑
9 ↗
4 ←
6 →
1 ↙
2 ↓
3 ↘

KP5 is intentionally unused.

---

## 8.2 Four-Key Mode

Alternative input mode.

Uses:

←
↑
→
↓

The game projects existing chart direction logic into the four-key input system.

4-Key should feel like an alternate mode of the same game, not a separate game.

---

## 8.3 Key Remapping

Final professional interface should support remappable keys.

Settings mockups should account for this.

---

# 9. NOTE SYSTEM

# 9.1 Normal Notes

Basic directional notes.

Player:

reads the displayed direction
→ presses matching expected direction.

Visual:

- diamond-based;
- clean;
- blue identity;
- no numbers.

---

# 9.2 Diagonal Notes

Diagonal directions are still Normal-direction notes.

To improve recognition:

diagonal notes may use orange accents.

Recommended visual separation:

Cardinal:
blue

Diagonal:
orange

They should still clearly belong to the same note family.

---

# 9.3 Reverse Notes

Special directional mechanic.

Visual:

same basic Normal note silhouette.

Difference:

RED OUTER OUTLINE ONLY.

Recommended red:

#FF5A64

Do not alter silhouette simply because a note is Reverse.

---

## Reverse Logic

Runtime logic conceptually:

authored/projected direction
↓
Random transformation if enabled
↓
expected input determined
↓
Reverse changes displayed direction
↓
player still presses expected input

This ordering is important for deterministic behavior.

---

# 9.4 Space Notes

Special musical accent.

Input:

SPACEBAR

Visual:

gold diamond.

Recommended:

#F5C96A

Space can be more visually substantial than directional notes.

A filled or emphasized inner diamond is acceptable.

---

# 9.5 Bomb Notes

REMOVED.

Do not design them.

---

# 10. NOTE MOVEMENT

Beat UP! gameplay uses:

ONE HORIZONTAL LANE.

Notes travel:

RIGHT → LEFT.

Hit zone:

LEFT side.

The gameplay field is not a multi-column falling-note layout.

---

# 11. HIT ZONE

Primary hit receptor:

large white diamond.

Visual goals:

- instantly readable;
- higher visual priority than decorative background;
- subtle timing halo;
- responsive on judgement;
- no excessive glow.

Space can use a gold timing accent.

---

# 12. JUDGEMENTS

Judgement names:

PERFECT
GREAT
GOOD
MISS

Canonical semantic colors:

PERFECT:
pink / lilac

GREAT:
green

GOOD:
cyan

MISS:
red

Judgement should appear near the hit area.

It should not obstruct incoming notes.

---

# 13. TIMING WINDOWS

## Directional Notes

PERFECT <= 35 ms
GREAT   <= 60 ms
GOOD    <= 90 ms
MISS    > 90 ms

## Space Notes

PERFECT <= 60 ms
GREAT   <= 110 ms
GOOD    <= 170 ms
MISS    > 170 ms

Do not invent new timing windows in mockups.

---

# 14. ACCURACY SYSTEM

Judgement accuracy weights:

PERFECT = 1.00
GREAT   = 0.80
GOOD    = 0.50
MISS    = 0.00

---

# 15. RANK SYSTEM

Rank thresholds:

SS >= 98.5%
S  >= 95%
A  >= 88%
B  >= 78%
C  >= 65%
D  = below 65%

Result UI should make Rank one of the strongest visual elements.

---

# 16. SCORING

Current score scale supports million-level scores.

Maximum display score:

9,999,999

Strong complete runs may commonly land in roughly:

1–9 million.

Example display:

1,000,356

8,742,960

Do not mock up old tiny-score values such as:

52,300

unless a specific chart legitimately produces them.

---

# 17. COMBO

Combo is a secondary gameplay performance metric.

Gameplay:

show current combo clearly.

Result:

show Max Combo.

Combo should not visually overpower note readability.

---

# 18. DIFFICULTIES

Beat UP! has three authored difficulties:

NORMAL
HARD
MASTER

---

# 18.1 Normal

Intent:

READ THE SONG.

Characteristics:

- clear rhythm;
- breathing room;
- simple direction phrases;
- occasional eighth notes;
- low Reverse frequency;
- obvious Space accents.

Normal should introduce the song.

---

# 18.2 Hard

Intent:

PERFORM THE SONG.

Characteristics:

- more continuous patterns;
- quarter + eighth combinations;
- longer phrase chains;
- stronger alternation;
- more Reverse;
- occasional bursts.

---

# 18.3 Master

Intent:

MASTER THE SONG.

Characteristics:

- continuous high activity when musically appropriate;
- controlled sixteenth bursts;
- complex hand routing;
- richer direction vocabulary;
- significantly more Reverse;
- demanding phrase recognition.

Avoid:

- random chaos;
- unreadable walls;
- two-key spam;
- excessive single-finger chains.

---

# 19. SCROLL SPEED CONTRACT

Scroll speed follows song BPM.

Higher BPM:
faster note travel.

Lower BPM:
slower note travel.

But a capped curve must prevent extreme BPM songs becoming unreadable.

IMPORTANT:

No independent user setting for note speed.

Settings UI should not display one.

---

# 20. RANDOM MODIFIER

Random modifies note direction.

It does NOT change:

- timestamps;
- song BPM;
- note density;
- chart structure;
- difficulty;
- Space placement;
- Reverse timing;
- song sections.

Random should be presented as:

a modifier.

Not as a new difficulty.

---

# 21. PERSONAL BEST

Personal Best is local.

Important values:

- Rank;
- Score;
- Accuracy;
- Max Combo;
- PERFECT;
- GREAT;
- GOOD;
- MISS;
- Play Count.

Different rulesets must not overwrite incompatible records.

For example:

8K and 4K are separate contexts.

Random and authored runs must remain distinguishable.

---

# 22. REPLAY

Beat UP! includes deterministic replay support.

Replay may record:

- action timeline;
- expected input;
- displayed direction;
- random seed;
- note judgement;
- timing offset.

The normal UI does not need to expose technical replay internals.

---

# 23. PLAYTEST TELEMETRY

Beat UP! collects playtest performance information.

Per-note data can include:

- timestamp;
- PERFECT;
- GREAT;
- GOOD;
- MISS;
- timing error;
- note index;
- note type;
- expected input.

This supports developer heatmap analysis.

Telemetry is NOT a normal player-facing visual system.

Do not clutter player mockups with analytics dashboards.

---

# 24. SONG CATALOG

The song catalog is dynamic.

The current project contains a large multi-song library and each song may contain:

NORMAL
HARD
MASTER.

Do not hardcode the current number of tracks into layout logic.

A screenshot may show:

TRACK 04 / 40

but future content can change.

Mockups may use a representative total.

Implementation must derive it dynamically.

---

# 25. VISUAL IDENTITY: ALBUM FLOW

Album Flow is the current canonical visual direction.

Core adjectives:

dark
calm
editorial
music-first
artwork-led
minimal
precise
premium
restrained
responsive

---

# 26. DESIGN PHILOSOPHY

The song is the hero.

The interface frames the song.

Not:

the interface competes with the song.

---

# 27. INSPIRATION

Useful philosophy references:

- osu! — fast navigation and rhythm-game flow;
- Muse Dash — strong music/game personality;
- Taiko-style rhythm clarity.

Do NOT literally copy:

- layouts;
- icons;
- assets;
- logos;
- branding;
- animations.

---

# 28. UI SHOULD NOT LOOK LIKE

Avoid:

- SaaS dashboard;
- admin panel;
- desktop utility;
- spreadsheet;
- mobile app enlarged to desktop;
- cyberpunk HUD;
- generic futuristic game UI;
- default Godot interface;
- glassmorphism showcase.

---

# 29. CARD USAGE

Do NOT place everything inside a card.

Cards are for:

- grouping;
- selected performance;
- actionable control clusters;
- meaningful separation.

Typography and spacing should do most of the hierarchy work.

---

# 30. COLOR SYSTEM

Core Album Flow colors:

Background
#0B0E14

Surface
#131A24

Surface Raised
#1B2430

Border
#344052

Primary Text
#F4F6FB

Muted Text
#8B96A8

Primary Accent
#A9B8FF

Accent Light
#D8E0FF

Warm Neutral
#F2C8B0

Perfect Pink/Lilac
#D3A4FF

Good Cyan
#7DB4CE

Space Gold
#F5C96A

Danger
#B76C75

Success
#7DCE9E

---

# 31. GAMEPLAY SEMANTIC COLORS

Recommended stronger gameplay colors:

Normal Blue
~#5697FF

Diagonal Orange
~#FFA65C

Reverse Outline
#FF5A64

Space Gold
#F5C96A

PERFECT
pink/lilac

GREAT
green

GOOD
cyan

MISS
red

---

# 32. TYPOGRAPHY

The project includes bundled font families suitable for deterministic UI.

Recommended roles:

Space Grotesk:
display / large screen titles.

Poppins:
body / buttons / UI labels.

IBM Plex Mono:
BPM / track count / metadata / technical numbers.

---

# 33. TYPOGRAPHIC HIERARCHY

Example ranges at 1920×1080:

Brand:
48–68 px

Screen title:
30–44 px

Song title:
28–40 px

Section heading:
17–22 px

Body:
13–16 px

Metadata:
10–13 px

Overline:
9–11 px

These are design guidelines, not fixed implementation values.

---

# 34. SPACING

Use a consistent spacing grammar.

Recommended:

4
8
12
16
24
32
48
64
96

Avoid arbitrary spacing everywhere.

---

# 35. BORDER RADIUS

Recommended:

small UI:
8 px

normal panels:
12–14 px

large artwork / large panels:
16–18 px

Avoid giant pill-shaped containers unless the control naturally needs it.

---

# 36. BORDERS

Prefer:

thin
low-contrast
1 px

Selected state:

accent border / rail.

Avoid:

thick glowing outlines.

---

# 37. SHADOWS AND GLOW

Use sparingly.

Allowed:

- subtle artwork separation;
- selected primary action;
- tiny ambient glow;
- judgement effect.

Avoid:

- glow on every card;
- strong bloom;
- neon background.

---

# 38. BACKGROUND

Primary menu background:

dark navy / charcoal.

Artwork may provide:

very subtle ambient color.

Do NOT let a selected song turn the whole Song Library:

blue
red
green
purple.

Song Library must remain neutral.

---

# 39. MOTION LANGUAGE

Motion should feel quick and deliberate.

Suggested timing:

fast interaction:
~120 ms

normal UI:
~180 ms

large transition:
~240 ms

Use:

ease-out / quint-like easing.

Good motion:

- small slide;
- fade;
- controlled scale;
- artwork continuity.

Avoid:

- bounce;
- elastic;
- long cinematic delays;
- unnecessary spin;
- excessive parallax.

---

# 40. LOADING PHILOSOPHY

Avoid generic:

black screen
+
spinner.

When loading is necessary:

use current song context.

Artwork
title
difficulty
progress

can mask preparation.

---

# 41. NAVIGATION ARCHITECTURE

Conceptual player journey:

SPLASH
↓
MAIN MENU
├── PLAY
│    ↓
│  SONG LIBRARY
│    ↓
│  SONG LAUNCH
│    ↓
│  GAMEPLAY
│    ├── PAUSE
│    ↓
│  RESULT
│    ├── RETRY
│    └── SONG LIBRARY
│
├── CHART STUDIO
├── HOW TO PLAY
├── CALIBRATION
├── SETTINGS
├── CREDITS
└── EXIT

---

# 42. TECHNICAL UX CONTEXT

Beat UP! uses persistent systems such as:

AppShell

NavigationController

MusicSession

SongSelectionState

BackgroundSession

ReplayManager

UserSettings

Telemetry / session logging.

Mockup designers do not need to implement these.

However, designs should respect persistent continuity.

---

# 43. MAIN MENU

## Purpose

Create:

identity;
music atmosphere;
primary navigation.

---

## Main Menu Layout

Latest canonical design:

LEFT
brand
tagline
vertical navigation

CENTER / RIGHT
large square current-track art

RIGHT
featured track information

BOTTOM
Now Playing transport.

---

## Brand

Top left:

BEAT UP!

Under:

MUSIC LIFTS US HIGHER

Tagline is small, tracked, understated.

---

## Navigation

Items:

PLAY

CHART STUDIO

HOW TO PLAY

CALIBRATION

SETTINGS

CREDITS

EXIT

---

## Navigation Style

Selected:

- bright text;
- thin lilac selection rail;
- soft selected background;
- optional tiny diamond.

Unselected:

- muted off-white;
- minimal hover state.

EXIT:

restrained red.

Do not use seven large separate rectangular buttons.

---

## Main Menu Artwork

Current playing track artwork.

Square.

Recommended desktop range:

440–560 px.

Rounded corners:

~14–18 px.

Artwork is a focal object.

Do not use fake artwork when actual assets exist.

---

## Featured Track Metadata

Right side:

FEATURED TRACK

Song Title

Artist

short atmospheric description.

Example:

FEATURED TRACK

Midnight Pulse

Nova Circuit

In the quiet between beats,
we find a brighter tomorrow.

In real implementation, metadata should come from actual track state.

---

## Main Menu Now Playing

Bottom bar.

Contains:

small cover thumbnail;

track title;

artist;

previous;

play/pause;

next;

progress;

elapsed time;

duration.

Example:

[cover]
Midnight Pulse
Nova Circuit

◀   II   ▶

1:24 ━━━━━━━━━━━━━ 3:56

---

## Runtime Requirements

Pause:

must not reset timestamp to 00:00.

Previous / Next:

must genuinely change track.

Artwork and metadata:

must remain synchronized.

---

# 44. SONG LIBRARY

Song Library is one of the most important screens.

Target composition:

LEFT
compact browser

CENTER
album artwork

RIGHT
track details.

---

# 45. SONG LIBRARY OVERALL PROPORTIONS

Approximate content width distribution:

Left:
26–29%

Center:
34–38%

Right:
31–35%

Use visual judgement rather than rigid percentages when adapting to 1600×900.

---

# 46. SONG LIBRARY HEADER

Top left:

BEAT UP!

SONG LIBRARY

BEAT UP!:
large.

SONG LIBRARY:
small;
uppercase;
tracked.

---

# 47. SONG LIBRARY TRANSPORT

Do NOT display the Main Menu bottom Now Playing bar.

Do NOT display a giant top Now Playing bar.

Music continues internally.

Song Library focuses on selection.

---

# 48. SONG LIBRARY FILTERS

Preferred visible filter row:

ALL

ARTIST

DIFFICULTY

BPM ↑

Default sort:

BPM ascending.

If more options need menus:

use styled custom dropdowns.

Do not show generic native Godot OptionButtons.

---

# 49. SONG LIST

Each row:

[thumbnail] Song Title
            Artist

                           BPM / level context

Recommended dimensions at 1600×900:

row:
~58–64 px.

thumbnail:
~44–48 px.

---

## Unselected Row

Near-transparent.

Minimal background.

Muted artist.

---

## Selected Row

Subtle dark-lilac fill.

Thin accent outline or left rail.

Stronger text.

Do NOT significantly expand its height.

---

# 50. SONG LIST MUST NOT DO THIS

Do not place:

NORMAL
HARD
MASTER

as expanded rows below selected song.

Difficulty belongs to right details panel.

---

# 51. SONG ROW ARTWORK

Use:

song thumbnail.

Prefer project thumbnail assets.

Do not make every song item a giant horizontal artwork banner.

This was a major problem in previous designs.

---

# 52. SONG LIBRARY CENTER COLUMN

The center should be visually simple.

Structure:

LARGE ARTWORK

PLAY

Nothing else should compete heavily here.

---

# 53. SELECTED ARTWORK

Square.

1:1.

Large focal point.

Recommended at 1600×900:

approximately 440–510 px,
depending on available vertical space.

Use cover-style scaling.

No distortion.

No giant background expansion.

---

# 54. PLAY BUTTON

Directly under artwork.

Full artwork width.

Height:

approximately 50–56 px.

Style:

dark lilac;
thin accent border;
uppercase;
minimal.

PLAY is the strongest action on the screen.

---

# 55. SONG DETAILS — RIGHT COLUMN

Top:

TRACK 04 / 40

Use actual index dynamically.

Do not hardcode total.

Then:

Space Invaders

Teminite & MD

Then optional short summary.

---

# 56. SONG TITLE

Do NOT force uppercase.

Song title should preserve its normal typography.

Example:

Space Invaders

not:

SPACE INVADERS.

---

# 57. DIFFICULTY SELECTOR

Horizontal cards:

NORMAL
4

HARD
7

MASTER
10

Equal width.

Selected difficulty:

lilac/accent outline.

Unselected:

dark surface.

Must remain functional.

---

# 58. SONG METADATA

Compact 3-column layout:

BPM
128

DURATION
5:48

MODE
8 KEY

Captions:

small mono uppercase.

Values:

larger clean text.

MODE can be:

8 KEY

or:

4 KEY.

Random should not be appended to MODE.

---

# 59. YOUR BEST CARD

Primary selected-song performance summary.

Example:

YOUR BEST

S

SCORE
1,000,356

MAX COMBO
892

ACCURACY
99.3%

---

## No Record State

YOUR BEST

—

SCORE
—

MAX COMBO
—

ACCURACY
—

Do not show giant ranking tables on primary Song Library screen.

---

# 60. ACTIVE MODIFIERS

Below Your Best:

ACTIVE MODIFIERS

[8 KEY] [RANDOM]

or:

[4 KEY] [RANDOM]

Random OFF:

dark inactive chip.

Random ON:

accent state.

---

# 61. PRACTICE BUTTON

Under modifiers:

PRACTICE

Large secondary button.

Practice should remain important but visually secondary to PLAY.

---

# 62. SONG LIBRARY BACKGROUND

Critical rule:

Background remains:

#0B0E14-ish.

Selected artwork does NOT become a huge colorful background.

At most:

very low opacity atmospheric tint.

---

# 63. SONG LAUNCH

Short transition after PLAY.

Purpose:

- continuity;
- ritual;
- async loading presentation.

---

## Song Launch Content

Example:

NOW ENTERING

BEAT UP!

[large artwork]

Space Invaders
Teminite & MD

MASTER 10
8 KEY
RANDOM OFF

Preparing chart and audio…

──────────────

---

## Song Launch Motion

Artwork should feel like it continues from Song Library.

Possible sequence:

selected artwork
→ expands/moves
→ metadata fades
→ gameplay becomes ready
→ artwork recedes into gameplay context.

No generic spinner.

---

# 64. GAMEPLAY

One horizontal lane.

RIGHT → LEFT notes.

Hit zone left.

---

# 65. GAMEPLAY HUD

Required:

SCORE

COMBO

ACCURACY

SONG PROGRESS

RECENT JUDGEMENT

Optional low-priority:

song title;
difficulty;
mode.

---

# 66. GAMEPLAY HIERARCHY

The most important visual element is:

incoming notes + receptor.

HUD must be quieter.

---

# 67. GAMEPLAY SCORE

Example:

SCORE

892,340

Top-left is acceptable.

---

# 68. GAMEPLAY COMBO

Example:

COMBO

368

Center/top or another clear location.

Do not use an enormous combo badge that obstructs chart.

---

# 69. GAMEPLAY ACCURACY

Example:

ACCURACY

98.7%

Top-right.

---

# 70. GAMEPLAY PROGRESS

Minimal thin bar.

Can sit near top.

Use gold sparingly for current progress.

---

# 71. HIT ZONE

White diamond.

Subtle timing halo.

Clear from background.

---

# 72. GAMEPLAY NOTES

Normal cardinal:

blue.

Diagonal:

orange.

Reverse:

red outline;
same silhouette.

Space:

gold.

No numeric labels.

---

# 73. GAMEPLAY JUDGEMENT

Near hit zone.

Example:

PERFECT

+12 ms

Judgement colors follow canonical semantics.

---

# 74. GAMEPLAY BACKGROUND

Can use selected song artwork.

Must be dim.

Gameplay notes must remain readable regardless of artwork.

User background dim setting should be respected in implementation.

---

# 75. PAUSE

Gameplay remains visible behind pause overlay.

Background:

dim / frozen.

---

## Pause Options

PAUSE

TAKE A BREATH

RESUME

RETRY

SETTINGS

RETURN TO LIBRARY

---

## Pause Selection

Selected:

thin rail;
soft accent wash.

---

## Resume Countdown

A compact:

3
2
1

may appear when resuming.

Do not make it a giant blocking spectacle.

---

# 76. RESULT

Result screen represents performance closure.

Must display:

song artwork;

song title;

artist;

difficulty;

mode/modifiers;

rank;

score;

accuracy;

max combo;

PERFECT;

GREAT;

GOOD;

MISS.

---

# 77. RESULT VISUAL PRIORITY

1. FINAL RANK
2. FINAL SCORE
3. accuracy
4. max combo
5. judgement breakdown
6. song context
7. actions

---

# 78. RESULT EXAMPLE

FINAL RANK

SS

NEW PERSONAL BEST

FINAL SCORE

1,000,000

99.8%
ACCURACY

1324
MAX COMBO

PERFECT 1318

GREAT 6

GOOD 0

MISS 0

---

# 79. RESULT ACTIONS

Only two primary actions are needed:

RETRY

RETURN TO SONG LIBRARY

Do not create an unnecessary NEXT button that behaves like Retry.

---

# 80. RESULT ANIMATION

Recommended sequence:

screen enters;

score / metrics settle;

rank meter fills;

rank stops;

rank sound plays;

NEW BEST appears if applicable.

Keep it fast.

---

# 81. SETTINGS

Settings should be functional and calm.

Suggested group structure:

DISPLAY

AUDIO

TIMING

VISUAL

INPUT

ACCESSIBILITY

---

# 82. DISPLAY SETTINGS

Potential/current relevant controls:

Resolution

Window Mode

VSync

Fullscreen / Borderless where supported.

---

# 83. AUDIO SETTINGS

At minimum:

Master Volume.

Professional future grouping may reserve:

Music

SFX

UI.

Do not pretend those exist in implementation unless implemented.

For mockup design it is acceptable to reserve their visual structure.

---

# 84. TIMING SETTINGS

Input Offset.

Audio Offset.

Calibration entry.

Timing values should use milliseconds.

---

# 85. VISUAL SETTINGS

Gameplay Background Dim / Opacity.

Judgement Effects.

Combo Effects.

Reduced Motion where supported.

---

# 86. IMPORTANT SETTINGS RULE

DO NOT ADD:

NOTE SPEED.

Instead show an informational caption:

NOTE SPEED FOLLOWS SONG BPM AUTOMATICALLY.

---

# 87. INPUT SETTINGS

Show:

Directional Mode

8 KEY

4 KEY

and remappable bindings.

8-key mapping should visually represent:

7 8 9
4   6
1 2 3

---

# 88. CALIBRATION

Calibration must feel focused.

Purpose:

synchronize perceived audio and input timing.

---

# 89. CALIBRATION ELEMENTS

CALIBRATION

FIND YOUR PERFECT TIMING

Timing visual / ring / diamond

Metronome

BPM

Input/audio offset

offset slider/value

Apply

Retry

Reset if needed.

---

# 90. CALIBRATION VISUAL

Example:

                 ◇
              ( pulse )

               120 BPM

AUDIO & INPUT OFFSET

-100ms ━━━━━●━━━━━━━━ +100ms

                +12 ms

              [ APPLY ]

---

# 91. HOW TO PLAY

This is required because Beat UP!'s controls are unusual.

Recommended three sections:

CONTROLS

NOTE TYPES

JUDGEMENT.

---

# 92. HOW TO PLAY — CONTROLS

Visual keypad:

7 ↖     8 ↑     9 ↗

4 ←             6 →

1 ↙     2 ↓     3 ↘

Explicit:

KP5 IS NOT USED FOR DIRECTIONAL INPUT.

---

# 93. HOW TO PLAY — 4 KEY

Also display:

← ↑ → ↓

Explain:

4-Key projects directional charts into cardinal input.

---

# 94. HOW TO PLAY — NOTE TYPES

NORMAL

Read displayed direction.

Press matching input.

---

REVERSE

Same silhouette as Normal.

Red outline.

Displayed direction is reversed according to Reverse logic.

---

SPACE

Gold diamond.

Press Space on timing.

---

DO NOT INCLUDE BOMB.

---

# 95. HOW TO PLAY — JUDGEMENT

Normal timing:

PERFECT <= 35ms

GREAT <= 60ms

GOOD <= 90ms

MISS > 90ms

Space:

PERFECT <= 60ms

GREAT <= 110ms

GOOD <= 170ms.

---

# 96. CREDITS

Credits should use an editorial layout.

Potential categories:

GAME DESIGN

PROGRAMMING

UI / UX

CHARTING

MUSIC

AUDIO

FONTS

TOOLS / LIBRARIES

SPECIAL THANKS

Do not invent contributor names when unknown.

Use placeholders only when clearly labelled as placeholder content.

---

# 97. CHART STUDIO

Chart Studio is a player-facing chart authoring tool.

It should be more utilitarian than Main Menu while remaining visually part of Beat UP!.

---

# 98. PLAYER CHART STUDIO CAPABILITIES

Player can:

import audio;

create chart;

edit metadata;

set BPM;

set offset;

choose difficulty;

place notes;

delete notes;

select notes;

seek audio;

view waveform;

use beat snap;

zoom timeline;

undo;

redo;

save;

export;

playtest.

---

# 99. CHART STUDIO PLAYER NOTE TYPES

NORMAL

REVERSE

SPACE

No Bomb.

---

# 100. CHART STUDIO LAYOUT

Recommended:

TOP HEADER
metadata.

WAVEFORM
horizontal audio visualization.

TIMELINE
beat grid + notes.

RIGHT SIDEBAR
note tools + edit tools + snap.

BOTTOM
transport / zoom / view settings.

---

# 101. CHART STUDIO HEADER

Include:

song title;

artist;

BPM;

offset;

difficulty;

save.

Possibly current cover art.

---

# 102. WAVEFORM

Waveform is functional.

Should support:

playhead;

seek;

zoom context;

viewport marker;

hover timestamp.

It must not be decorative-only.

---

# 103. TIMELINE

Show:

beat divisions;

bar lines;

playhead;

note timing;

Normal;

Reverse;

Space.

Keep lanes visually readable.

---

# 104. NOTE TOOLS

Player tools:

NORMAL

REVERSE

SPACE

Edit tools:

SELECT

ERASE

DELETE

UNDO

REDO

---

# 105. SNAP

Example:

SNAP

1/4 BEAT

Other subdivisions can be selectable.

---

# 106. CHART STUDIO OUTPUT

Player options may include:

SAVE

EXPORT

PLAYTEST

---

# 107. DEVELOPER GENERATOR

Automatic generation exists only for developer workflow.

Player mockups MUST NOT display:

Generate All

Quick Generate

AI Generate

Advanced Generator

Python Generator

automatic difficulty generation.

---

# 108. MODS OVERLAY

A secondary Mods overlay can be designed.

Example:

MODS

MODE

[8 KEY]

[4 KEY]

MODIFIER

[RANDOM]

CURRENT

8K
RANDOM OFF.

Keep small and focused.

---

# 109. SPLASH

Splash is minimal.

Possible composition:

dark background;

small Beat UP! branding;

diamond motif;

soft fade.

Do not make splash a full menu.

---

# 110. PLAYER CREATOR POLICY

Player:

can create charts.

Developer:

can run automatic generator.

This distinction must remain clear.

---

# 111. MOUSE-FIRST MENU DESIGN

Primary menus are mouse-friendly.

But keyboard navigation must remain possible.

Design every interactive item with:

default;

hover;

pressed;

focus;

selected;

disabled.

---

# 112. FOCUS ACCESSIBILITY

Keyboard focus must be visible.

Do not rely solely on subtle color.

Possible focus:

accent border;

rail;

slight brightening.

---

# 113. REDUCED MOTION

Professional UI should be capable of reducing:

parallax;

large zooms;

decorative motion.

Critical gameplay timing visuals remain.

---

# 114. PERFORMANCE TARGET

The game should remain smooth on ordinary / lower-end PCs.

Do not design UI that requires:

multiple real-time full-screen blur passes;

heavy shader distortion;

constant particles;

animated noise textures;

large overlapping transparent effects.

Use composition instead.

---

# 115. REUSABLE DESIGN COMPONENTS

Codex should create a shared component set.

Recommended:

ScreenTitle

Overline

TextNavigationItem

SelectionRail

PrimaryButton

SecondaryButton

AlbumArtwork

SongRailRow

DifficultyChip

ModifierChip

MetricCard

MetadataValue

ProgressBar

TransportControl

Slider

Toggle

Dropdown

KeyBindingButton

DiamondNote

JudgementLabel

Waveform

TimelineNote

Dialog

Toast.

---

# 116. MAIN MENU COMPONENT RULE

Main Menu uses:

text navigation.

Do not convert its left navigation into seven large card buttons.

---

# 117. SONG LIBRARY COMPONENT RULE

Song rows are compact browser rows.

Do not turn them into huge banners.

---

# 118. ARTWORK POLICY

Use actual project artwork where possible.

Inspect project assets such as:

assets/song_backgrounds/

assets/song_thumbnails/

Prefer real project art.

Do not generate fake song artwork when current artwork exists.

---

# 119. INFORMATION HIERARCHY

Priority:

1. current song / current action;
2. selected state;
3. gameplay/performance context;
4. supporting options;
5. technical metadata.

Filters should not visually beat the selected song.

---

# 120. COPY STYLE

Keep copy:

short;

direct;

music-oriented;

functional.

Good:

PLAY

PRACTICE

YOUR BEST

FEATURED TRACK

ACTIVE MODIFIERS

RETURN TO SONG LIBRARY.

Avoid:

CLICK HERE TO START PLAYING

VIEW DETAILED STATISTICS

CONFIGURE GAMEPLAY EXPERIENCE.

---

# 121. NO EXCESSIVE GRADIENT

Gradient can be used:

subtly.

Do not use gradient as a substitute for composition.

---

# 122. NO EXCESSIVE GLOW

Glow is an accent.

Not a default state.

---

# 123. NO DEFAULT GODOT UI LOOK

Mockups should not resemble default:

OptionButton;

LineEdit;

CheckButton;

Panel.

Every control should feel designed for Beat UP!.

---

# 124. RESPONSIVE RULES

Mockups use 1920×1080.

But designer must consider:

1600×900.

At 1600×900:

reduce:

gaps;
artwork size;
display text.

Keep:

hierarchy;
three-column Song Library;
legibility.

---

# 125. 1366×768

At smaller desktop:

artwork may shrink;

song rail remains scrollable;

right metadata may compact;

no overlap;

no clipped controls.

---

# 126. DO NOT USE FULL ABSOLUTE LAYOUT

Mockups can use precise visual positions.

But design should be implementable through responsive:

horizontal groups;

vertical groups;

margins;

stretch ratios;

min sizes.

Do not design something that only works at one exact pixel size.

---

# 127. MAIN MENU MOCKUP DELIVERABLE

Create one individual frame:

Album Flow — Main Menu

1920×1080.

Do not combine it with other screens.

---

# 128. SONG LIBRARY MOCKUP DELIVERABLE

Create one individual frame:

Album Flow — Song Library

1920×1080.

---

# 129. SONG LAUNCH MOCKUP DELIVERABLE

Create:

Album Flow — Song Launch

1920×1080.

---

# 130. GAMEPLAY MOCKUP DELIVERABLE

Create:

Album Flow — Gameplay

1920×1080.

---

# 131. PAUSE MOCKUP DELIVERABLE

Create:

Album Flow — Pause

1920×1080.

---

# 132. RESULT MOCKUP DELIVERABLE

Create:

Album Flow — Result

1920×1080.

---

# 133. SETTINGS MOCKUP DELIVERABLE

Create:

Album Flow — Settings

1920×1080.

---

# 134. CALIBRATION MOCKUP DELIVERABLE

Create:

Album Flow — Calibration

1920×1080.

---

# 135. HOW TO PLAY MOCKUP DELIVERABLE

Create:

Album Flow — How To Play

1920×1080.

---

# 136. CREDITS MOCKUP DELIVERABLE

Create:

Album Flow — Credits

1920×1080.

---

# 137. CHART STUDIO MOCKUP DELIVERABLE

Create:

Album Flow — Chart Studio

1920×1080.

---

# 138. OPTIONAL SECONDARY MOCKUPS

After primary screens:

Mods Overlay

Song Library — Random Enabled

Song Library — No Personal Best

Settings — Rebinding Key

Chart Studio — Selected Reverse Note

Chart Studio — Space Hold / timeline editing

Pause — Resume Countdown.

---

# 139. EVERY MENU MUST BE SEPARATE

Do NOT create:

one giant image containing every menu.

Each menu needs:

its own frame;

its own screenshot/export;

its own composition.

---

# 140. MOCKUP DATA

If actual project metadata is accessible:

USE IT.

Use:

real titles;

real artists;

real BPM;

real artwork;

real difficulty information.

For pure concept mockups where data is unavailable:

temporary sample data is acceptable.

But do not redefine canon based on placeholder data.

---

# 141. DESIGN SYSTEM FIRST

Before producing final screens:

Codex should define:

color tokens;

typography roles;

spacing;

radius;

buttons;

focus;

selection;

song row;

difficulty chip;

modifier chip;

progress bar;

artwork container.

Then screens should use those shared rules.

---

# 142. SCREEN CONSISTENCY REVIEW

After all mockups exist, view them side-by-side.

Ask:

Do they look like the same game?

Main Menu should not look like one product while Settings looks like another.

---

# 143. MAIN MENU FEEL

Target emotion:

“I'm inside a music collection.”

Not:

“I'm inside a settings launcher.”

---

# 144. SONG LIBRARY FEEL

Target:

“I'm browsing albums/charts and choosing what to perform.”

Not:

“I'm managing database entries.”

---

# 145. GAMEPLAY FEEL

Target:

“Everything disappears except music, notes, timing, and performance.”

---

# 146. RESULT FEEL

Target:

“The performance concluded and I immediately understand how I did.”

---

# 147. CHART STUDIO FEEL

Target:

“A serious creator tool belonging to Beat UP!.”

Not:

“Debug tools exposed to players.”

---

# 148. DESIGN ERRORS TO AVOID

Do NOT:

make every area a rectangle;

make every song row a banner;

make full-screen artwork background;

show dozens of statistics;

show technical telemetry;

use huge gradients;

use neon everywhere;

make text too small;

put details over artwork;

hide primary action;

make navigation ambiguous;

add features not described here;

change gameplay mechanics while designing UI.

---

# 149. SPECIFIC SONG LIBRARY FAILURE TO AVOID

A previous implementation failed because it resulted in:

large colorful song banners dominating the left;

selected artwork/background filling almost the entire right;

text over artwork;

expanded difficulty rows inside song list;

missing visual header;

details and background competing;

too many legacy components remaining visible.

The new mockup must explicitly solve all of those.

---

# 150. ACCEPTANCE CRITERIA — MAIN MENU

PASS if:

brand readable;

navigation clearly left;

artwork focal point;

featured track readable;

Now Playing integrated;

background calm;

Play obvious.

FAIL if:

too many cards;

artwork becomes background;

navigation feels like dashboard;

Now Playing dominates everything.

---

# 151. ACCEPTANCE CRITERIA — SONG LIBRARY

PASS if:

compact left song rail;

selected artwork clearly centered;

right panel readable;

difficulty lives right;

Your Best concise;

modifiers secondary;

Play obvious;

background dark.

FAIL if:

songs are giant banners;

artwork floods background;

difficulty expands below song;

local ranking dominates;

metadata overlaps.

---

# 152. ACCEPTANCE CRITERIA — GAMEPLAY

PASS if:

notes are visually dominant;

hit zone obvious;

HUD minimal;

score/combo/accuracy readable;

judgement readable;

background quiet.

---

# 153. ACCEPTANCE CRITERIA — RESULT

PASS if:

Rank is immediate;

Score is immediate;

Accuracy and Max Combo clear;

judgement breakdown secondary;

Retry / Library clear.

---

# 154. ACCEPTANCE CRITERIA — CHART STUDIO

PASS if:

waveform readable;

timeline dominant;

tools discoverable;

metadata clear;

manual authoring obvious;

no player auto-generation controls.

---

# 155. PROJECT SCOPE PROTECTION

Do not add:

online multiplayer;

online leaderboard;

account system;

character progression;

inventory;

shop;

battle pass;

combat;

story mode;

skill tree

during UI mockup work.

---

# 156. IMPLEMENTATION SHOULD WAIT

The current task is:

DESIGN MOCKUPS.

Codex must not immediately modify runtime UI.

Workflow:

Documentation
↓
Design System
↓
Mockups
↓
Review
↓
Revision
↓
Approval
↓
Godot Implementation.

---

# 157. FINAL PRODUCT STATEMENT

Beat UP! should feel like:

a dark, calm, artwork-led music interface
that transforms into a precise,
high-feedback rhythm-performance environment
the moment gameplay begins.

The central design statement is:

THE SONG IS THE HERO.
THE INTERFACE FRAMES IT.

---

# 158. FINAL CANONICAL GAMEPLAY REFERENCE

8K:

7 8 9
4   6
1 2 3

KP5 unused.

Notes:

Normal
Reverse
Space

Bomb removed.

Normal timing:

Perfect <= 35ms
Great <= 60ms
Good <= 90ms

Space timing:

Perfect <= 60ms
Great <= 110ms
Good <= 170ms

Accuracy:

Perfect 1.00
Great 0.80
Good 0.50
Miss 0.00

Ranks:

SS >= 98.5
S >= 95
A >= 88
B >= 78
C >= 65
D below 65

Score display cap:

9,999,999

Scroll:

BPM-driven.

Random:

direction-only.

Reverse:

Normal silhouette
+
red outline only.

Chart Studio:

manual player authoring.

Automatic generation:

developer-only.

---

# 159. FINAL MOCKUP LIST

PRIMARY:

01 Main Menu
02 Song Library
03 Song Launch
04 Gameplay
05 Pause
06 Result
07 Settings
08 Calibration
09 How To Play
10 Credits
11 Chart Studio

SECONDARY OPTIONAL:

12 Mods Overlay
13 Song Library — Random ON
14 Song Library — No Personal Best
15 Settings — Keybind Edit
16 Chart Studio — Note Selected
17 Pause — Resume Countdown

All:

1920×1080
16:9
one menu per frame.
