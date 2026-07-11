---
name: Nova Repair Design System
colors:
  surface: '#f9f9ff'
  surface-dim: '#cfdaf2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee8ff'
  surface-container-highest: '#d8e3fb'
  on-surface: '#111c2d'
  on-surface-variant: '#434655'
  inverse-surface: '#263143'
  inverse-on-surface: '#ecf1ff'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d0e1fb'
  on-secondary-container: '#54647a'
  tertiary: '#4d556b'
  on-tertiary: '#ffffff'
  tertiary-container: '#656d84'
  on-tertiary-container: '#eef0ff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#dae2fd'
  tertiary-fixed-dim: '#bec6e0'
  on-tertiary-fixed: '#131b2e'
  on-tertiary-fixed-variant: '#3f465c'
  background: '#f9f9ff'
  on-background: '#111c2d'
  surface-variant: '#d8e3fb'
typography:
  headline-xl:
    fontFamily: Manrope
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Manrope
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Manrope
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Manrope
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Manrope
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Manrope
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  sidebar_width: 240px
  sidebar_collapsed: 64px
  container_max: 1440px
  gutter: 20px
---

## Brand & Style

The brand personality is centered on **Operational Precision**. As a tool for repair shop management, the UI must feel like a high-performance instrument: reliable, fast, and unobtrusive. The emotional response should be one of "calm control"—reducing the cognitive load of managing complex inventory and ticket workflows.

The design style is **Corporate / Modern**, leaning heavily into functional minimalism. It prioritizes information density and clarity over decorative flair. The aesthetic is "Desktop-First SaaS," utilizing a clean white-on-gray layering system to create a structured workspace that feels native to professional Windows environments. 

Key principles:
- **Efficiency:** Every pixel serves a functional purpose.
- **Stability:** Solid blocks, consistent borders, and predictable placements.
- **Clarity:** High contrast for text and critical status indicators.

## Colors

The palette is designed for prolonged daily use, minimizing eye strain through a soft neutral base while highlighting actionable elements with a single primary accent.

- **Primary:** Deep Professional Blue (#2563EB) is reserved for primary actions, active states, and focus indicators.
- **Neutral/Text:** Dark Charcoal (#1E293B) provides high-legibility for body text, while Slates are used for secondary information.
- **Backgrounds:** The application uses a "Layered Light" approach. The base application frame is #F8FAFC, while all functional "work surfaces" (cards, tables, modals) are pure #FFFFFF.
- **Semantic Colors:** Statuses (Repair Pending, Completed, At Risk) use muted but clear functional tones to ensure immediate recognition without overwhelming the dashboard.

## Typography

The design system utilizes **Manrope** for its balance between modern geometry and functional legibility. 

- **Scale:** The scale is compact to accommodate data-heavy tables and complex forms typical of management software.
- **Hierarchy:** We use weight (SemiBold to Bold) rather than massive size increases to denote hierarchy, keeping the interface feeling "grounded."
- **Labels:** Small, uppercase labels with slight letter spacing are used for table headers and section metadata to distinguish them from editable user data.

## Layout & Spacing

This design system uses a **Fixed-Fluid Sidebar Layout**. 
- **Sidebar:** A persistent 240px navigation bar on the left ensures critical tools (Tickets, Inventory, Customers) are always accessible.
- **Main Content:** A fluid area that utilizes a standard 12-column grid for dashboard widgets and full-width containers for data tables.
- **Spacing Rhythm:** An 8px linear scale is the foundation. For data-heavy views (Tables/Lists), use "Compact" spacing (8px padding); for marketing-style or summary views, use "Standard" spacing (16px - 24px padding).
- **Responsive Behavior:** On tablet, the sidebar collapses to icons-only (64px). On mobile, the sidebar moves to a bottom navigation bar or a hidden drawer, prioritizing the search and ticket scanning functions.

## Elevation & Depth

To maintain a "Professional Desktop" feel, depth is communicated through **Tonal Layering** supplemented by subtle, sharp shadows.

- **Level 0 (Base):** #F8FAFC. Used for the background "canvas."
- **Level 1 (Surface):** #FFFFFF. Used for cards, table containers, and the main content area. These feature a 1px solid border (#E2E8F0).
- **Level 2 (Interactive):** Used for dropdowns and popovers. These employ a subtle ambient shadow: `0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)`.
- **Contrast outlines:** Every elevated element must have a subtle border to ensure clear definition against the light gray background, even if shadows are present.

## Shapes

The design system uses a **Soft** shape language. 
- **Radius 4px (Base):** Applied to standard buttons, input fields, and small cards. This creates a professional, "exact" look that feels aligned with structured data.
- **Radius 8px (Large):** Reserved for main dashboard containers and modals.
- **Radius 999px (Pill):** Used exclusively for Status Badges (e.g., "In Progress") to visually separate them from interactive buttons.

## Components

### Buttons
- **Primary:** Solid #2563EB background, white text. No gradients. Focus state includes a 2px offset ring.
- **Secondary:** White background with a #E2E8F0 border. Text is #1E293B.
- **Tertiary/Ghost:** No background or border. Used for "Cancel" actions or secondary navigation within a card.

### Tables (Critical Component)
- **Header:** Light gray background (#F1F5F9), uppercase label-sm typography, sticky positioning.
- **Rows:** 48px minimum height. Subtlest possible border-bottom (#F1F5F9). Zebra striping is not required; use hover states (#F8FAFC) for row tracking.

### Inputs
- **Default:** White background, 1px border (#E2E8F0). On focus, border changes to #2563EB with a subtle blue glow.
- **Validation:** Error states use #EF4444 for borders and helper text.

### Status Chips
- Small, pill-shaped, with a low-opacity background of the semantic color (e.g., 10% green) and a high-contrast text label (e.g., 100% green).

### Sidebar Navigation
- Compact vertical layout. Active state indicated by a 3px vertical primary blue bar on the left edge and a subtle #EFF6FF background tint for the entire item.