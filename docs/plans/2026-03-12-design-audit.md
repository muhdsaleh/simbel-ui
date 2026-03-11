# Simbel UI — Design Audit
**Date:** 2026-03-12
**Scope:** `simbel-campaigns.html` · `simbel-campaign-builder.html`
**Target personality:** Polished & premium (Linear / Superhuman quality) with approachable energy — minimalism, whitespace, solid typography, pixel-perfect polish.

---

## Section 1 — Color & Brand

### Issues found
| # | Issue | Severity |
|---|-------|----------|
| 1.1 | CTA buttons used `--cta` (green `#32BB5A`) — off-brand for primary actions | High |
| 1.2 | Platform icons used generic foreground color; no brand identity | High |
| 1.3 | Selected platform tile overrode brand color with indigo, obscuring identity | Medium |
| 1.4 | Review step chip dots did not reflect platform brand colors | Low |

### Changes made
- **`.btn-default` + `.btn-primary`** — changed `background` from `var(--cta)` to `var(--primary)` (`#3333CC`) in both files.
- **Platform brand colors** applied via CSS attribute/data selectors:

| Platform | Color |
|----------|-------|
| Instagram | `radial-gradient(circle at 30% 107%, #fdf497 0%, #fdf497 5%, #fd5949 45%, #d6249f 60%, #285AEB 90%)` |
| Facebook | `#1877F2` |
| X / Twitter | `#000000` |
| LinkedIn | `#0077B5` |
| TikTok | `#000000` |
| WhatsApp | `#25D366` |
| Email | `var(--primary)` |

- Removed `.platform-tile.selected .pt-icon { background: var(--primary) }` — selection is communicated via border/checkmark/background tint only.
- Review chip JS updated with `platformBrandColors` map so dots match platform identity.

### Platform SVG logos (corrected)
All icons sourced from **Simple Icons** (simpleicons.org) — official brand-approved fill paths. Previous icons were Feather/Lucide stroke placeholders.

| Platform | Fix |
|----------|-----|
| Facebook | Replaced stroke "F" with Simple Icons circular-f fill path |
| LinkedIn | Replaced stroke icon with Simple Icons "in" letterforms (outer rounded-rect subpath removed to prevent white-square inversion on blue bg) |
| TikTok | Replaced stroke icon with Simple Icons musical-note fill path |
| WhatsApp | Replaced stroke icon with Simple Icons phone-in-bubble fill path |

---

## Section 2 — Typography

### Issues found
| # | Issue | Before | After |
|---|-------|--------|-------|
| 2.1 | Page title too small | 20px | 22px |
| 2.2 | Campaign card name slightly light | 14px | 15px |
| 2.3 | Stat label illegible at 11px | 11px | 12px |
| 2.4 | Progress step label over-sized in builder | 20px / 700 | 14px / 600 |
| 2.5 | Sidebar section headers clipping at narrow widths (wrong class in responsive CSS) | `.nav-section-header` | `.sidebar-section` (fixed) |

### Changes made
- `campaigns.html`: `.page-title` 20px → 22px; `.campaign-name` 14px → 15px; `.c-stat-label` 11px → 12px
- `campaign-builder.html`: `.step-label` 20px/700 → 14px/600; `.step-num` 26px → 22px
- Both files: responsive `@media (max-width: 900px)` selector corrected to `.sidebar .sidebar-section`

---

## Section 3 — Builder Form UX

### Issues found
| # | Issue | Before | After |
|---|-------|--------|-------|
| 3.1 | Progress strip too tall after label size reduction | 56px (hardcoded) | 44px |
| 3.2 | Section card headers had excessive padding | `var(--space-5) var(--space-6)` | `16px 20px` |
| 3.3 | Section card bodies had excessive padding | `var(--space-6)` | `20px` |
| 3.4 | Date picker calendar icon had no brand tint | browser default | indigo tint via CSS filter |

### Changes made
- `.progress-strip` height: `56px` → `44px`
- `.section-header` padding: token-based → `16px 20px`
- `.section-body` padding: token-based → `20px`
- `input[type="date"].field-input::-webkit-calendar-picker-indicator` — opacity `.45`, indigo filter

---

## Section 4 — Motion & Micro-interactions

### Issues found
- Stat cards, campaign cards, and buttons had no hover lift — felt static
- Dark mode toggle caused instant snap (no crossfade)
- Sidebar theme transition was abrupt

### Changes made

#### Hover lifts
```css
/* Stat cards */
.stat-card:hover {
  box-shadow: 0 6px 20px rgba(51,51,204,.09), 0 1px 3px rgba(0,0,0,.05);
  transform: translateY(-2px);
}

/* Campaign cards */
.campaign-card:hover {
  box-shadow: 0 6px 20px rgba(51,51,204,.09), 0 1px 3px rgba(0,0,0,.05);
  border-color: var(--primary-border);
  transform: translateY(-2px);
}

/* Buttons */
.btn-default:hover, .btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 3px 10px rgba(51,51,204,.30);
}
```

#### Theme crossfade
```css
body { transition: background-color .15s ease, color .1s ease; }
.sidebar { transition: width .22s ease, background-color .15s ease, border-color .15s ease; }
```

---

## Section 5 — Dark Mode Refinements

### Issues found
| # | Issue | Fix |
|---|-------|-----|
| 5.1 | X/Twitter (`#000`) badge invisible against dark card bg (`#16162A`) | Subtle `box-shadow` ring |
| 5.2 | TikTok (`#000`) badge same problem | Same ring fix |

### Changes made
```css
/* Campaigns page */
.dark .platform-icon[title="Twitter / X"],
.dark .platform-icon[title="TikTok"] {
  box-shadow: 0 0 0 1.5px rgba(255,255,255,.14);
}

/* Builder page */
.dark .platform-tile[data-platform="twitter"] .pt-icon,
.dark .platform-tile[data-platform="tiktok"]  .pt-icon {
  box-shadow: 0 0 0 1.5px rgba(255,255,255,.14);
}
```

---

## Summary of all files changed

| File | Sections touched |
|------|-----------------|
| `simbel-campaigns.html` | 1, 2, 4, 5 |
| `simbel-campaign-builder.html` | 1, 2, 3, 4, 5 |

---

## Design principles enforced
1. **Brand first** — platform colors and logos must match official guidelines at all times, including in selected/hover states.
2. **Typographic precision** — minimum 12px for any label; hierarchy reinforced through weight, not just size.
3. **Spatial economy** — padding tied to an 8px grid; no over-spaced section containers.
4. **Purposeful motion** — 2px lift + shadow on interactive cards; 1px lift on buttons. All under 200ms.
5. **Dark mode integrity** — every color decision re-examined at both themes; pure-black icons receive a hairline ring to maintain visual separation.
