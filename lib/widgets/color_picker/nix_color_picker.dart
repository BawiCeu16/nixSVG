import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:m3e_buttons/m3e_buttons.dart';
import 'package:remixicon/remixicon.dart';

import 'package:nixsvg/models/vector_shape.dart';
import 'nix_color_models.dart';
import 'nix_color_spectrum_painter.dart';
import 'nix_eyedropper_overlay.dart';

/// Next-generation Material 3 Expressive Color & Gradient Picker
/// Supporting all platforms, all color codes (HEX, RGBA, HSLA, HSVA),
/// interactive Gradient Stop editing, Eyedropper, Pick-and-Drop swatches,
/// and professional contrast / harmony tools with macOS-level fluid polish.
class NixColorPicker extends StatefulWidget {
  final Color initialColor;
  final ShapeGradient? initialGradient;
  final bool enableGradient;
  final ColorPickerMode? initialMode;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<ShapeGradient>? onGradientChanged;
  final ValueChanged<ColorPickerMode>? onModeChanged;
  final ValueChanged<Color>? onColorFinalized;
  final VoidCallback? onClose;
  final String title;
  final bool showHeader;
  final bool showActions;
  final double width;

  const NixColorPicker({
    super.key,
    required this.initialColor,
    this.initialGradient,
    this.enableGradient = true,
    this.initialMode,
    required this.onColorChanged,
    this.onGradientChanged,
    this.onModeChanged,
    this.onColorFinalized,
    this.onClose,
    this.title = 'Color & Gradient',
    this.showHeader = true,
    this.showActions = true,
    this.width = 330,
  });

  @override
  State<NixColorPicker> createState() => _NixColorPickerState();
}

class _NixColorPickerState extends State<NixColorPicker> {
  late ColorPickerMode _mode;
  late double _hue;
  late double _saturation;
  late double _value;
  late double _alpha;
  late Color _currentColor;
  ColorCodeFormat _currentFormat = ColorCodeFormat.hex;

  // Gradient state
  late ShapeGradient _gradient;
  int _selectedStopIndex = 0;

  bool _isCopied = false;

