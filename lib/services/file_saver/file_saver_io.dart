import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// IO implementation for saving exported files across macOS, Windows, Linux, Android, and iOS.
Future<String?> saveFileToDisk({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  final extension = fileName.contains('.') ? fileName.split('.').last : null;
  final allowedExtensions = extension != null ? [extension] : null;

  // Resolve initial target directory (Downloads or Documents)
  io.Directory? targetDir;
  try {
    if (io.Platform.isAndroid || io.Platform.isIOS) {
      targetDir = await getApplicationDocumentsDirectory();
    } else {
      try {
        targetDir = await getDownloadsDirectory();
      } catch (_) {}

      if (targetDir == null || !targetDir.existsSync()) {
        final home =
            io.Platform.environment['HOME'] ??
            io.Platform.environment['USERPROFILE'];
        if (home != null && home.isNotEmpty) {
          final dl = io.Directory('$home/Downloads');
          if (dl.existsSync()) {
            targetDir = dl;
          } else {
            final homeDir = io.Directory(home);
            if (homeDir.existsSync()) {
              targetDir = homeDir;
            }
          }
        }
      }
    }
  } catch (_) {}

  // 1. On Linux Desktop: Use native XDG Desktop Portal to guarantee
  // that both the fileName and format are pre-populated in the system save dialog.
  if (!kIsWeb && io.Platform.isLinux) {
    try {
      final portalResult = await _saveViaLinuxPortal(
        fileName: fileName,
        targetDir: targetDir?.path,
        bytes: bytes,
        extension: extension,
      );
      if (portalResult != null) {
        if (portalResult.isEmpty) {
          // User explicitly cancelled the dialog
          return null;
        }
        return portalResult;
      }
    } catch (e) {
      debugPrint('Linux portal save failed: $e, trying native file_picker.');
    }
  }

  // 2. Try native FilePicker saveFile dialog
  io.File? placeholderFile;
  try {
    // On Linux with zenity fallback: Zenity 4.0.1 requires the file to exist on
    // disk so that gtk_file_chooser_set_file can highlight and pre-fill the name.
    if (!kIsWeb && io.Platform.isLinux && targetDir != null) {
      try {
        final candidate = io.File('${targetDir.path}/$fileName');
        if (!candidate.existsSync()) {
          await candidate.writeAsBytes(bytes, flush: true);
          placeholderFile = candidate;
        }
      } catch (_) {}
    }

    var selectedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export $fileName',
      fileName: fileName,
      initialDirectory: targetDir?.path,
      type: allowedExtensions != null ? FileType.custom : FileType.any,
      allowedExtensions: allowedExtensions,
      bytes: bytes,
    );

    if (selectedPath != null && selectedPath.isNotEmpty) {
      if (extension != null &&
          !selectedPath.toLowerCase().endsWith('.$extension')) {
        selectedPath = '$selectedPath.$extension';
      }
      final file = io.File(selectedPath);
      await file.writeAsBytes(bytes, flush: true);

      // Clean up placeholder if saved to a different path
      if (placeholderFile != null && placeholderFile.path != file.path) {
        try {
          if (placeholderFile.existsSync()) placeholderFile.deleteSync();
        } catch (_) {}
      }

      return file.path;
    }

    // User cancelled the dialog: remove placeholder
    if (placeholderFile != null) {
      try {
        if (placeholderFile.existsSync()) placeholderFile.deleteSync();
      } catch (_) {}
    }
    return null;
  } catch (e) {
    debugPrint(
      'Native FilePicker saveFile failed: $e. Falling back to local storage directory.',
    );

    // Clean up placeholder if any
    if (placeholderFile != null) {
      try {
        if (placeholderFile.existsSync()) placeholderFile.deleteSync();
      } catch (_) {}
    }

    // 3. Fallback for systems without GUI dialog tools
    try {
      targetDir ??= await getApplicationDocumentsDirectory();

      if (!targetDir.existsSync()) {
        await targetDir.create(recursive: true);
      }

      final fallbackFile = io.File('${targetDir.path}/$fileName');
      await fallbackFile.writeAsBytes(bytes, flush: true);
      return fallbackFile.path;
    } catch (fallbackError) {
      debugPrint('Fallback file save failed: $fallbackError');
      rethrow;
    }
  }
}

