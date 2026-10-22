---
trigger: always_on
---

# UI/UX Goals & Design Philosophy

Every agent working on **nixSVG** must strictly uphold the following visual and experiential standards:

## 1. Material 3 Expressive (M3E) Exclusivity
- **Framework Standards**:
  - Exclusively utilize **Material 3 Expressive** styling principles and components:
    - `m3e_buttons`, `m3e_segmented_list`, `m3e_dropdown_menu`, `m3e_slider`, `m3e_floating_toolbar`, `m3e_bottom_sheet`, `m3e_card_list`, and `flutter_m3shapes_extended`.
  - Dynamic color schemes derived systematically from active seed colors via `M3EColorScheme` and `AppTheme`.
  - All surface elevations, tonal palettes, and contrast ratios must dynamically adjust to light/dark modes and user-selected primary accents.

## 2. Solid Foundation & Polish
- **The Experience Benchmark**:
  - The application must feel **solid, responsive, and exquisitely crafted**—comparable to premier desktop applications (e.g., Sketch, Craft, Figma).
  - High frame rate (60/120 FPS) with zero frame stutter or layout recalculation thrashing during scrubbing, dragging, or panning.
- **Physics & Micro-Animations**:
  - Employ spring physics (`m3e_physics_spring.dart`, `motor`, `morph_expressive`) for transitions, sidebar drawer sliding, floating toolbars, and modal popups.
  - Hover states on interactive elements must be subtle, tactile, and provide immediate visual feedback.

## 3. Mathematical Rigor & Precision
- **No Guesswork**:
  - In design, layout, and calculations, approximations are strictly forbidden. All measurements, padding, margins, bounding boxes, transforms, and corner radii must be mathematically calculated and consistent:
    - Geometry calculations must reside in dedicated calculation utilities (e.g., `lib/calculations/canvas_geometry.dart`, `canvas_transform.dart`).
    - Use strict clamping against viewport boundaries and explicit floating-point precision where needed.
    - Transform handles must maintain uniform screen-space pixel sizing regardless of canvas zoom level.

## 4. Typography & Visual Hierarchy
- **Primary Typeface**:
  - **Google Sans** / Google Sans Flex loaded locally from `assets/fonts/GoogleSansFlex_Regular.ttf`.
  - Clear hierarchy with distinct label styling: micro-labels for properties, medium headers for sidebars, crisp mono/tabular numbers for coordinate/dimension scrubbing.