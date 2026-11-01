# KEEP — Design system

## Direction and feel
- Calm, focused reading app: "a reading lamp on a dark desk". Warm and quiet, not playful.
- Palette from the Stitch project "Modern Dark Mode Gallery" (Obsidian Sage). Dark: charcoal with a green
  cast (`#121413`), mint primary `#5AF0B3`, lamp amber tertiary `#FFD16D`. Light ("Warm Paper"): paper
  `#F6F1E7`, deep sage ink primary `#006C4B`, dark amber tertiary `#7A5900`. Color means something:
  primary = progress / good score, secondary = good-but-not-great, tertiary = needs review,
  error = destructive action. Gray builds structure.
- Signature: the reading lamp background on the reading screen (charcoal or warm paper with a soft
  emerald → amber glow that follows the finger and breathes while the timer runs).

## Where values live
- Colors: explicit `ColorScheme`s `_obsidianSage` / `_warmPaper` in `lib/core/theme.dart` (no seed).
  Reading-screen colors in `ReadingLampColors`, logo colors in `KeepLogoColors` (both theme extensions,
  separate light and dark values). No `Color(0x…)` in widgets.
- Never branch on brightness in widget code; add a theme value instead.
- Text: `Theme.of(context).textTheme` only. Call sites may `copyWith(color: …)` and nothing else.
  Helpers: `AppTheme.reading`, `AppTheme.readingInput`, `AppTheme.wordmark`, `AppTheme.wordmarkLarge`.
- Radius: `AppRadius` in `lib/core/radius.dart`: sm 8 · control 14 · card 20 · sheet 24 · pill.
- Spacing: `AppSpacing` in `lib/core/spacing.dart` (base 4): xxs 4 · xs 8 · sm 12 · md 16 · lg 20 · xl 24 ·
  xxl 32 · fabClearance 96. Use `EdgeInsets.only` / `symmetric` / `EdgeInsetsDirectional.only`, never `fromLTRB`.

## Code comments
- At the first use in each `lib/` file of a project class or top-level function from another file, add
  `// X มาจาก lib/path/file.dart`. Not for Flutter/package symbols, generated l10n, or `test/`.

## Hierarchy
- System font (Thai/Chinese render well); sizes, line heights and tracking come from Stitch, in px:
  displayLarge 40/52 · displayMedium 32/42 · displaySmall 28/34 (recall-stat) · headlineMedium 26/34 ·
  headlineSmall 22/30 · titleLarge 18/26 · titleMedium 16/24 · titleSmall 15/20 · bodyLarge 16/28.8 ·
  bodyMedium 14/22 · bodySmall 13/18 · labelLarge 15/20 · labelMedium 13/18 · labelSmall 11/16.
- Weight does the work: numbers 700 with tabular figures, headings/labels 600, body 400.
- One focal point per screen. Home: the action card under the hero — "Random article"
  (`secondaryContainer`, shuffle icon turns half a turn on tap) or, while an article is in progress,
  the resume card in the same slot (no locked button is shown).
