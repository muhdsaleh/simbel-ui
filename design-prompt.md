# Simbel Marketing Site — Design Prompt

Build a single-page marketing site for **Simbel**, an AI-powered social media management platform built for Arabic. Single HTML file with all CSS and JS inline. Dark theme. No frameworks, no build tools.

---

## Typography & Brand

- **Font**: Adapter Arabic Text via Adobe Fonts/Typekit — a single bilingual font handling both Arabic and Latin scripts
  - Load: `<link rel="stylesheet" href="https://use.typekit.net/jvc7lrv.css">`
  - CSS: `font-family: 'adapter-arabic-text', sans-serif;`
  - Numbers must always display as Western Arabic (1, 2, 3) via `font-feature-settings: "lnum" 1`
- **Logo**: `simbel_logo_white.svg` — white SVG wordmark with an abstract icon mark, used in nav and footer
- **Primary color (indigo)**: `#3333CC`, lighter variant `#5555E8`
- **"Black"**: `#27274E` (the brand's dark, never true black)
- Headline weight: 700–800. Body weight: 400. Labels/UI: 500–600
- Letter-spacing: tight on headlines (−0.02em to −0.03em), normal on body
- Subpixel antialiasing: `-webkit-font-smoothing: antialiased; -moz-osx-font-smoothing: grayscale`

---

## Color System (CSS Custom Properties)

```css
:root {
  --bg:           #0B0B15;       /* deepest background */
  --bg-2:         #08080F;       /* even darker alt */
  --surface:      #111120;       /* card backgrounds */
  --surface-2:    #181828;       /* elevated card / hover state */
  --surface-3:    #1E1E32;       /* highest elevation */
  --border:       rgba(110,110,200,.09);   /* subtle borders */
  --border-2:     rgba(110,110,200,.18);   /* visible borders */
  --primary:      #3333CC;       /* brand indigo */
  --primary-lit:  #5555E8;       /* lighter indigo for text accents */
  --primary-glow: rgba(51,51,204,.15);
  --primary-soft: rgba(51,51,204,.08);
  --green:        #22C55E;
  --green-muted:  rgba(34,197,94,.13);
  --text:         #E2E2F4;       /* primary text — cool off-white */
  --text-2:       rgba(226,226,244,.65);  /* secondary text */
  --text-3:       rgba(226,226,244,.42);  /* tertiary text */
  --text-4:       rgba(226,226,244,.25);  /* ghost text */
  --radius:       8px;
  --radius-lg:    12px;
  --max-w:        1120px;        /* content max width */
  --section-gap:  140px;         /* vertical spacing between sections */
}
```

---

## Animated Background (fixed, behind all content)

The entire page sits over a fixed animated background layer (`.bg-canvas`) at z-index 0.

### 1. Floating Gradient Orbs
Four large blurred circles (`filter: blur(80px)`) that drift using a `orbFloat` keyframe animation (translate + scale over 20–30s loops). They fade in on load with a separate `orbFade` animation. Colors: mostly `rgba(51,51,204, .06–.12)` indigo with one subtle green orb `rgba(34,197,94,.05)`. They respond to mouse movement with a parallax effect — each orb shifts proportionally to how far the cursor is from center, with increasing intensity per orb.

### 2. Canvas Particle System
An HTML5 `<canvas>` element fills the viewport. 80 particles — tiny dots (`1–2px`) in `rgba(85,85,232, .05–.35)` — drift slowly with random velocities. Each particle pulses its opacity using a sine wave at individual phases. Particles within 120px of each other are connected by faint lines (`rgba(51,51,204, opacity)` where opacity fades to 0 at the 120px threshold, max ~0.08). All particles are subtly attracted toward the mouse cursor (within 300px radius, very gentle `0.0003` multiplier). Particles wrap around screen edges.

### 3. Grid Pattern
A CSS background grid (`60px × 60px`) made from two perpendicular `linear-gradient` lines at `rgba(110,110,200,.04)`. Masked with a `radial-gradient` ellipse so the grid fades out toward edges — visible mainly in the center/upper portion.

### 4. Hero Grid Lines
Four vertical lines at 20%, 40%, 60%, 80% horizontal positions. Each is a `1px` wide gradient line (`transparent → rgba(51,51,204,.08) → transparent`). They pulse in and out with staggered `vlinePulse` animations (6s cycle, 1.5s stagger between each).

### 5. Film Grain Overlay
A `body::before` pseudo-element covers the viewport (`position: fixed; inset: 0; z-index: 9999; pointer-events: none; opacity: .03`) with an inline SVG noise texture using `feTurbulence` (fractalNoise, baseFrequency 0.9, 4 octaves). Tiled at 256px.

---

## Scroll-Triggered Reveal Animations

Elements with class `.reveal` start invisible and translated down 28px. When they enter the viewport (IntersectionObserver, threshold 0.15, rootMargin `0px 0px -40px 0px`), they get class `.visible` which transitions to `opacity: 1; transform: translateY(0)` with `cubic-bezier(.16,1,.3,1)` easing over 0.8s. Stagger delays: `.reveal-d1` through `.reveal-d5` add 0.08s increments.

---

## Page Sections (top to bottom)

### 1. Fixed Navigation Bar
- `position: fixed`, 64px tall, full width, `z-index: 1000`
- Background: `rgba(11,11,21,.7)` with `backdrop-filter: blur(16px)`, transitions to `.92` opacity on scroll past 20px
- Bottom border: `1px solid var(--border)`
- Content (max-width `var(--max-w)`, centered): logo (left, 18px height) — links (right) — "How it works", "Arabic", "Platforms", "Pricing" at 14px/500 weight in `--text-2`, hover to `--text` — "Get started free" CTA button (36px height, 8px radius, `--primary` bg, white text, 14px/600 weight, hover lifts −1px with `--primary-lit` bg)

### 2. Hero Section
- Padding: 160px top, centered text
- Faint radial glow behind: 800×600px ellipse gradient from `rgba(51,51,204,.1)` to transparent
- **Eyebrow badge**: pill shape (32px height, 999px radius), `--primary-soft` bg, `--border-2` border, `--primary-lit` text at 13px/500. Contains a 6px pulsing green dot + "Now in beta". Fades up on load (0.2s delay)
- **Headline** (`h1`): `clamp(40px, 5.5vw, 68px)`, weight 800, −0.03em tracking, max-width 780px. Text: "AI-powered social media management, built for" then `<span class="accent">` "Arabic." in `--primary-lit`. Fades up at 0.35s
- **Subheadline**: `clamp(16px, 1.8vw, 19px)`, `--text-2`, max-width 520px, line-height 1.6. Text: "One brief drives strategy, content, scheduling, and analytics across every platform. In Arabic or English." Fades up at 0.5s
- **CTA buttons** (flex row, 14px gap, centered): Primary — "Get started free" (48px height, 10px radius, `--primary` bg, white, 15px/600, hover lifts −2px with glowing box-shadow `0 8px 32px rgba(51,51,204,.3)`). Ghost — "See how it works" with a small play triangle SVG icon (transparent bg, `--text-2`, 1px `--border-2` border, hover lifts). Fades up at 0.65s
- **Note**: "No credit card required" in 13px `--text-3`, margin-bottom 72px. Fades up at 0.75s
- **Product screenshot**: `<iframe>` embedding `simbel-campaigns-option-a.html` (a separate campaigns dashboard page) at 100% width × 620px height, `pointer-events: none`, inside a container with 16px radius, `--border-2` border, deep shadow (`0 24px 80px rgba(0,0,0,.5)` + `1px inset rgba(255,255,255,.03)`). A gradient overlay fades the bottom edge into the background. The container has subtle parallax on scroll (translates Y at `scrollY * 0.08`). Fades up at 0.85s

### 3. Metrics Strip
- 80px vertical padding, no visual separator (seamless with page background)
- 4-column grid (equal columns) at max-width, centered
- Each metric: centered text, vertical `1px` divider line (`--border`) between them (right side, 80% height)
- **Value**: `clamp(36px, 4vw, 52px)`, weight 800, −0.03em tracking, tabular + lining nums. Counter animation: rolls from 0 to target on scroll intersection (1600ms, easeOutExpo)
- **Label**: 14px, weight 500, `--text-3`
- Content: **37** "AI agents working for you" | **7** "Platforms connected" | **5** "Arabic dialects supported" | **1** "Brief to full campaign"
- Each metric uses `.reveal` with staggered delays

### 4. How It Works Section
- Section padding: `var(--section-gap)` (140px) vertical, 40px horizontal
- **Section label**: "HOW IT WORKS" — 13px, weight 600, uppercase, 0.08em tracking, `--primary-lit`
- **Title**: "One brief. Five stages. Complete campaign." — `clamp(28px, 3.5vw, 42px)`, weight 700, −0.02em tracking, max-width 600px
- **Description**: body text at 17px, `--text-2`, max-width 500px, line-height 1.65

#### Pipeline Cards (5-column grid, 16px gap, 56px top margin)
Each card (`.pipeline-step`):
- `--surface` bg, `--border` border, 12px radius, 28px/22px padding
- Flexbox column layout
- **Large number**: "01"–"05" at 48px, weight 800, `--primary` color (full opacity indigo), −0.04em tracking. Transitions to white on hover
- **Name**: 16px, weight 600 (e.g., "Brief", "Research & Strategy", "Content", "Publish", "Analytics")
- **Description**: 13px, `--text-3`, line-height 1.5, flex: 1
- **"Details" link**: 12px, `--text-4`, inline-flex with a small chevron SVG. The chevron rotates 180° when active
- **Hover**: bg → `--surface-2`, border → `--border-2`, lifts −4px
- **Active/clicked state**: bg → `--primary`, border → `--primary`, lifts −4px with `box-shadow: 0 8px 32px rgba(51,51,204,.25)`. Number, name → white. Description → `rgba(255,255,255,.7)`. Details → `rgba(255,255,255,.85)`
- Clicking a card opens a detail panel below (full grid-column span). Clicking again closes it. Clicking a different card switches

#### Detail Panels
- Full-width (`grid-column: 1 / -1`), animated height with `max-height` transition (0 → 400px, 0.5s cubic-bezier)
- Inner container: 2-column grid (1fr 1fr), 40px gap, `--surface` bg, `--border-2` border, 12px radius, 36px/32px padding
- **Left column (text)**: h3 at 20px/700 + paragraph at 15px/`--text-2`/1.7 line-height + feature list (unordered, each item 14px/`--text-2` with a 5px `--primary-lit` dot before each)
- **Right column (visual)**: `--surface-2` bg, `--border` border, 10px radius, 24px padding, min-height 180px, centered content with a faint radial indigo glow. Contains a horizontal flow diagram: 4 steps connected by `→` arrows. Each step is a 40px square (10px radius, indigo-tinted bg/border) with an emoji icon + 11px label below

Detail panel content per step:
1. **Brief** — "Start with what matters" — objectives, KPIs, platforms, languages, brand guidelines — Flow: 🎯 Objective → 👥 Audience → 📱 Platforms → 🗣️ Language
2. **Research & Strategy** — "AI-driven market intelligence" — competitor analysis, audience patterns, posting frequency, strategy doc — Flow: 🔍 Research → 📊 Analysis → 📋 Strategy → ✅ Approval
3. **Content** — "Content that speaks your audience's language" — platform-native formats, five Arabic dialects, hashtag research, visual suggestions — Flow: ✍️ Generate → 🌐 Localize → 🔄 Adapt → 📝 Review
4. **Publish** — "Smart scheduling for MENA time zones" — optimal timing, Ramadan awareness, drag-and-drop queue, approval workflows — Flow: 🕐 Timing → 📅 Schedule → 👁️ Review → 🚀 Publish
5. **Analytics** — "Learn, improve, repeat" — unified dashboard, AI insights, engagement/reach/conversion tracking, auto strategy refinement — Flow: 📈 Track → 🧠 Analyze → 💡 Insights → ⚡ Optimize

### 5. Built for Arabic Section
- Same section structure (label: "BUILT FOR ARABIC", title, description)
- Title: "Content that sounds local, not translated."
- Desc: "Simbel generates content in five Arabic dialects. Not formal MSA that sounds stiff on social media — real, conversational Arabic your audience actually speaks."
- 2-column grid (1fr 1fr, 64px gap, 56px top margin)

#### Left: Dialect Cards (2×2 grid, 10px gap)
Each card: `--surface` bg, `--border` border, 12px radius, 20px padding. Hover lifts −3px.
- Flag emoji (24px), dialect name (14px/600), sample Arabic text (15px, `--text-2`, RTL, right-aligned)
- **Speaker button**: 32px circle, `--primary-soft` bg, `--primary-lit` color, indigo border. Hover → `--primary` bg, white, scale 1.1. Clicking triggers browser SpeechSynthesis API to read the Arabic text aloud. Pulses while playing
- Cards: 🇸🇦 Saudi "وش رايكم نجرب شي جديد؟" | 🇪🇬 Egyptian "إيه رأيكم نجرب حاجة جديدة؟" | 🇦🇪 Emirati "شو رايكم نيرب شي ييديد؟" | 🇱🇧 Levantine "شو رأيكن نجرب شي جديد؟"

#### Right: Generated Content Preview
- `--surface` bg, `--border` border, 16px radius, 32px padding, with a top-right radial glow
- Label: "GENERATED CONTENT PREVIEW" (12px, uppercase, 0.06em tracking, `--text-3`)
- Mock Instagram post card: `--surface-2` bg, `--border` border, 10px radius, 20px padding
  - Header: 32px circle avatar (`rgba(51,51,204,.18)` bg, "S" in `--primary-lit`) + "Simbel · Instagram"
  - Body: Arabic RTL promotional text about Ramadan deals
  - Hashtags: `--primary-lit` colored
  - Badge: green pill ("● Saudi dialect") with `--green-muted` bg

### 6. Platforms Section
- Centered section (label + title + description all center-aligned)
- Title: "Publish everywhere from one dashboard."
- Desc: "Connect your accounts and Simbel handles the rest. Content is optimized for each platform automatically."
- 7-column grid (10px gap, 56px top margin)
- Each card: `--surface` bg, `--border` border, 12px radius, 28px/16px padding, centered. Hover lifts −4px → `--surface-2`
- 40×40px icon container with 28px SVG icons in `--text-2`, then platform name (13px/600/`--text-2`)
- Platforms: Instagram, Facebook, X (Twitter), LinkedIn, TikTok, WhatsApp, Email (each with appropriate SVG path icon)

### 7. Final CTA
- 120px vertical padding, centered, with a bottom radial glow (900×500px ellipse at `rgba(51,51,204,.08)`)
- Title: "Ready to launch your first campaign?" — same sizing as section titles
- Subtitle: 17px, `--text-2`, max-width 420px — "Start free. No credit card required."
- Primary CTA button (same style as hero primary button)

### 8. Footer
- `--border` top border, 48px vertical padding
- Flex row (space-between): logo (14px height, 40% opacity) — links list ("Features", "Pricing", "About", "Contact", "Privacy", "Terms") at 13px/`--text-3` — copyright "© 2026 Simbel" at 12px/`--text-4`

---

## JavaScript Behaviors

1. **Scroll reveal** — IntersectionObserver adds `.visible` class to `.reveal` elements
2. **Counter animation** — Numbers roll from 0 to target value over 1600ms with easeOutExpo, triggered once on scroll intersection
3. **Hero parallax** — Product screenshot translates Y at `scrollY * 0.08` (only below 1200px scroll)
4. **Nav darken** — Background opacity changes from 0.7 to 0.92 when scrolled past 20px
5. **Pipeline expand/collapse** — Clicking a step toggles its detail panel; only one can be open at a time; auto-scrolls to reveal the panel
6. **Particle system** — 80 particles with connection lines, mouse attraction, pulse animation
7. **Orb parallax** — Mouse movement shifts orbs with increasing intensity per orb
8. **Dialect TTS** — SpeechSynthesis API reads Arabic text on speaker button click; buttons show playing state

---

## Responsive Breakpoints

### ≤ 900px
- Pipeline grid → 2 columns (5th card spans full width)
- Arabic grid → single column
- Platforms grid → 4 columns
- Metrics grid → 2 columns with 32px gap, dividers hidden
- Detail panel inner → single column

### ≤ 600px
- Section gap → 80px, hero padding-top → 120px
- Nav padding → 20px, section horizontal padding → 20px
- Pipeline grid → single column
- Platforms grid → 3 columns
- Dialect cards → single column
- Footer → column layout, centered, 20px gap
- Nav links hidden (hamburger not yet implemented)

---

## Key Design Principles

1. **Depth through layering**: Multiple translucent layers (grain → particles → orbs → grid → content) create depth without heavy shadows
2. **Indigo as the single accent**: Nearly every colored element uses the indigo spectrum. Green appears only for status badges. No other hues
3. **Motion is ambient, not attention-grabbing**: Particles drift, orbs float, grid lines pulse — all barely perceptible. Scroll reveals are quick and smooth, never bouncy
4. **Cards as the primary UI pattern**: Every content group is a card with consistent styling (surface bg, border, 12px radius, lift-on-hover)
5. **RTL-ready**: Arabic text blocks use `direction: rtl; text-align: right`. The font handles both scripts natively
6. **Single-file simplicity**: Everything (HTML, CSS, JS) lives in one file. No dependencies beyond the Typekit font link
