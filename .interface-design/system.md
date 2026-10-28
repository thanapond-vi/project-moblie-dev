# KEEP — Design system

## Direction and feel
- Calm, focused reading app: "a reading lamp on a dark desk". Warm and quiet, not playful.
- One accent hue (teal-green seed `#2E7D6B`). Color means something: primary = progress / good score,
  tertiary = middle score, error = low score or destructive action. Gray builds structure.
- Signature: the reading lamp background on the reading screen (charcoal or warm paper with a soft
  emerald → amber glow that follows the finger and breathes while the timer runs).

## Where values live
- Colors: `ColorScheme.fromSeed` in `lib/core/theme.dart`; reading-screen colors in the
  `ReadingLampColors` theme extension (separate light and dark values). No `Color(0x…)` in widgets.
- Never branch on brightness in widget code; add a theme value instead.
- Text: `Theme.of(context).textTheme` only. Call sites may `copyWith(color: …)` and nothing else.
  Helpers: `AppTheme.reading`, `AppTheme.readingInput`, `AppTheme.wordmark`, `AppTheme.wordmarkLarge`.
- Spacing: `AppSpacing` in `lib/core/spacing.dart` (base 4): xxs 4 · xs 8 · sm 12 · md 16 · lg 20 · xl 24 ·
  xxl 32 · fabClearance 96. Use `EdgeInsets.only` / `symmetric` / `EdgeInsetsDirectional.only`, never `fromLTRB`.

## Hierarchy
- Weight does the work, not size: headline and titleLarge 700 with tabular figures, titleMedium 600,
  body and labels at their Material defaults.
- One focal point per screen. Home: the "Total reading" card (full width, primary-container tint,
  displaySmall number); articles read and average score are smaller cards below it.
- Reading text: bodyLarge, 17 px, line height 1.8 (Thai reads better with tall lines). Article headings
  use titleLarge in the reading text color, with extra space above.

## Depth and shape
- Surface-color shifts only (cards `surfaceContainerLow`, elevation 0). No drop shadows.
- Radius scale: buttons and inputs 14 · cards 20 · reading card top 20. Focused input border: primary, 2 px.

## Components
- Stat card (`StatRevealCard`): label types out, number counts up (easeOutExpo), caption fades in;
  `prominent: true` for the one main card per screen. Labels may wrap; never clip.
- Score badge: circle, 2 px border in the score color, 12 % tint fill, number in headlineSmall,
  scaled down with `FittedBox` so large text never overflows. ≥ 80 primary · ≥ 50 tertiary · else error.
- Email: `EmailText` truncates only the part before `@`, keeps the domain, full value in tooltip and semantics.

## Motion and accessibility
- Every animation checks `AppMotion.reduced(context)` and shows the final state when Reduce Motion is on.
- Text must survive 3× text scale without overflow; long labels wrap, numbers scale down.
- Language names are shown in English everywhere: English · Chinese · Thai.
