---
trigger: always_on
---

# Cross-Platform Compatibility & Responsive Design Rules

**nixSVG** is built to run flawlessly across **macOS, Windows, Linux, Web, Android, and iOS** across portrait and landscape orientations.

Agents must rigorously adhere to the following responsive design and platform adaptivity rules:

## 1. Dynamic Layout Architecture (`ResponsiveLayoutTokens`)
All panel dimensions, top navigation bar heights, sidebar widths, and toolbar locations must be computed dynamically using `ResponsiveLayoutTokens`:

### A. Top Navigation Bar (`TopNavigationBar`)
- **Desktop (macOS, Windows, Linux) / Ultra-wide (width ≥ 1200px)**: Height = `46.0px`.
- **Tablet / Medium Screens (width ≥ 600px)**:
  - Landscape: `42.0px`.
  - Portrait: `44.0px`.
- **Small Mobile Screens (width < 600px)**:
  - Landscape: `38.0px`.
  - Portrait: `42.0px`.
- Must accommodate system status bars and window title bar controls natively.

### B. Sidebars (Layers Sidebar & Properties Sidebar)
- **Desktop & Wide Displays (width ≥ 900px)**:
  - Persistent left (`LayersSidebar`) and right (`PropertiesSidebar`) columns.
  - User-resizable using `SidebarResizeHandle`.
  - Bounded by `ResponsiveLayoutTokens.getMaxSidebarWidth(screenWidth)`:
    - 4K / Ultrawide (width ≥ 1920px): clamped up to `28%` of screen width (max `520.0px`).
    - Standard Desktop / Laptop: clamped up to `35%` of screen width (max `420.0px`).
- **Compact Viewports & Mobile Phones (width < 900px)**:
  - Sidebars automatically transition into **Off-Canvas Drawers** or **M3E Modal Bottom Sheets**.
  - Width is calculated via `ResponsiveLayoutTokens.getCompactDrawerWidth(screenWidth)` (`85%` of width, clamped between `240.0px` and `380.0px`).
  - Activated by top bar or bottom navigation toggle buttons.

### C. Floating Toolbar (`FloatingToolBar`)
- **Dynamic Scale Factor**:
  - Small phones (<400px width): Scale `0.84`.
  - Standard mobile (<600px width): Scale `0.92`.
  - Ultrawide desktop (≥2000px): Scale `1.05`.
  - Standard desktop / tablet: Scale `1.0`.
- **Bottom Margin & Safe Areas**:
  - Calculated via `ResponsiveLayoutTokens.getFloatingToolbarBottomMargin(context)`:
  - Fully respects `MediaQuery.padding.bottom` (iOS Home Indicator, Android navigation bars).
  - Landscape phone mode with compact height (<500px): compact margin (`8.0px + bottomInset`).

## 2. Platform-Specific Modality & Capabilities
- **Desktop (macOS, Windows, Linux)**:
  - Full desktop keyboard shortcuts (`Cmd` on macOS, `Ctrl` on Windows/Linux).
  - Two-finger trackpad pinch-zoom and scroll wheel panning.
  - Hover cursors (`SystemMouseCursors.resizeLeftRight`, `move`, `precise`).
  - Right-click context menus on canvas elements and layers.
- **Web**:
  - Context menu prevention (`BrowserContextMenu.disableContextMenu()`) to allow vector app right-click menus without default browser context interference.
  - Cross-browser mouse wheel handling and web-safe file picking via `file_picker`.
- **Mobile (Android & iOS)**:
  - Multi-touch gesture recognition for pinch-to-zoom and two-finger canvas panning.
  - Touch target sizing must meet or exceed accessibility guidelines (minimum 44x44px touchable areas).
  - Device orientation change triggers immediate, smooth reflow without resetting canvas pan/zoom coordinates or active document state.