/// Invokes modern XDG Desktop Portal FileChooser via DBus on Linux.
///
/// Returns:
/// - String path if user confirmed and saved file
/// - Empty string `""` if user explicitly cancelled the dialog
/// - `null` if portal is unavailable or python/dbus failed
Future<String?> _saveViaLinuxPortal({
  required String fileName,
  required String? targetDir,
  required Uint8List bytes,
  required String? extension,
}) async {
  final formatLabel = switch (extension?.toLowerCase()) {
    'png' => 'PNG Image',
    'jpeg' || 'jpg' => 'JPEG Image',
    'svg' => 'SVG Vector Graphic',
    'pdf' => 'PDF Document',
    _ => 'Document',
  };

  const script = r'''
import sys, os, time, urllib.parse

try:
    import dbus
    from dbus.mainloop.glib import DBusGMainLoop
    from gi.repository import GLib

    file_name = sys.argv[1]
    initial_dir = sys.argv[2]
    format_label = sys.argv[3]
    ext = sys.argv[4].lstrip('.')

    DBusGMainLoop(set_as_default=True)
    bus = dbus.SessionBus()
    loop = GLib.MainLoop()

    portal = bus.get_object('org.freedesktop.portal.Desktop', '/org/freedesktop/portal/desktop')
    fc = dbus.Interface(portal, 'org.freedesktop.portal.FileChooser')

    token = f"nixsvg_{int(time.time()*1000)}"

    f_main = dbus.Struct((dbus.String(f"{format_label} (*.{ext})"), [dbus.Struct((dbus.UInt32(0), dbus.String(f"*.{ext}")), signature='us')]), signature='sa(us)')
    f_all = dbus.Struct((dbus.String('All Files (*)'), [dbus.Struct((dbus.UInt32(0), dbus.String('*')), signature='us')]), signature='sa(us)')
    filters = dbus.Array([f_main, f_all], signature='(sa(us))')

    options = {
        'handle_token': token,
        'current_name': dbus.String(file_name),
        'filters': filters,
        'current_filter': f_main,
    }

    if initial_dir and os.path.isdir(initial_dir):
        options['current_folder'] = dbus.ByteArray((initial_dir + '\0').encode('utf-8'))

    target_handle = None
    selected_file = None

    def on_response(response, results, path=None):
        global selected_file
        if path == str(target_handle):
            if response == 0:
                uris = results.get('uris', [])
                if uris:
                    uri = str(uris[0])
                    selected_file = urllib.parse.unquote(urllib.parse.urlparse(uri).path)
            loop.quit()

    bus.add_signal_receiver(
        on_response,
        signal_name='Response',
        dbus_interface='org.freedesktop.portal.Request',
        path_keyword='path'
    )

    target_handle = fc.SaveFile('', f"Export {file_name}", options)
    loop.run()

    if selected_file:
        sys.stdout.write(selected_file)
        sys.exit(0)
    else:
        # User cancelled
        sys.exit(10)
except Exception as e:
    sys.stderr.write(str(e))
    sys.exit(1)
''';

  final result = await io.Process.run('python3', [
    '-c',
    script,
    fileName,
    targetDir ?? '',
    formatLabel,
    extension ?? '',
  ]);

  if (result.exitCode == 0) {
    var outPath = result.stdout.toString().trim();
    if (outPath.isNotEmpty) {
      if (extension != null &&
          !outPath.toLowerCase().endsWith('.${extension.toLowerCase()}')) {
        outPath = '$outPath.$extension';
      }
      final file = io.File(outPath);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }
  } else if (result.exitCode == 10) {
    // User intentionally clicked cancel in the portal dialog
    return '';
  }

  return null;
}