  // Custom user swatches (saved via Pick & Drop or + button)
  final List<Color> _userSwatches = [
    const Color(0xFF6366F1),
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF97316),
    const Color(0xFFEF4444),
    const Color(0xFFA855F7),
  ];

  // Direct text input controllers
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _c1Controller = TextEditingController();
  final TextEditingController _c2Controller = TextEditingController();
  final TextEditingController _c3Controller = TextEditingController();
  final TextEditingController _c4Controller = TextEditingController();

  final FocusNode _hexFocus = FocusNode();
  final FocusNode _c1Focus = FocusNode();
  final FocusNode _c2Focus = FocusNode();
  final FocusNode _c3Focus = FocusNode();
  final FocusNode _c4Focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode ??
        (widget.initialGradient != null
            ? (widget.initialGradient!.type == PaintFillType.radialGradient
                ? ColorPickerMode.radialGradient
                : ColorPickerMode.linearGradient)
            : ColorPickerMode.solid);

    _gradient = widget.initialGradient ??
        ShapeGradient(
          type: _mode == ColorPickerMode.radialGradient
              ? PaintFillType.radialGradient
              : PaintFillType.linearGradient,
          stops: [
            GradientColorStop(offset: 0.0, color: widget.initialColor),
            const GradientColorStop(offset: 1.0, color: Color(0xFF38BDF8)),
          ],
          angle: 90.0,
        );

    _initFromColor(widget.initialColor);
  }

  @override
  void didUpdateWidget(covariant NixColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor &&
        _currentColor != widget.initialColor) {
      _initFromColor(widget.initialColor);
    }
    if (widget.initialGradient != null &&
        widget.initialGradient != oldWidget.initialGradient) {
      _gradient = widget.initialGradient!;
    }
  }

  @override
  void dispose() {
    _hexController.dispose();
    _c1Controller.dispose();
    _c2Controller.dispose();
    _c3Controller.dispose();
    _c4Controller.dispose();
    _hexFocus.dispose();
    _c1Focus.dispose();
    _c2Focus.dispose();
    _c3Focus.dispose();
    _c4Focus.dispose();
    super.dispose();
  }

  void _initFromColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    _hue = hsv.hue;
    _saturation = hsv.saturation;
    _value = hsv.value;
    _alpha = hsv.alpha;
    _currentColor = color;
    _syncTextControllers();
  }

  void _updateActiveColor({
    double? hue,
    double? saturation,
    double? value,
    double? alpha,
    bool updateControllers = true,
  }) {
    setState(() {
      if (hue != null) _hue = hue % 360;
      if (saturation != null) _saturation = saturation.clamp(0.0, 1.0);
      if (value != null) _value = value.clamp(0.0, 1.0);
      if (alpha != null) _alpha = alpha.clamp(0.0, 1.0);

      _currentColor = HSVColor.fromAHSV(_alpha, _hue, _saturation, _value).toColor();

      // If in gradient mode, update currently selected stop's color
      if (_mode != ColorPickerMode.solid) {
        final stops = List<GradientColorStop>.from(_gradient.stops);
        if (_selectedStopIndex < stops.length) {
          stops[_selectedStopIndex] =
              stops[_selectedStopIndex].copyWith(color: _currentColor);
          _gradient = _gradient.copyWith(stops: stops);
          widget.onGradientChanged?.call(_gradient);
        }
      }

      if (updateControllers) {
        _syncTextControllers();
      }
    });

    widget.onColorChanged(_currentColor);
  }

  void _syncTextControllers() {
    if (!_hexFocus.hasFocus) {
      _hexController.text =
          NixColorUtils.toHex(_currentColor, includeAlpha: false).replaceAll('#', '');
    }

    switch (_currentFormat) {
      case ColorCodeFormat.hex:
        break;
      case ColorCodeFormat.rgba:
        final rgba = NixColorUtils.toRgba(_currentColor);
        if (!_c1Focus.hasFocus) _c1Controller.text = rgba.r.toString();
        if (!_c2Focus.hasFocus) _c2Controller.text = rgba.g.toString();
        if (!_c3Focus.hasFocus) _c3Controller.text = rgba.b.toString();
        if (!_c4Focus.hasFocus) _c4Controller.text = rgba.aPct.toString();
        break;
      case ColorCodeFormat.hsla:
        final hsla = NixColorUtils.toHsla(_currentColor);
        if (!_c1Focus.hasFocus) _c1Controller.text = hsla.h.toString();
        if (!_c2Focus.hasFocus) _c2Controller.text = hsla.sPct.toString();
        if (!_c3Focus.hasFocus) _c3Controller.text = hsla.lPct.toString();
        if (!_c4Focus.hasFocus) _c4Controller.text = hsla.aPct.toString();
        break;
      case ColorCodeFormat.hsva:
        final hsva = NixColorUtils.toHsva(_currentColor);
        if (!_c1Focus.hasFocus) _c1Controller.text = hsva.h.toString();
        if (!_c2Focus.hasFocus) _c2Controller.text = hsva.sPct.toString();
        if (!_c3Focus.hasFocus) _c3Controller.text = hsva.vPct.toString();
        if (!_c4Focus.hasFocus) _c4Controller.text = hsva.aPct.toString();
        break;
    }
  }

  void _onHexChanged(String val) {
    final parsed = NixColorUtils.parseHex(val);
    if (parsed != null) {
      final hsv = HSVColor.fromColor(parsed.withValues(alpha: _alpha));
      _updateActiveColor(
        hue: hsv.hue,
        saturation: hsv.saturation,
        value: hsv.value,
        updateControllers: false,
      );
    }
  }

  void _onNumericChanged() {
    final int v1 = int.tryParse(_c1Controller.text) ?? 0;
    final int v2 = int.tryParse(_c2Controller.text) ?? 0;
    final int v3 = int.tryParse(_c3Controller.text) ?? 0;
    final int v4 = int.tryParse(_c4Controller.text) ?? (_alpha * 100).round();

    Color newColor = _currentColor;
    switch (_currentFormat) {
      case ColorCodeFormat.hex:
        break;
      case ColorCodeFormat.rgba:
        newColor = NixColorUtils.fromRgba(v1, v2, v3, v4);
        break;
      case ColorCodeFormat.hsla:
        newColor = NixColorUtils.fromHsla(v1, v2, v3, v4);
        break;
      case ColorCodeFormat.hsva:
        newColor = NixColorUtils.fromHsva(v1, v2, v3, v4);
        break;
    }

    final hsv = HSVColor.fromColor(newColor);
    _updateActiveColor(
      hue: hsv.hue,
      saturation: hsv.saturation,
      value: hsv.value,
      alpha: hsv.alpha,
      updateControllers: false,
    );
  }

  void _copyColorCode() {
    final css = NixColorUtils.toCssString(
      color: _currentColor,
      gradient: _gradient,
      mode: _mode,
    );
    Clipboard.setData(ClipboardData(text: css));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  // --------------------------------------------------------------------------
  // Professional Tools: Eyedropper, Harmonies, Random, Invert
  // --------------------------------------------------------------------------

  Future<void> _activateEyedropper() async {
    final sampled = await NixEyedropper.pickColor(
      context: context,
      initialColor: _currentColor,
    );
    if (sampled != null && mounted) {
      final hsv = HSVColor.fromColor(sampled);
      _updateActiveColor(
        hue: hsv.hue,
        saturation: hsv.saturation,
        value: hsv.value,
        alpha: hsv.alpha,
      );
    }
  }

  void _applyComplementary() {
    final comp = NixColorUtils.complementary(_currentColor);
    final hsv = HSVColor.fromColor(comp);
    _updateActiveColor(
      hue: hsv.hue,
      saturation: hsv.saturation,
      value: hsv.value,
    );
  }

  void _applyInvert() {
    final inv = NixColorUtils.invert(_currentColor);
    final hsv = HSVColor.fromColor(inv);
    _updateActiveColor(
      hue: hsv.hue,
      saturation: hsv.saturation,
      value: hsv.value,
    );
  }

  void _applyRandom() {
    final rand = NixColorUtils.randomVibrant();
    final hsv = HSVColor.fromColor(rand);
    _updateActiveColor(
      hue: hsv.hue,
      saturation: hsv.saturation,
      value: hsv.value,
    );
  }

  void _saveCurrentToUserSwatches() {
    if (!_userSwatches.contains(_currentColor)) {
      setState(() {
        _userSwatches.insert(0, _currentColor);
        if (_userSwatches.length > 12) _userSwatches.removeLast();
      });
    }
  }

  // --------------------------------------------------------------------------
  // Gradient Stop Operations
  // --------------------------------------------------------------------------

  void _addGradientStop(double offset) {
    if (_gradient.stops.length >= 8) return;
    final clamped = offset.clamp(0.0, 1.0);
    final stops = List<GradientColorStop>.from(_gradient.stops);
    final newColor = NixColorUtils.lerpGradientStops(stops, clamped);

    stops.add(GradientColorStop(offset: clamped, color: newColor));
    stops.sort((a, b) => a.offset.compareTo(b.offset));
    final newIdx = stops.indexWhere((s) => (s.offset - clamped).abs() < 0.001);

    setState(() {
      _selectedStopIndex = newIdx != -1 ? newIdx : stops.length - 1;
      _gradient = _gradient.copyWith(stops: stops);
    });

    _initFromColor(newColor);
    widget.onGradientChanged?.call(_gradient);
  }

  void _updateStopOffset(int index, double newOffset) {
    final stops = List<GradientColorStop>.from(_gradient.stops);
    final clamped = newOffset.clamp(0.0, 1.0);
    stops[index] = stops[index].copyWith(offset: clamped);
    stops.sort((a, b) => a.offset.compareTo(b.offset));

    final newIdx = stops.indexOf(
      stops.firstWhere(
        (s) => (s.offset - clamped).abs() < 0.001,
        orElse: () => stops[0],
      ),
    );

    setState(() {
      _selectedStopIndex = newIdx >= 0 ? newIdx : index;
      _gradient = _gradient.copyWith(stops: stops);
    });

    widget.onGradientChanged?.call(_gradient);
  }

  void _deleteSelectedStop() {
    if (_gradient.stops.length <= 2) return;
    final stops = List<GradientColorStop>.from(_gradient.stops);
    stops.removeAt(_selectedStopIndex);
    setState(() {
      _selectedStopIndex = _selectedStopIndex.clamp(0, stops.length - 1);
      _gradient = _gradient.copyWith(stops: stops);
    });
    _initFromColor(_gradient.stops[_selectedStopIndex].color);
    widget.onGradientChanged?.call(_gradient);
  }

  void _reverseGradientStops() {
    final stops = _gradient.stops.map((s) {
      return s.copyWith(offset: 1.0 - s.offset);
    }).toList()
      ..sort((a, b) => a.offset.compareTo(b.offset));

    setState(() {
      _gradient = _gradient.copyWith(stops: stops);
    });
    widget.onGradientChanged?.call(_gradient);
  }

  // --------------------------------------------------------------------------
  // Build Methods
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Toolbar
              if (widget.showHeader) _buildHeader(context, colorScheme),
              const SizedBox(height: 10),

              // 2. Mode Selector: Solid | Linear | Radial
              if (widget.enableGradient) ...[
                _buildModeSelector(colorScheme),
                const SizedBox(height: 10),
              ],

              // 3. Gradient Stop Track (Visible when in Gradient Mode)
              if (_mode != ColorPickerMode.solid) ...[
                _buildGradientEditor(context, colorScheme),
                const SizedBox(height: 10),
              ],

              // 4. Before / After Preview Pill with Drag-and-Drop & Contrast Check
              _buildColorPreviewRow(context, colorScheme),
              const SizedBox(height: 10),

              // 5. 2D Saturation-Value Canvas Area
              _buildSaturationValueCanvas(colorScheme),
              const SizedBox(height: 10),

              // 6. Hue Rainbow Slider & Alpha Slider
              _buildSliders(colorScheme),
              const SizedBox(height: 10),

              // 7. Format Switcher & Direct Numeric Inputs
              _buildFormatInputs(context, colorScheme),
              const SizedBox(height: 10),

              // 8. Pick & Drop Palette Swatches + Quick Actions
              _buildSwatchesSection(context, colorScheme),

              // 9. Bottom Actions
              if (widget.showActions) ...[
                const SizedBox(height: 12),
                _buildBottomActions(colorScheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(RemixIcons.palette_line, size: 15, color: colorScheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),

        // Eyedropper tool button
        _buildHeaderToolButton(
          icon: RemixIcons.sip_line,
          tooltip: 'Pick Color (Eyedropper)',
          colorScheme: colorScheme,
          onTap: _activateEyedropper,
        ),
        const SizedBox(width: 4),

        // Complementary tool button
        _buildHeaderToolButton(
          icon: RemixIcons.contrast_drop_line,
          tooltip: 'Complementary Color',
          colorScheme: colorScheme,
          onTap: _applyComplementary,
        ),
        const SizedBox(width: 4),

        // Invert tool button
        _buildHeaderToolButton(
          icon: RemixIcons.contrast_2_line,
          tooltip: 'Invert Color',
          colorScheme: colorScheme,
          onTap: _applyInvert,
        ),
        const SizedBox(width: 4),

        // Magic Random tool button
        _buildHeaderToolButton(
          icon: RemixIcons.magic_line,
          tooltip: 'Magic Random Color',
          colorScheme: colorScheme,
          onTap: _applyRandom,
        ),
        const SizedBox(width: 4),

        // Close button
        if (widget.onClose != null)
          _buildHeaderToolButton(
            icon: RemixIcons.close_line,
            tooltip: 'Close',
            colorScheme: colorScheme,
            onTap: widget.onClose!,
          ),
      ],
    );
  }

  Widget _buildHeaderToolButton({
    required IconData icon,
    required String tooltip,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildModeSelector(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: ColorPickerMode.values.map((mode) {
          final isSelected = _mode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mode = mode;
                  if (mode == ColorPickerMode.linearGradient) {
                    _gradient = _gradient.copyWith(type: PaintFillType.linearGradient);
                  } else if (mode == ColorPickerMode.radialGradient) {
                    _gradient = _gradient.copyWith(type: PaintFillType.radialGradient);
                  }
                });
                widget.onModeChanged?.call(mode);
                if (mode != ColorPickerMode.solid) {
                  widget.onGradientChanged?.call(_gradient);
                } else {
                  widget.onColorChanged(_currentColor);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGradientEditor(BuildContext context, ColorScheme colorScheme) {
    final stops = _gradient.stops;
    if (_selectedStopIndex >= stops.length) {
      _selectedStopIndex = stops.length - 1;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient track with draggable pins
          LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              const handleSize = 18.0;

              return SizedBox(
                height: 30,
                width: trackWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Clickable gradient bar
                    GestureDetector(
                      onTapUp: (details) {
                        final offset = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                        _addGradientStop(offset);
                      },
                      child: Container(
                        height: 12,
                        width: trackWidth,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                          gradient: LinearGradient(
                            colors: stops.map((s) => s.color).toList(),
                            stops: stops.map((s) => s.offset).toList(),
                          ),
                        ),
                      ),
                    ),

                    // Draggable Stop Pins
                    ...stops.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final stop = entry.value;
                      final isSelected = idx == _selectedStopIndex;
                      final thumbCenter = stop.offset * trackWidth;
                      final left = (thumbCenter - (handleSize / 2)).clamp(
                        0.0,
                        trackWidth - handleSize,
                      );

                      return Positioned(
                        left: left,
                        top: 6,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedStopIndex = idx);
                            _initFromColor(stop.color);
                          },
                          onPanUpdate: (details) {
                            final deltaOffset = details.delta.dx / trackWidth;
                            _updateStopOffset(idx, stop.offset + deltaOffset);
                          },
                          child: Container(
                            width: handleSize,
                            height: handleSize,
                            decoration: BoxDecoration(
                              color: stop.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? colorScheme.primary : Colors.white,
                                width: isSelected ? 2.5 : 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),

          // Actions row: Flip stops, Delete stop, and Angle slider (if linear)
          Row(
            children: [
              // Reverse stops
              _buildGradientActionChip(
                icon: RemixIcons.arrow_left_right_line,
                label: 'Reverse',
                colorScheme: colorScheme,
                onTap: _reverseGradientStops,
              ),
              const SizedBox(width: 6),

              // Delete stop (if > 2)
              if (stops.length > 2) ...[
                _buildGradientActionChip(
                  icon: RemixIcons.delete_bin_line,
                  label: 'Delete Stop',
                  colorScheme: colorScheme,
                  onTap: _deleteSelectedStop,
                ),
                const SizedBox(width: 6),
              ],

              const Spacer(),

              // Angle (Linear only)
              if (_mode == ColorPickerMode.linearGradient) ...[
                Text(
                  '${_gradient.angle.round()}°',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 70,
                  height: 20,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                      activeTrackColor: colorScheme.primary,
                      inactiveTrackColor: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      thumbColor: colorScheme.primary,
                    ),
                    child: Slider(
                      value: _gradient.angle % 360,
                      min: 0,
                      max: 360,
                      onChanged: (val) {
                        setState(() {
                          _gradient = _gradient.copyWith(angle: val);
                        });
                        widget.onGradientChanged?.call(_gradient);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Gradient Presets Pills
          SizedBox(
            height: 20,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: NixColorUtils.curatedGradientPresets.length,
              separatorBuilder: (_, index) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final preset = NixColorUtils.curatedGradientPresets[i];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _gradient = preset.copyWith(type: _gradient.type);
                      _selectedStopIndex = 0;
                    });
                    _initFromColor(_gradient.stops[0].color);
                    widget.onGradientChanged?.call(_gradient);
                  },
                  child: Container(
                    width: 38,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                      gradient: LinearGradient(
                        colors: preset.stops.map((s) => s.color).toList(),
                        stops: preset.stops.map((s) => s.offset).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientActionChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPreviewRow(BuildContext context, ColorScheme colorScheme) {
    final whiteContrast = NixColorUtils.contrastRatio(_currentColor, Colors.white);
    final blackContrast = NixColorUtils.contrastRatio(_currentColor, Colors.black);
    final bestContrast = math.max(whiteContrast, blackContrast);
    final rating = NixColorUtils.wcagRating(bestContrast);

    return Row(
      children: [
        // Before / After Pill with Drag & Drop capability
        Tooltip(
          message: 'Drag to drop in palette • Tap original to revert',
          child: Container(
            height: 38,
            width: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                children: [
                  const CustomPaint(
                    size: Size(90, 38),
                    painter: NixCheckerboardPainter(),
                  ),
                  Row(
                    children: [
                      // Original Color (Tap to Revert)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _initFromColor(widget.initialColor),
                          child: Container(
                            color: widget.initialColor,
                            child: const Center(
                              child: Icon(
                                RemixIcons.arrow_go_back_line,
                                size: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Current Color (Draggable!)
                      Expanded(
                        child: Draggable<Color>(
                          data: _currentColor,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _currentColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _mode == ColorPickerMode.solid
                                  ? _currentColor
                                  : null,
                              gradient: _mode != ColorPickerMode.solid
                                  ? LinearGradient(
                                      colors: _gradient.stops.map((s) => s.color).toList(),
                                      stops: _gradient.stops.map((s) => s.offset).toList(),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Hex & Copy CSS Pill
        Expanded(
          child: GestureDetector(
            onTap: _copyColorCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _mode == ColorPickerMode.solid
                              ? NixColorUtils.toHex(_currentColor)
                              : '${_mode.label} (${_gradient.stops.length} stops)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Contrast: ${bestContrast.toStringAsFixed(1)}:1 ($rating)',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isCopied ? RemixIcons.check_line : RemixIcons.file_copy_line,
                    size: 14,
                    color: _isCopied ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaturationValueCanvas(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.maxWidth;
        const boxHeight = 130.0;

        return GestureDetector(
          onPanDown: (details) {
            FocusManager.instance.primaryFocus?.unfocus();
            _handleSvGesture(details.localPosition, boxWidth, boxHeight);
          },
          onPanUpdate: (details) {
            _handleSvGesture(details.localPosition, boxWidth, boxHeight);
          },
          child: Container(
            height: boxHeight,
            width: boxWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: CustomPaint(
              size: Size(boxWidth, boxHeight),
              painter: NixSaturationValuePainter(
                hue: _hue,
                saturation: _saturation,
                value: _value,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSvGesture(Offset localPos, double width, double height) {
    final s = (localPos.dx / width).clamp(0.0, 1.0);
    final v = (1.0 - (localPos.dy / height)).clamp(0.0, 1.0);
    _updateActiveColor(saturation: s, value: v);
  }

  Widget _buildSliders(ColorScheme colorScheme) {
    return Column(
      children: [
        // Hue Rainbow Slider
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            const trackHeight = 14.0;
            return GestureDetector(
              onPanDown: (details) {
                FocusManager.instance.primaryFocus?.unfocus();
                final h = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0) * 360.0;
                _updateActiveColor(hue: h);
              },
              onPanUpdate: (details) {
                final h = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0) * 360.0;
                _updateActiveColor(hue: h);
              },
              child: Container(
                height: trackHeight,
                width: trackWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(trackHeight / 2),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: CustomPaint(
                  size: Size(trackWidth, trackHeight),
                  painter: NixHueTrackPainter(hue: _hue),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // Alpha Opacity Slider
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            const trackHeight = 14.0;
            return GestureDetector(
              onPanDown: (details) {
                FocusManager.instance.primaryFocus?.unfocus();
                final a = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                _updateActiveColor(alpha: a);
              },
              onPanUpdate: (details) {
                final a = (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                _updateActiveColor(alpha: a);
              },
              child: Container(
                height: trackHeight,
                width: trackWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(trackHeight / 2),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: CustomPaint(
                  size: Size(trackWidth, trackHeight),
                  painter: NixAlphaTrackPainter(baseColor: _currentColor, alpha: _alpha),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFormatInputs(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Format switcher pill
          Row(
            children: ColorCodeFormat.values.map((fmt) {
              final isSelected = _currentFormat == fmt;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentFormat = fmt;
                      _syncTextControllers();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        fmt.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Numeric / Hex Inputs
          if (_currentFormat == ColorCodeFormat.hex) ...[
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _hexController,
                    focusNode: _hexFocus,
                    label: 'HEX',
                    prefix: '#',
                    colorScheme: colorScheme,
                    onChanged: _onHexChanged,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 58,
                  child: _buildInputField(
                    controller: _c4Controller,
                    focusNode: _c4Focus,
                    label: 'OPACITY',
                    suffix: '%',
                    colorScheme: colorScheme,
                    onChanged: (_) {
                      final val = int.tryParse(_c4Controller.text);
                      if (val != null) {
                        _updateActiveColor(alpha: (val / 100.0).clamp(0.0, 1.0));
                      }
                    },
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _c1Controller,
                    focusNode: _c1Focus,
                    label: _currentFormat == ColorCodeFormat.rgba ? 'R' : 'H',
                    colorScheme: colorScheme,
                    onChanged: (_) => _onNumericChanged(),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildInputField(
                    controller: _c2Controller,
                    focusNode: _c2Focus,
                    label: _currentFormat == ColorCodeFormat.rgba ? 'G' : 'S',
                    suffix: _currentFormat != ColorCodeFormat.rgba ? '%' : null,
                    colorScheme: colorScheme,
                    onChanged: (_) => _onNumericChanged(),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildInputField(
                    controller: _c3Controller,
                    focusNode: _c3Focus,
                    label: _currentFormat == ColorCodeFormat.rgba
                        ? 'B'
                        : (_currentFormat == ColorCodeFormat.hsla ? 'L' : 'V'),
                    suffix: _currentFormat != ColorCodeFormat.rgba ? '%' : null,
                    colorScheme: colorScheme,
                    onChanged: (_) => _onNumericChanged(),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildInputField(
                    controller: _c4Controller,
                    focusNode: _c4Focus,
                    label: 'A',
                    suffix: '%',
                    colorScheme: colorScheme,
                    onChanged: (_) => _onNumericChanged(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required ColorScheme colorScheme,
    required ValueChanged<String> onChanged,
    String? prefix,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    prefix,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 7),
                  ),
                  onChanged: onChanged,
                ),
              ),
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    suffix,
                    style: TextStyle(fontSize: 10, color: colorScheme.outline),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwatchesSection(BuildContext context, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with Save button
        Row(
          children: [
            Text(
              'SWATCHES',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: colorScheme.outline,
                letterSpacing: 0.6,
              ),
            ),
            const Spacer(),
            _buildGradientActionChip(
              icon: RemixIcons.add_line,
              label: 'Save',
              colorScheme: colorScheme,
              onTap: _saveCurrentToUserSwatches,
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Grid of Curated Swatches (Draggable and DragTarget!)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ..._userSwatches.map((color) => _buildSwatchItem(color, colorScheme, isCustom: true)),
            ...NixColorUtils.curatedPresets.take(14).map((color) => _buildSwatchItem(color, colorScheme)),
          ],
        ),
      ],
    );
  }

  Widget _buildSwatchItem(Color color, ColorScheme colorScheme, {bool isCustom = false}) {
    final isSelected = _currentColor.toARGB32() == color.toARGB32();

    return DragTarget<Color>(
      onAcceptWithDetails: (details) {
        setState(() {
          final dropped = details.data;
          if (isCustom) {
            final idx = _userSwatches.indexOf(color);
            if (idx != -1) _userSwatches[idx] = dropped;
          } else {
            _userSwatches.insert(0, dropped);
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;

        return Draggable<Color>(
          data: color,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          child: GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
              _initFromColor(color);
              _updateActiveColor();
            },
            onLongPress: isCustom
                ? () {
                    setState(() => _userSwatches.remove(color));
                  }
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isHovered
                      ? colorScheme.primary
                      : (isSelected
                          ? colorScheme.primary
                          : (color == Colors.white
                              ? colorScheme.outlineVariant
                              : Colors.transparent)),
                  width: isHovered ? 2.5 : (isSelected ? 2.2 : 1.0),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.onClose != null)
          M3EButton(
            onPressed: widget.onClose,
            style: M3EButtonStyle.text,
            size: M3EButtonSize.sm,
            child: const Text('Cancel'),
          ),
        const SizedBox(width: 8),
        M3EButton(
          onPressed: () {
            widget.onColorFinalized?.call(_currentColor);
            widget.onClose?.call();
          },
          style: M3EButtonStyle.filled,
          size: M3EButtonSize.sm,
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
