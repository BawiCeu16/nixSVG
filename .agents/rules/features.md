---
trigger: always_on
---

# Feature Specifications & Functional Requirements

Every agent contributing to **nixSVG** must understand, preserve, and enhance the following core feature systems:

## 1. Infinite Vector Canvas & Viewport
- **Navigation & Transformations**:
  - Smooth pan (`InteractiveViewer` / custom transformation matrix), zoom (with mouse wheel, trackpad pinch, or multi-touch gestures).
  - Canvas coordinate system conversion between screen coordinates and world vector space (`CanvasTransform.screenToWorld` and `worldToScreen`).
- **Snapping & Alignment Grid**:
  - Configurable grid rendering (`GridPainter`) with dynamic subdivisions based on current zoom level.
  - Snap-to-grid, snap-to-guides, and bounding-box alignment snaps.
- **Selection & Multi-Selection**:
  - Marquee drag selection, direct shape selection, multi-selection (Shift+Click / Cmd+Click).
  - Transform handles (corner scale, edge scale, rotation handle) with interactive hit-testing (`CanvasHitTest`).

## 2. Shape Primitives & Vector Tools
- **Primitive Shapes**:
  - Rectangles, Rounded Rectangles (with uniform or individual corner radii).
  - Circles, Ellipses, Stars, Polygons, and Lines.
- **Path & Pen Tooling**:
  - Multi-node Bézier curves, freehand drawing paths with point smoothing algorithms.
  - Vector node editing (anchor points, control handles).
- **Inline Text & Typography**:
  - Canvas inline text editing (`CanvasInlineTextEditor`) with Google Sans / dynamic typography.
  - Font size, letter spacing, line height, font weight, and text alignment.

## 3. Properties Inspector & Numerical Scrubbing
- **Figma-Style Scrubbing**:
  - Drag-to-scrub numerical values (`X`, `Y`, `Width`, `Height`, `Rotation`, `Corner Radius`, `Stroke Width`, `Opacity`).
  - Single-click to type exact values; arrow key increments/decrements with Shift/Alt modifiers.
- **Color & Fill Management**:
  - Solid fills, linear and radial gradients, strokes (inner, center, outer), dash patterns.
  - High-precision Color Picker (`NixColorPickerPresenter`, `ColorPickerDialog`) supporting HEX, RGB, HSL, alpha channels, and preset palettes.
- **Layer Blend Modes & Effects**:
  - Opacity sliders, drop shadows, inner shadows, blur effects, and blend modes.

## 4. Layer Tree & Hierarchy Management
- **Layer Operations**:
  - Reordering (drag-and-drop layer hierarchy, Bring to Front, Send to Back).
  - Grouping (`Cmd/Ctrl+G`) and Ungrouping (`Cmd/Ctrl+Shift+G`).
  - Visibility toggling (show/hide eye icon), locking (lock/unlock toggle).
  - Rename layers directly in the layer sidebar (`LayersSidebar`).

## 5. History & State Recovery
- **Deterministic Undo / Redo**:
  - Managed via `UndoRedoManager` supporting infinite/configurable history depth.
  - Scrubbing, dragging, and transformation operations must batch actions properly so single gestures create a single undo step.

## 6. SVG Import & Export Engine
- **SVG Generation (`SvgExportService`, `ExportDialog`)**:
  - Clean, valid, standards-compliant SVG markup with proper `<defs>`, `<rect>`, `<circle>`, `<path>`, `<text>`, and `<style>` attributes.
  - High-resolution raster export (PNG, WebP,Jpeg etc.) with user-selectable scale factors (1x, 2x, 3x, 4x).
- **Import**:
  - Parsing incoming SVG XML nodes into native `VectorShape` models while preserving transforms and styles.

## 7. Keyboard Shortcuts & Accelerators
- Standard desktop shortcuts:
  - `V` for Select tool, `R` for Rectangle, `O` for Oval/Ellipse, `T` for Text, `P` for Pen/Path.
  - `Space + Drag` for Canvas Hand Pan.
  - `Cmd/Ctrl + Z` for Undo, `Cmd/Ctrl + Shift + Z` (or `Cmd/Ctrl + Y`) for Redo.
  - `Delete` / `Backspace` to remove selected shapes.
  - `Cmd/Ctrl + D` to Duplicate in place.