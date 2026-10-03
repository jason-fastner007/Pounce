import 'debug_export_io.dart' if (dart.library.js_interop) 'debug_export_web.dart' as impl;

/// Stores diagnostic values in the browser (window.kfDebug); no-op on native.
void debugExport(Map<String, Object?> values) => impl.export(values);
