/// Cross-platform file saving service providing safe, resilient file saving
/// across Web, macOS, Windows, Linux, Android, and iOS.
library;

export 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';
