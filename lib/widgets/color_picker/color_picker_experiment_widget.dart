import 'package:flutter/material.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:remixicon/remixicon.dart';

import 'package:nixsvg/models/vector_shape.dart';

import 'nix_color_models.dart';
import 'nix_color_picker.dart';
import 'nix_color_picker_presenter.dart';

/// Interactive Experiment & Playground widget to test the custom Material 3 Expressive
/// Color & Gradient Picker across all platforms, presentation modes, color codes,
/// Eyedropper, and Pick & Drop tools.
class ColorPickerExperimentWidget extends StatefulWidget {
  const ColorPickerExperimentWidget({super.key});

  @override
  State<ColorPickerExperimentWidget> createState() =>
      _ColorPickerExperimentWidgetState();
}

class _ColorPickerExperimentWidgetState
    extends State<ColorPickerExperimentWidget> {
  Color _pickedColor = const Color(0xFF6366F1); // Default Indigo
  ColorPickerMode _activeMode = ColorPickerMode.solid;
  ShapeGradient _pickedGradient = const ShapeGradient(
    type: PaintFillType.linearGradient,
    stops: [
      GradientColorStop(offset: 0.0, color: Color(0xFF6366F1)),
      GradientColorStop(offset: 1.0, color: Color(0xFF38BDF8)),
    ],
    angle: 90.0,
  );

  int _presentationMode =
      0; // 0: Adaptive Popover, 1: Centered Dialog, 2: Embedded Inline
  final GlobalKey _triggerButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rgba = NixColorUtils.toRgba(_pickedColor);
    final hsla = NixColorUtils.toHsla(_pickedColor);
    final hsva = NixColorUtils.toHsva(_pickedColor);
    final hexCode = NixColorUtils.toHex(_pickedColor, includeAlpha: true);
    final cssCode = NixColorUtils.toCssString(
      color: _pickedColor,
      gradient: _pickedGradient,
      mode: _activeMode,
    );

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _pickedColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      RemixIcons.flask_line,
                      color: _pickedColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COLOR & GRADIENT LAB',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Gradient, Eyedropper, Pick & Drop, and all color codes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(RemixIcons.close_line),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Presentation Mode Switcher (Popover vs Dialog vs Inline)
              Text(
                'PRESENTATION MODE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment<int>(
                    value: 0,
                    icon: Icon(RemixIcons.window_line, size: 14),
                    label: Text('Adaptive Popover'),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    icon: Icon(RemixIcons.chat_1_line, size: 14),
                    label: Text('Modal Dialog'),
                  ),
                  ButtonSegment<int>(
                    value: 2,
                    icon: Icon(RemixIcons.layout_bottom_line, size: 14),
                    label: Text('Embedded Inline'),
                  ),
                ],
                selected: {_presentationMode},
                onSelectionChanged: (newSelection) {
                  setState(() => _presentationMode = newSelection.first);
                },
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Live Hero Visualizer Box (Supports Solid and Gradients!)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        height: 96,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _activeMode == ColorPickerMode.solid
                              ? _pickedColor
                              : null,
                          gradient: _activeMode != ColorPickerMode.solid
                              ? LinearGradient(
                                  colors: _pickedGradient.stops
                                      .map((s) => s.color)
                                      .toList(),
                                  stops: _pickedGradient.stops
                                      .map((s) => s.offset)
                                      .toList(),
                                )
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _pickedColor.withValues(alpha: 0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _activeMode == ColorPickerMode.solid
                                    ? hexCode
                                    : '${_activeMode.label} Gradient',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (_presentationMode != 2)
                              M3EButton(
                                key: _triggerButtonKey,
                                onPressed: _launchColorPicker,
                                style: M3EButtonStyle.filled,
                                size: M3EButtonSize.sm,
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(RemixIcons.palette_line, size: 14),
                                    SizedBox(width: 6),
                                    Text('Open Color & Gradient'),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CSS Output Card
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'CSS:',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cssCode,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Code breakdown cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildCodeCard(
                              theme,
                              colorScheme,
                              title: 'RGB',
                              code: 'rgb(${rgba.r}, ${rgba.g}, ${rgba.b})',
                              sub: 'Alpha: ${rgba.aPct}%',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCodeCard(
                              theme,
                              colorScheme,
                              title: 'HSL',
                              code:
                                  'hsl(${hsla.h}°, ${hsla.sPct}%, ${hsla.lPct}%)',
                              sub: 'Alpha: ${hsla.aPct}%',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCodeCard(
                              theme,
                              colorScheme,
                              title: 'HSV',
                              code:
                                  'hsv(${hsva.h}°, ${hsva.sPct}%, ${hsva.vPct}%)',
                              sub: 'Alpha: ${hsva.aPct}%',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // If inline mode is selected, show embedded widget directly!
                      if (_presentationMode == 2) ...[
                        Text(
                          'LIVE EMBEDDED WIDGET',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: NixColorPicker(
                            initialColor: _pickedColor,
                            initialGradient: _pickedGradient,
                            enableGradient: true,
                            title: 'Interactive Color & Gradient Picker',
                            showHeader: false,
                            showActions: false,
                            width: double.infinity,
                            onColorChanged: (c) =>
                                setState(() => _pickedColor = c),
                            onGradientChanged: (g) =>
                                setState(() => _pickedGradient = g),
                            onModeChanged: (m) =>
                                setState(() => _activeMode = m),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchColorPicker() {
    final RenderBox? box =
        _triggerButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final Rect? anchor = box != null && box.hasSize
        ? (box.localToGlobal(Offset.zero) & box.size)
        : null;

    showNixColorPicker(
      context: context,
      initialColor: _pickedColor,
      initialGradient: _pickedGradient,
      enableGradient: true,
      initialMode: _activeMode,
      title: 'Experiment Color & Gradient',
      anchorRect: _presentationMode == 0 ? anchor : null,
      forcePopover: _presentationMode == 0,
      forceDialog: _presentationMode == 1,
      onColorChanged: (c) => setState(() => _pickedColor = c),
      onGradientChanged: (g) => setState(() => _pickedGradient = g),
      onModeChanged: (m) => setState(() => _activeMode = m),
    );
  }

  Widget _buildCodeCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required String title,
    required String code,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            code,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
