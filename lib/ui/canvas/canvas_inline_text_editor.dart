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

  const CanvasInlineTextEditor({
    super.key,
    required this.shape,
    required this.onTextChanged,
    required this.onCommit,
    this.onCancel,
    this.onRectChanged,
    this.isNew = false,
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
    _focusNode = FocusNode(debugLabel: 'CanvasInlineTextEditorFocus');

    if (widget.isNew) {
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

    // Dynamic auto-expansion if text overflows bounding box
    final style = widget.shape.getTextStyle();
    final painter = TextPainter(
      text: TextSpan(text: newText.isEmpty ? ' ' : newText, style: style),
      textAlign: widget.shape.textAlign,
      textDirection: TextDirection.ltr,
    );
    painter.layout(minWidth: 10.0, maxWidth: double.infinity);

    final requiredWidth = math.max(
      widget.shape.rect.width,
      painter.width + 16.0,
    );
    final requiredHeight = math.max(
      widget.shape.rect.height,
      painter.height + 8.0,
    );

    if (requiredWidth > widget.shape.rect.width ||
        requiredHeight > widget.shape.rect.height) {
      final updatedRect = Rect.fromLTWH(
        widget.shape.rect.left,
        widget.shape.rect.top,
        requiredWidth,
        requiredHeight,
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

    // Editor frame coordinates matching shape.rect and rotation
    final rect = shape.rect;
    final width = math.max(rect.width, 100.0);
    final height = math.max(rect.height, 36.0);

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: shape.rotation * math.pi / 180.0,
        alignment: Alignment.center,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Signature Figma text frame outline
              Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.primary, width: 1.5),
                  borderRadius: BorderRadius.circular(2.0),
                  color: colorScheme.surface.withValues(alpha: 0.1),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 2.0,
                  vertical: 1.0,
                ),
                alignment: _getAlignment(
                  shape.textAlign,
                  shape.textVerticalAlign,
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlign: shape.textAlign,
                  style: textStyle,
                  cursorColor: colorScheme.primary,
                  cursorWidth: 2.0,
                  cursorRadius: const Radius.circular(1.0),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
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

  Alignment _getAlignment(TextAlign hAlign, TextVerticalAlign vAlign) {
    double x = -1.0;
    if (hAlign == TextAlign.center) {
      x = 0.0;
    } else if (hAlign == TextAlign.right) {
      x = 1.0;
    }

    double y = -1.0;
    if (vAlign == TextVerticalAlign.center) {
      y = 0.0;
    } else if (vAlign == TextVerticalAlign.bottom) {
      y = 1.0;
    }

    return Alignment(x, y);
  }
}
