# nixSVG — Agent & Developer Handbook

Welcome to the **nixSVG** project repository. This document outlines everything you need to know about the product, its architecture, core features, UI/UX philosophy, and cross-platform compatibility guidelines.

---

## 1. What Are We Building?
**nixSVG** is a high-performance, precision vector graphic design studio and SVG editor built with Flutter.

The goal is to deliver:
- **Canvas Power**: Professional vector manipulation capabilities akin to Figma, Illustrator, and Sketch.
- **Mac-App Style Polish**: A smooth, tactile, and rock-solid experience characteristic of high-end Apple macOS software.
- **Material 3 Expressive**: Cutting-edge visual design utilizing M3 Expressive components, dynamic theming, and spring physics.
- **Universal Cross-Platform**: Flawless execution across **macOS, Windows, Linux, Web, Android, and iOS**.

---

## 2. Core Feature Breakdown
- **Vector Canvas Engine**:
  - Infinite coordinate space, real-time transformations (`CanvasTransform`), and interactive zoom/pan.
  - Multi-level grid with dynamic subdivisions (`GridPainter`) and snap-to-grid / snap-to-guides.
  - Precise hit-testing and marquee multi-selection (`CanvasHitTest`).
- **Shape Primitives & Vector Tools**:
  - Primitives: Rectangles (with individual/uniform corner radii), Circles, Ellipses, Stars, Polygons, Lines.
  - Paths: Freehand drawing and Bézier pen paths with anchor point and control handle editing.
  - Typography: Inline canvas text editing (`CanvasInlineTextEditor`) with Google Sans.
- **Properties Inspector & Scrubbing**:
  - Interactive Figma-style numerical scrubbing for coordinates, dimensions, angles, corner radii, and stroke weights.
  - Professional Color Picker (`NixColorPickerPresenter`, `ColorPickerDialog`) with HEX/RGB/HSL, gradients, and preset palettes.
- **Layer Tree & Hierarchy**:
  - Layer reordering, grouping/ungrouping, locking, hiding, and naming (`LayersSidebar`).
- **History & Undo/Redo**:
  - Granular transaction management (`UndoRedoManager`) with scrub batching.
- **Import & Export**:
  - Standards-compliant SVG export (`SvgExportService`, `ExportDialog`) and raster PNG/WebP exports (1x–4x).
- **Desktop Accelerators**:
  - Standard key bindings (`V`, `R`, `O`, `T`, `P`, `Space+Pan`, `Cmd/Ctrl+Z`, `Cmd/Ctrl+Shift+Z`, `Cmd/Ctrl+D`).

---

## 3. UI/UX Goals & Design Philosophy
1. **Material 3 Expressive Exclusivity**:
   - Utilize M3 Expressive packages (`m3e_buttons`, `m3e_segmented_list`, `m3e_dropdown_menu`, `m3e_slider`, `m3e_floating_toolbar`, `m3e_bottom_sheet`, `flutter_m3shapes_extended`).
   - Dynamic theming with seed colors (`AppTheme`, `themeProvider`) that reactively updates all surfaces.
2. **Solid Foundation & Mac Feel**:
   - Silky 60/120 FPS performance with spring physics (`m3e_physics_spring.dart`, `motor`).
   - Tactile feedback, crisp hover transitions, and clean layouts.
3. **Mathematical Precision**:
   - Exact calculations for bounding boxes, padding, margins, transform matrices, and hit tolerances.
   - All spatial math must live in dedicated calculation classes under `lib/calculations/`.

---

## 4. Cross-Platform Compatibility Matrix

| Platform | Primary Input Modality | Layout Behavior | Special Considerations |
| :--- | :--- | :--- | :--- |
| **macOS** | Keyboard + Trackpad / Mouse | Dual persistent sidebars + resizable dividers | Command-key shortcuts, native window bar |
| **Windows / Linux** | Keyboard + Mouse | Dual persistent sidebars + resizable dividers | Control-key shortcuts, custom window chrome |
| **Web** | Mouse / Trackpad / Touch | Dual persistent sidebars (desktop) or Drawer | Browser context menu suppressed (`BrowserContextMenu.disableContextMenu()`) |
| **Android / iOS** | Multi-touch gestures | Dynamic off-canvas Drawers / M3E Modal Bottom Sheets | Minimum 44px touch targets, orientation changes reflow panels dynamically |

### Dynamic Panel Scaling Rules (`ResponsiveLayoutTokens`)
- **TopNavigationBar**: Desktop `46px`, Tablet `42–44px`, Mobile `38–42px`.
- **Sidebars (Layers & Properties)**: Dynamic max widths (`28%–35%` of screen width, clamped).
- **Floating Toolbar**: Scales between `0.84x` (small phone) to `1.05x` (ultrawide), automatically adjusting bottom margin to accommodate system safe areas.

---

## 5. Active Agent Rules in `.agents/rules/`
- [project_vision.md](file:///home/edwardbawiceu/development/flutter/projects/nixsvg/.agents/rules/project_vision.md)
- [features.md](file:///home/edwardbawiceu/development/flutter/projects/nixsvg/.agents/rules/features.md)
- [ui_ux_goals.md](file:///home/edwardbawiceu/development/flutter/projects/nixsvg/.agents/rules/ui_ux_goals.md)
- [cross_platform_compatibility.md](file:///home/edwardbawiceu/development/flutter/projects/nixsvg/.agents/rules/cross_platform_compatibility.md)
- [design.md](file:///home/edwardbawiceu/development/flutter/projects/nixsvg/.agents/rules/design.md)
- [experience.md](file:///home/edwardbawiceu/development/flutter/projects/nixsvg/.agents/rules/experience.md)