- Home hero card (`surfaceContainerLow`): name + streak pill (amber fire), AI sentence in headlineSmall,
  3 stat tiles (`surfaceContainer`, count up), daily goal bar (today's minutes vs the round length).
  A 5 % lamp-amber radial glow in the top-right corner ties it to the reading lamp.
- Reading screen focal point = the article text. Header (timer in titleLarge, amber under 2 min, pause
  button; reading-progress bar from scroll position; TTS row with play/stop, status and a speed chip
  0.75–1.5×) stays quiet on `surface`. App bar: bookmark toggle + "more" menu (Wikipedia / Google /
  pause for later). Card content: lead image 16:9 (decorative, hidden if it fails), title, meta pills
  (`surfaceContainerHigh`), Active Recall Note (AI question, amber start bar = lamp light; generic
  question if AI fails), then paragraphs. Headings and the TTS paragraph carry a 3 px start bar
  (primary / secondary) so the state is not shown by color alone.
- Reading text: `AppTheme.reading`, 18 px, line height 1.8 (Thai reads better with tall lines). Article headings
  use titleLarge in the reading text color, with extra space above.

## Depth and shape
- Surface-color shifts only (cards `surfaceContainerLow`, elevation 0). No drop shadows.
- Inputs are inset: `surfaceContainer` fill, `outlineVariant` hairline, focused border primary 2 px.
- Sheets and dialogs one step up (`surfaceContainerLow` / `surfaceContainerHigh`), radius 24.

## Components
- App shell (`AppShell`): 3 tabs Library / Review / Stats in a floating capsule nav (`CapsuleNavBar`):
  `surfaceContainerHigh` pill with an `outlineVariant` hairline, selected tab = `secondaryContainer` pill.
  Labels clamp at 1.5× text scale. Every tab uses `KeepAppBar` (logo + KEEP left, avatar right → Profile).
  Scrolling content adds `MediaQuery.paddingOf(context).bottom` so the last item clears the nav.
- Logo (`KeepLogo`): lamp + beam + open book, painted from the Stitch SVG. `lamp`, `beam`, `book`
  (0–1) can be animated separately; decorative unless `semanticLabel` is given.
- Stat card (`StatRevealCard`): label types out, number counts up (easeOutExpo), caption fades in;
  `prominent: true` for the one main card per screen. Labels may wrap; never clip.
- Score levels (`ScoreLevel`): ≥ 80 mastered = primary · ≥ 60 good = secondary · else review =
  tertiary (amber, not red: a low score means "read again", not an error) · none = outline.
  `ScorePill` (filled container pair + icon) on history cards; `ScoreBadge` circle elsewhere.
- History card: tags + read time | score pill, title, 2-line summary, retention bar in the level color
  + level label, language · date + delete button (swipe-to-delete also works, both confirm first).
- Topic sheet: headlineSmall title + close button (48 dp), info pills (source · language, minutes per
  round), chips keep their icon when selected (`showCheckmark: false`, `secondaryContainer` fill +
  `SelectedScale`), primary button, then a one-line hint with an amber lightbulb.
- Glows fade to the same hue at alpha 0 (never to an opaque surface color), or the middle turns muddy.
- Summary result card (calm: no halos, no illustration): `ScoreRing` (104 px, 8 px stroke in the
  level color, count-up number, semantics "Score N, level") + level pill + "X of Y key points" +
  model; key points grouped "Covered (n)" ✓ primary / "Missed (n)" ○ tertiary, core points marked;
  "Check these facts" in error color; AI feedback last in onSurfaceVariant. Stale score = 55 %
  opacity + amber note. After saving: tonal "Read another article" + outlined "Back to home".
- Chips never swap their icon for a checkmark (`showCheckmark: false` in the chip theme).
- Profile card: avatar 72 px (whole avatar is the change-photo button) + nickname (titleLarge) +
  "status · member since <month>" in secondary + email; then 3 equal-height `StatTile`s (logs saved
  primary, review success "–" until Phase B secondary, day streak tertiary). Settings sections: label
  title in onSurfaceVariant (semantic header), cards with zero margin; segmented buttons never show a
  check icon. Display card: dark mode + launch sound switches. Footer: logo, tagline, real app version.
- `StatTile` (shared): `surfaceContainer`, control radius, count-up number in titleLarge 700, label
  labelSmall; rows of tiles use `IntrinsicHeight` so tiles match height when a label wraps.
- Sign in (Stitch "Sign In A"): `KeepLogo` in an 80 px `surfaceContainerLow` circle with a faint
  amber halo; KEEP wordmark (0.28 em tracking, start padding equal to the tracking so it is optically
  centred); tagline; status pill (primary dot); form in a card; "Forgot password?" (login mode only)
  opens a dialog → Firebase reset email, neutral success text; lock-icon privacy footer.
- Onboarding: 2 steps (profile → reading preferences) with a 2-segment step bar + "Step n of 2";
  steps switch with the page motion. Avatar row scrolls horizontally; the selected avatar has a
  primary ring + check badge, and semantics say "selected".
- Launch (`LaunchScreen`, 3.6 s, tap to skip): lamp drops in and book rises (`lampShift`/`bookShift`,
  0–38 %), lamp flickers like an old bulb 30–70 % (`LaunchScreen.flicker`: never below 30 % after it
  first lights, 2 dips, ≤ 2 flashes/s, amber halo follows the beam), then KEEP + tagline fade up.
  Sound `assets/sounds/lamp_flicker.wav` (synthesised hum + clicks, ~-10 dBFS) starts with the flicker,
  respects the silent switch and mixes with other audio; off via Settings → Launch sound.
  Reduce Motion: static logo for 0.9 s, no flicker, no sound. Native splash background is paper /
  charcoal (no white flash).
- Theme mode (`KeepApp`): signed out → follows the device (launch + login + onboarding all match);
  signed in → the user's Dark Mode setting.
- App icon: `KeepLogo` painted on charcoal with a 20 % amber glow (`assets/icon/`, generated with
  `dart run flutter_launcher_icons`; Android adaptive foreground has extra padding).
- Stats tab (`StatsScreen` / `StatsBody`, data from `PeriodStats`): range segmented 7 / 30 days / all;
  3 `StatTile`s with a short "↑ n" caption (full sentence in semantics); then `ChartCard`s: reading
  time (bars, focal), recall scores (line + dashed 60/80 thresholds), 12-week reading calendar, topics.
  Charts (`lib/widgets/charts.dart`, CustomPainter): one hue = primary; calendar intensity = primary
  alpha 0.35/0.6/0.8/1 with a Less→More legend; text in text tokens, never the series color; bars have
  4 px rounded tops, empty days a 2 px stub; line 2 px, dots 8 px with a 2 px surface ring; recessive
  outlineVariant grid. Tap → value in a fixed line above the plot. Every card: semantics summary +
  table toggle. "All" range over 60 days switches to weekly bars. Grow-in animation respects
  Reduce Motion.
- Review tab (Leitner, `ReviewSchedule`): 5 boxes reviewed every 1 / 3 / 7 / 14 / 30 days; a new
  log is due the day after reading. Forgot → box 1, Hard → same box, Good → +1, Easy → +2.
  Firestore fields on `study_logs`: reviewBox, nextReviewAt, lastReviewedAt, reviewsTotal,
  reviewsPassed (server increments), recallQuestion. Profile "review success %" = passed ÷ total.
  Tab: hero "N articles to review" + Review button (focal), memory boxes as 5 `StatTile`s, due list
  (overdue = amber + clock icon), coming up (next 5). Session: title → recall prompt (amber start
  bar, stored AI question or a generic one) → optional notes (not saved) → reveal key points (core
  first; old logs show the earlier summary) → 2×2 rating buttons, each showing "in N days"; Good is
  the filled one. Sub-labels take the button's own text color.
- Delete account: a red text button under Logout (secondary to Logout, red = dangerous) → alert
  dialog with warning icon, what gets deleted, password field (errors shown inline), red filled
  "Delete forever". `AccountService` order: re-auth → users/{uid} → study_logs (batches of 400) →
  Firebase Auth user → this account's local keys; stops at the first failure.
- Sign in buttons under the form: "── or ──" divider, then outlined "Continue with Google" (GoogleMark:
  the 4-colour G, brand colours are the one allowed colour-literal exception) and "Continue with Apple"
  (Icons.apple, placeholder: snackbar "coming soon"). Google uses Firebase `signInWithProvider`
  (no google_sign_in package: its iOS SDK conflicts with Firebase iOS 13); iOS URL scheme = Encoded App ID.
- Email: `EmailText` truncates only the part before `@`, keeps the domain, full value in tooltip and semantics.

## Motion and accessibility
- Motion is unhurried: page transitions 450 ms, card entrance 500 ms (70 ms stagger), press 200 ms,
  select 300 ms, highlight 400 ms, scroll-to 600 ms. Curves `easeOutCubic` / `easeInCubic`: still
  "fast start, slow end", but softer than M3 emphasized curves. All values live in `AppMotion`.
- Every animation checks `AppMotion.reduced(context)` and shows the final state when Reduce Motion is on.
- Text must survive 3× text scale without overflow; long labels wrap, numbers scale down.
- Language names are shown in English everywhere: English · Chinese · Thai.
