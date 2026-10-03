import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void export(Map<String, Object?> values) => globalContext['kfDebug'] = jsonEncode(values).toJS;
