import 'dart:io' as io;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remixicon/remixicon.dart';

/// Resilient file picker that wraps [FilePicker.platform.pickFiles],
/// catching missing native Linux dependencies (such as `zenity`) and
/// providing an in-app fallback dialog and setup guidance.
class SafeFilePicker {
  const SafeFilePicker._();

  /// Picks files safely, catching Linux `zenity` missing executable exceptions
  /// and presenting a graceful fallback dialog.
  static Future<FilePickerResult?> pickFiles({
    required BuildContext context,
    required List<String> allowedExtensions,
    bool allowMultiple = false,
  }) async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        withData: true,
      );
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (!kIsWeb &&
          defaultTargetPlatform == TargetPlatform.linux &&
          (errorStr.contains('zenity') || errorStr.contains('kdialog'))) {
        if (!context.mounted) return null;
        return await showDialog<FilePickerResult>(
          context: context,
          barrierDismissible: true,
          builder: (dialogContext) => ZenityMissingFallbackDialog(
            allowedExtensions: allowedExtensions,
          ),
        );
      }
      rethrow;
    }
  }
}

/// Fallback file selector dialog presented when native Linux file dialogs
/// (`zenity` or `kdialog`) are not installed on the host system.
class ZenityMissingFallbackDialog extends StatefulWidget {
  final List<String> allowedExtensions;

  const ZenityMissingFallbackDialog({
    super.key,
    required this.allowedExtensions,
  });

  @override
  State<ZenityMissingFallbackDialog> createState() =>
      _ZenityMissingFallbackDialogState();
}

class _ZenityMissingFallbackDialogState
    extends State<ZenityMissingFallbackDialog> {
  late final TextEditingController _pathController;
  String? _errorMessage;
  bool _copied = false;
  List<io.FileSystemEntity> _filesInDirectory = [];
  String _currentDirectoryPath = '';

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController();
    _loadInitialDirectory();
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  void _loadInitialDirectory() {
    try {
      final homeDir = io.Platform.environment['HOME'] ?? '';
      final downloadsDir = io.Directory('$homeDir/Downloads');
      if (downloadsDir.existsSync()) {
        _scanDirectory(downloadsDir.path);
      } else if (io.Directory(homeDir).existsSync()) {
        _scanDirectory(homeDir);
      } else {
        _scanDirectory(io.Directory.current.path);
      }
    } catch (_) {
      _scanDirectory(io.Directory.current.path);
    }
  }

  void _scanDirectory(String dirPath) {
    try {
      final dir = io.Directory(dirPath);
      if (!dir.existsSync()) return;

      final entities = dir.listSync().where((entity) {
        if (entity is io.File) {
          final ext = entity.path.split('.').last.toLowerCase();
          return widget.allowedExtensions.contains(ext);
        }
        return false;
      }).toList();

      setState(() {
        _currentDirectoryPath = dirPath;
        _filesInDirectory = entities;
      });
    } catch (e) {
      debugPrint('Error scanning directory: $e');
    }
  }

  void _submitFilePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid file path.');
      return;
    }

    final file = io.File(trimmed);
    if (!file.existsSync()) {
      setState(() => _errorMessage = 'File not found at specified path.');
      return;
    }

    final ext = trimmed.split('.').last.toLowerCase();
    if (!widget.allowedExtensions.contains(ext)) {
      setState(() => _errorMessage =
          'Unsupported file extension: .$ext (Allowed: ${widget.allowedExtensions.join(', ')})');
      return;
    }

    try {
      final bytes = file.readAsBytesSync();
      final normalized = trimmed.replaceAll('\\', '/');
      final fileName = normalized.split('/').last;

      final result = FilePickerResult([
        PlatformFile(
          name: fileName,
          path: trimmed,
          size: bytes.length,
          bytes: bytes,
        ),
      ]);

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to read file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final homeDir = io.Platform.environment['HOME'] ?? '';
    final shortcuts = <String, String>{
      'Downloads': '$homeDir/Downloads',
      'Documents': '$homeDir/Documents',
      'Pictures': '$homeDir/Pictures',
      'Home': homeDir,
    };

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.25),
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      RemixIcons.terminal_box_line,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Native File Picker Missing (Zenity)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Linux desktop file dialogs require the zenity package.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(RemixIcons.close_line, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Install Command Code Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To enable native dialogs, run in terminal:',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            'sudo apt install -y zenity',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.tonal(
                      onPressed: () {
                        Clipboard.setData(
                          const ClipboardData(text: 'sudo apt install -y zenity'),
                        );
                        setState(() => _copied = true);
                        Future.delayed(
                          const Duration(seconds: 2),
                          () {
                            if (mounted) setState(() => _copied = false);
                          },
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _copied
                                ? RemixIcons.check_line
                                : RemixIcons.file_copy_line,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(_copied ? 'Copied!' : 'Copy'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Section Header
              Text(
                'Or select a file directly below:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Quick Folder Chips
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: shortcuts.entries.map((entry) {
                  final isCurrent = _currentDirectoryPath == entry.value;
                  return ActionChip(
                    avatar: Icon(
                      RemixIcons.folder_line,
                      size: 14,
                      color: isCurrent
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    label: Text(entry.key),
                    onPressed: () => _scanDirectory(entry.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // Files in current directory list
              if (_filesInDirectory.isNotEmpty) ...[
                Text(
                  'Matching files in ${_currentDirectoryPath.split('/').last}:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  constraints: const BoxConstraints(maxHeight: 140),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filesInDirectory.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.2)),
                    itemBuilder: (context, index) {
                      final item = _filesInDirectory[index];
                      final name = item.path.split('/').last;
                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            RemixIcons.file_line,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          title: Text(
                            name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            RemixIcons.arrow_right_s_line,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onTap: () {
                            _pathController.text = item.path;
                            _submitFilePath(item.path);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Manual File Path Text Input
              TextField(
                controller: _pathController,
                decoration: InputDecoration(
                  hintText: '/home/user/my_vector.svg',
                  labelText: 'File Path',
                  prefixIcon: const Icon(RemixIcons.file_line, size: 18),
                  errorText: _errorMessage,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(RemixIcons.check_line),
                    tooltip: 'Load File',
                    onPressed: () => _submitFilePath(_pathController.text),
                  ),
                ),
                onSubmitted: _submitFilePath,
              ),

              const SizedBox(height: 16),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _submitFilePath(_pathController.text),
                    child: const Text('Import File'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
