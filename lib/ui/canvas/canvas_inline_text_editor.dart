import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nixsvg/models/vector_shape.dart';

/// An interactive, canvas-anchored inline text editor for editing typography shapes directly
/// on the canvas, matching Figma's signature text editing experience and styling.
class CanvasInlineTextEditor extends StatefulWidget {
  final VectorShape shape;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onCommit;
  final VoidCallback? onCancel;
  final ValueChanged<Rect>? onRectChanged;
  final bool isNew;
  final bool selectAll;

  const CanvasInlineTextEditor({
    super.key,
    required this.shape,
    required this.onTextChanged,
    required this.onCommit,
    this.onCancel,
    this.onRectChanged,
    this.isNew = false,
    this.selectAll = false,
  });

  @override
  State<CanvasInlineTextEditor> createState() => _CanvasInlineTextEditorState();
}

class _CanvasInlineTextEditorState extends State<CanvasInlineTextEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isCommitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.shape.textContent);
    _focusNode = FocusNode(
      debugLabel: 'CanvasInlineTextEditorFocus',
      onKeyEvent: _handleKeyEvent,
    );

    if (widget.isNew || widget.selectAll) {
      if (widget.shape.textContent.isEmpty) {
        _controller.text = '';
      } else {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      }
    } else {
      // Position cursor at end of existing text
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }

    _focusNode.addListener(_handleFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && !_isCommitted) {
      _commit();
    }
  }

  void _commit() {
    if (_isCommitted) return;
    _isCommitted = true;
    widget.onCommit();
  }

  void _handleTextChanged(String newText) {
    widget.onTextChanged(newText);

    // Dynamic auto-expansion without arbitrary distortion
    final style = widget.shape.getTextStyle();
    final painter = TextPainter(
      text: TextSpan(text: newText.isEmpty ? ' ' : newText, style: style),
      textAlign: widget.shape.textAlign,
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    final textWidth = math.max(24.0, painter.width + 4.0);
    final textHeight = math.max(18.0, painter.height);

    if (widget.isNew ||
        textWidth > widget.shape.rect.width ||
        textHeight > widget.shape.rect.height) {
      final updatedWidth = widget.isNew
          ? textWidth
          : math.max(widget.shape.rect.width, textWidth);
      final updatedHeight = widget.isNew
          ? textHeight
          : math.max(widget.shape.rect.height, textHeight);
      final updatedRect = Rect.fromLTWH(
        widget.shape.rect.left,
        widget.shape.rect.top,
        updatedWidth,
        updatedHeight,
      );
      widget.onRectChanged?.call(updatedRect);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _commit();
        return KeyEventResult.handled;
      }
      final isCmdOrCtrl =
          HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed;
      if (isCmdOrCtrl &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
        _commit();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  void didUpdateWidget(covariant CanvasInlineTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shape.textContent != widget.shape.textContent &&
        _controller.text != widget.shape.textContent) {
      final oldSelection = _controller.selection;
      _controller.text = widget.shape.textContent;
      _controller.selection = oldSelection;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final shape = widget.shape;
    final textStyle = shape.getTextStyle();

    // Editor frame coordinates matching shape.rect and rotation exactly
    final rect = shape.rect;
    final width = math.max(rect.width, 20.0);
    final height = math.max(rect.height, 16.0);

    // Calculate vertical offset matching VectorCanvasPainter._drawShape
    final textPainter = shape.getTextPainter();
    double offsetY = 0.0;
    if (shape.textVerticalAlign == TextVerticalAlign.center) {
      offsetY = math.max(0.0, (height - textPainter.height) / 2);
    } else if (shape.textVerticalAlign == TextVerticalAlign.bottom) {
      offsetY = math.max(0.0, height - textPainter.height);
    }

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: shape.rotation * math.pi / 180.0,
        alignment: Alignment.center,
        child: MediaQuery.withNoTextScaling(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Signature Figma text frame outline (placed outside text bounds)
              Positioned(
                left: -2,
                top: -2,
                right: -2,
                bottom: -2,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2.0),
                      color: colorScheme.surface.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              ),

              // TextField positioned with pixel-perfect alignment matching TextPainter
              Positioned(
                left: 0,
                top: offsetY,
                width: width,
                height: math.max(height - offsetY, (textStyle.fontSize ?? 16.0) * 1.2),
                child: TextField(
                  focusNode: _focusNode,
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlign: shape.textAlign,
                  style: textStyle,
                  strutStyle: StrutStyle.fromTextStyle(
                    textStyle,
                    forceStrutHeight: true,
                  ),
                  cursorColor: colorScheme.primary,
                  cursorWidth: 2.0,
                  cursorRadius: const Radius.circular(1.0),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _handleTextChanged,
                ),
              ),

              // Figma-style corner anchor pips
              _buildCornerPip(Alignment.topLeft, colorScheme.primary),
              _buildCornerPip(Alignment.topRight, colorScheme.primary),
              _buildCornerPip(Alignment.bottomLeft, colorScheme.primary),
              _buildCornerPip(Alignment.bottomRight, colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerPip(Alignment alignment, Color color) {
    const double pipSize = 5.0;
    return Align(
      alignment: alignment,
      child: Container(
        width: pipSize,
        height: pipSize,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1.0),
        ),
      ),
    );
  }
}
