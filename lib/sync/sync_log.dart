import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/store.dart';
import '../library/library.dart';
import '../sc/models.dart';
import 'sync_event.dart';

/// Manages the local event history for sync.
class SyncLog extends ChangeNotifier {
  SyncLog(this.store, this.library) {
    _load();
  }

  final Store store;
  final Library library;

  late final String deviceId;
  String deviceName = 'Pounce Device';

  int _currentSeq = 0;
  final List<SyncEvent> _events = [];
  final Set<String> _seenEventIds = {};

  int get size => _events.length;
  List<SyncEvent> get events => List.unmodifiable(_events);

  void _load() {
    var id = store.get<String>('sync_device_id');
    if (id == null || id.isEmpty) {
      id = _randomString(16);
      store.set('sync_device_id', id);
    }
    deviceId = id;

    deviceName = store.get<String>('sync_device_name') ?? 'Pixel Device';

    final storedEvents = store.get<List<dynamic>>('sync_events');
    if (storedEvents != null) {
      for (final raw in storedEvents) {
        if (raw is String) {
          try {
            final ev = SyncEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
            if (ev != null) {
              _events.add(ev);
              _seenEventIds.add(ev.id);
              if (ev.deviceId == deviceId && ev.seq > _currentSeq) {
                _currentSeq = ev.seq;
              }
            }
          } catch (_) {}
        }
      }
    }
  }

  void setDeviceName(String name) {
    deviceName = name;
    store.set('sync_device_name', name);
    notifyListeners();
  }

  void _persist() {
    final list = _events.map((e) => jsonEncode(e.toJson())).toList();
    store.set('sync_events', list);
    notifyListeners();
  }

  /// Records a local event.
  SyncEvent record(String kind, Map<String, dynamic> payload) {
    _currentSeq++;
    final ev = SyncEvent(
      deviceId: deviceId,
      seq: _currentSeq,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      kind: kind,
      payload: jsonEncode(payload),
    );
    _events.add(ev);
    _seenEventIds.add(ev.id);
    _persist();
    return ev;
  }

  bool _isApplyingRemote = false;

  void recordLike(Track track, bool liked) {
    if (_isApplyingRemote) return;
    record(SyncKinds.like, {
      'trackId': track.id,
      'title': track.title,
      'username': track.user.username,
      'artworkUrl': track.artworkUrl,
      'duration': track.durationMs,
      'permalinkUrl': track.permalinkUrl,
      'liked': liked,
    });
  }

  void recordListen(Track track) {
    if (_isApplyingRemote) return;
    record(SyncKinds.listen, {
      'trackId': track.id,
      'title': track.title,
      'username': track.user.username,
      'artworkUrl': track.artworkUrl,
      'duration': track.durationMs,
      'permalinkUrl': track.permalinkUrl,
    });
  }

  /// Returns all events of this device since [sinceSeq].
  List<SyncEvent> eventsSince(int sinceSeq) {
    return _events.where((e) => e.seq > sinceSeq).toList();
  }

  /// Merges incoming events from a peer without conflicts.
  int mergeRemote(List<SyncEvent> remoteEvents) {
    _isApplyingRemote = true;
    try {
      var added = 0;
      for (final ev in remoteEvents) {
        if (_seenEventIds.contains(ev.id)) continue;

        _events.add(ev);
        _seenEventIds.add(ev.id);
        added++;

        // Apply the event to the local library
        try {
        final data = jsonDecode(ev.payload) as Map<String, dynamic>;
        switch (ev.kind) {
          case SyncKinds.like:
            final trackId = data['trackId'] as int;
            final liked = data['liked'] as bool? ?? true;
            final track = Track(
              id: trackId,
              title: data['title'] as String? ?? 'Track',
              user: ScUser(id: 0, username: data['username'] as String? ?? 'Artist'),
              durationMs: (data['duration'] as num?)?.toInt() ?? 0,
              artworkUrl: data['artworkUrl'] as String?,
              permalinkUrl: data['permalinkUrl'] as String? ?? '',
            );
            if (liked && !library.isLiked(track)) {
              library.toggleLike(track);
            } else if (!liked && library.isLiked(track)) {
              library.toggleLike(track);
            }
          case SyncKinds.listen:
            final trackId = data['trackId'] as int;
            final track = Track(
              id: trackId,
              title: data['title'] as String? ?? 'Track',
              user: ScUser(id: 0, username: data['username'] as String? ?? 'Artist'),
              durationMs: (data['duration'] as num?)?.toInt() ?? 0,
              artworkUrl: data['artworkUrl'] as String?,
              permalinkUrl: data['permalinkUrl'] as String? ?? '',
            );
            library.addHistory(track);
        }
      } catch (_) {}
    }

      if (added > 0) {
        _persist();
      }
      return added;
    } finally {
      _isApplyingRemote = false;
    }
  }

  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }
}
