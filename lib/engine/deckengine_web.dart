import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'deckengine.dart';

DeckEngine? get instance => _WorkerEngine.instance;

@JS()
extension type _ClipMsg._(JSObject _) implements JSObject {
  external factory _ClipMsg({
    int id,
    String op,
    JSUint8Array head,
    JSUint8Array clip,
    double offset,
    double duration,
    JSFloat32Array? env,
    bool fakeprint,
  });
}

@JS()
extension type _EventsMsg._(JSObject _) implements JSObject {
  external factory _EventsMsg({
    int id,
    String op,
    JSUint8Array head,
    JSUint8Array clip,
    double offset,
    double period,
    double downbeat,
    double bassBody,
    bool wantCue,
  });
}

@JS()
extension type _FakeMsg._(JSObject _) implements JSObject {
  external factory _FakeMsg({int id, String op, JSFloat32Array pcm, int rate});
}

@JS()
extension type _Reply._(JSObject _) implements JSObject {
  external int get id;
  external bool get ok;
  external JSArray<JSNumber>? get values;
}

/// Underlying ArrayBuffer (transferred to the worker instead of copied).
JSObject _buffer(JSObject typedArray) => typedArray['buffer']! as JSObject;

/// deckengine as WebAssembly in a worker (web/analysis_worker.js + web/deckengine.wasm).
class _WorkerEngine implements DeckEngine {
  static final instance = _WorkerEngine();

  web.Worker? _worker;
  var _next = 0;
  final _pending = <int, Completer<List<double>?>>{};

  web.Worker get _w => _worker ??= web.Worker('analysis_worker.js'.toJS)
    ..onmessage = ((web.MessageEvent e) {
      final r = e.data as _Reply;
      final values = r.values?.toDart.map((v) => v.toDartDouble).toList();
      _pending.remove(r.id)?.complete(r.ok ? values : null);
    }).toJS
    ..onerror = ((web.Event _) {
      // Worker can't be loaded: release everyone waiting.
      for (final c in _pending.values) {
        c.complete(null);
      }
      _pending.clear();
    }).toJS;

  Future<List<double>?> _send(JSObject msg, int id, List<JSObject> transfer) {
    final c = Completer<List<double>?>();
    _pending[id] = c;
    _w.postMessage(msg, transfer.toJS);
    // If the worker hangs, it doesn't block the DJ logic.
    return c.future.timeout(const Duration(seconds: 20), onTimeout: () {
      _pending.remove(id);
      return null;
    });
  }

  @override
  String get label => 'Rust · WASM';

  @override
  Future<ClipAnalysis?> analyzeMp3Clip(ClipRequest r) async {
    final id = _next++;
    final head = r.head.toJS, clip = r.clip.toJS, env = r.envelope?.toJS;
    final v = await _send(
      _ClipMsg(
        id: id,
        op: 'clip',
        head: head,
        clip: clip,
        offset: r.clipOffset.toDouble(),
        duration: r.durationMs,
        env: env,
        fakeprint: r.fakeprint,
      ),
      id,
      [_buffer(head), _buffer(clip)],
    );
    return v == null ? null : ClipAnalysis.fromList(v);
  }

  @override
  Future<TrackEvents?> scanEvents(EventRequest r) async {
    final id = _next++;
    final head = r.head.toJS, clip = r.clip.toJS;
    final v = await _send(
      _EventsMsg(
        id: id,
        op: 'events',
        head: head,
        clip: clip,
        offset: r.clipOffset.toDouble(),
        period: r.periodMs,
        downbeat: r.downbeatMs,
        bassBody: r.bassBodyDb ?? 0,
        wantCue: r.wantCue,
      ),
      id,
      [_buffer(head), _buffer(clip)],
    );
    return v == null ? null : TrackEvents.fromList(v);
  }

  @override
  Future<double?> fakeprint(Float32List pcm, int sampleRate) async {
    final id = _next++;
    final p = pcm.toJS;
    final v = await _send(_FakeMsg(id: id, op: 'fakeprint', pcm: p, rate: sampleRate), id, [_buffer(p)]);
    return v?.first;
  }

  @override
  Future<List<double>?> analyzeWaveform(List<double> samples, int durationMs) async => null;
}
