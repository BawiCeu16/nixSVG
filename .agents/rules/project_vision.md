---
trigger: always_on
---

# Project Vision: nixSVG (Vector Studio)

## 1. What Are We Building?
**nixSVG** is a high-performance, professional-grade, cross-platform Vector Graphic Design Studio and SVG Editor built natively in Flutter.

It is engineered to blend:
- The **precision, power, and intuitive canvas workflows** of modern industry-standard vector tools (Figma, Sketch, Adobe Illustrator).
- The **tactile fluidity, elegance, and solid polish** of native desktop applications.
- The **modern styling language of Material 3 Expressive (M3E)**, delivering vibrant, dynamic, and adaptive interfaces.

## 2. Core Pillars & Architecture
1. **Precision Vector Engine**:
   - Built on direct Flutter `CustomPainter` rendering (`VectorCanvasPainter`, `GridPainter`).
   - Rigorous mathematical models for coordinate transformation (`CanvasTransform`), 2D geometry (`CanvasGeometry`), and collision/selection detection (`CanvasHitTest`).
2. **Reactive State Management**:
   - Powered by **Flutter Riverpod** (`StateNotifier`, `Provider`, `NotifierProvider`) for deterministic, granular, and reactive state updates across canvas, layers, toolbar, and properties sidebars.
3. **Dynamic Theming & Customization**:
   - Reactive theme engine (`themeProvider`, `appSettingsProvider`) with dynamic M3E seed colors, dark/light modes, and persistent storage via `SharedPreferences`.
4. **Cross-Platform First**:
   - A single, unified codebase targeting **macOS, Windows, Linux, Web, Android, and iOS** without compromising on platform-specific idioms.