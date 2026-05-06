# Chexo Brand System

## Voice

**NN/g Tone Scores:**
- Humor: 2/10 — Reliable over funny
- Formality: 3/10 — Casual-friendly, never corporate
- Respect: 7/10 — Encouraging, never condescending
- Enthusiasm: 5/10 — Warmly encouraging, never hyped

### Sample Sentences

**Marketing:**
- "Chex it off. Your tasks, always in view."
- "A calm corner for everything you need to do."
- "Stay focused. Get it done."

**Error:**
- "Couldn't save that task. Give it another go."
- "Something went wrong. Your tasks are safe — try reopening the panel."

**Success:**
- "All done — nice work."
- "Task completed. One less thing on your mind."

## Name

**Chexo** — from "check off." The logo is a checkmark on warm amber. The name, the icon, and the action are one: when you complete a task, you *chex it off*.

## Tagline

**"Chex it off."**

Candidates considered:
1. "Chex it off." — Ownable, uses the brand name as a verb, memorable
2. "Your tasks, always in view." — Direct, benefit-led, captures floating panel
3. "Focus on what matters." — Outcome-led but generic

## App Store Copy (macOS)

### App Name (30 chars)
Chexo — Floating Tasks

### Subtitle (30 chars)
Focus mode for your daily tasks

### Keywords (100 chars)
task,todo,checklist,focus,floating,menu,bar,productivity,gtd,minimal,tracker,quick,popup,overlay

### Description (4000 chars max)

Chexo lives in your menu bar, ready when you need it.

A floating task panel that's always one click away. Add tasks, focus on one at a time, and track your progress — without switching apps or losing context.

**What it does**

✓ Floating panel — stays above your windows, drag it anywhere on screen
✓ Focus mode — isolate a single task and zero in until it's done
✓ Keyboard-first — press ⌘N to add a task, Esc to dismiss
✓ Progress tracking — see your completion rate at a glance
✓ Lightweight — no accounts, no sync, no subscriptions. Just tasks.

**How it works**

Click the menu bar icon to open the panel. Type a task and press Enter. Click the target icon to enter focus mode — everything fades away except the one task that matters right now.

Your tasks are saved automatically. The panel remembers its position. It stays out of your way until you need it.

Built for macOS with native performance. No Electron, no web views, no bloat.

## Color System

### Primary: Warm Amber (OKLCH H=65)

| Token | Hex | Use |
|-------|-----|-----|
| brand.50 | #FDF8F0 | Lightest tint |
| brand.100 | #FAF0E0 | Surface tint |
| brand.200 | #F4DFC0 | Subtle accent bg |
| brand.300 | #E8C494 | Muted accent |
| brand.400 | #DCA458 | Hover/secondary |
| brand.500 | #D08C30 | Primary brand |
| brand.600 | #B87420 | Pressed/active |
| brand.700 | #8C5818 | Dark accent |
| brand.800 | #6A4214 | Dark surface |
| brand.900 | #3C2610 | Near-black text |
| brand.950 | #241608 | Darkest |

### Accent Color (Xcode)
`#E08A30` — warm amber, optimized for UI tinting in light + dark mode

## Typography

macOS system font (SF Pro). Native feel for a native app.

| Role | Size | Weight | Line-height |
|------|------|--------|-------------|
| Body | 13pt | Regular | 1.5 |
| Header | 13pt | Semibold | 1.2 |
| Caption | 11pt | Medium | 1.4 |
| Counter | 11pt | Medium / Monospaced | 1.2 |
| Focus title | 22pt | Medium | 1.15 |
| Button label | 13pt | Medium | 1.2 |

## Logo

### Concept
Bold white checkmark on warm amber gradient. Apple applies the squircle mask automatically.

### Construction
- Master canvas: 256x256 (rasterized to 1024x1024 for production)
- Safe zone: 26px padding all sides (10% for squircle mask)
- Checkmark stroke: 28px width, round caps/joins
- Checkmark points: (68, 136) → (112, 176) → (202, 60)
- Background: diagonal gradient #E89840 → #CC7820

### 16px test
- Stroke at 16px: 1.75px — above 1.5px minimum
- Width at 16px: 8.4px — clearly visible
- 1-bit black: solid checkmark silhouette — legible
- Inverted (white bg, dark check): legible

### Variants
- `logo-master.svg` — full-color app icon source
- `logo-mono.svg` — monochrome via currentColor

## Microcopy

### Empty State
"No tasks yet" + "Press ⌘N to add one" (current — matches voice)

### Loading
N/A — all operations are instant local SwiftData

### Success
- Task completed: checkbox animation (current — matches voice)
- All done: progress line fills (current — matches voice)

### Push
N/A — no push notifications in current scope
