import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/store.dart';
import 'sync_event.dart';
import 'sync_log.dart';
import 'sync_peer.dart';

class SyncService extends ChangeNotifier {
  SyncService({required this.store, required this.log}) {
    _load();
  }

  final Store store;
  final SyncLog log;

  static const defaultPort = 47653;
  HttpServer? _server;
  Timer? _syncTimer;

  late String pairingSecret;
  int port = defaultPort;
  bool isListenerEnabled = true;

  final List<SyncPeer> _peers = [];
  List<SyncPeer> get peers => List.unmodifiable(_peers);

  int? _lastSyncedEvents;

  /// New events from the last sync, null = not synced yet (the UI formats the message).
  int? get lastSyncedEvents => _lastSyncedEvents;

  int _lastSyncTimeMs = 0;
  int get lastSyncTimeMs => _lastSyncTimeMs;

  void _load() {
    var sec = store.get<String>('sync_secret');
    if (sec == null || sec.isEmpty) {
      sec = _randomSecret();
      store.set('sync_secret', sec);
    }
    pairingSecret = sec;

    port = store.get<int>('sync_port') ?? defaultPort;
    isListenerEnabled = store.get<bool>('sync_listener_enabled') ?? true;

    final storedPeers = store.get<List<dynamic>>('sync_peers');
    if (storedPeers != null) {
      for (final p in storedPeers) {
        if (p is String) {
          try {
            final peer = SyncPeer.fromJson(jsonDecode(p) as Map<String, dynamic>);
            if (peer != null) _peers.add(peer);
          } catch (_) {}
        }
      }
    }

    if (isListenerEnabled) {
      startListener();
    }
    _startPeriodicSync();
  }

  void _savePeers() {
    final list = _peers.map((p) => jsonEncode(p.toJson())).toList();
    store.set('sync_peers', list);
    notifyListeners();
  }

  void setListenerEnabled(bool enabled) {
    isListenerEnabled = enabled;
    store.set('sync_listener_enabled', enabled);
    if (enabled) {
      startListener();
    } else {
      stopListener();
    }
    notifyListeners();
  }

  Future<void> startListener() async {
    if (_server != null) return;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _server!.listen(_handleRequest);
      notifyListeners();
    } catch (e) {
      debugPrint('SyncService bind error: $e');
    }
  }

  void stopListener() {
    _server?.close();
    _server = null;
    notifyListeners();
  }

  bool get isRunning => _server != null;

  void _handleRequest(HttpRequest req) async {
    final path = req.uri.path;
    final auth = req.headers.value('authorization');

    // 1. Ping (possible without auth)
    if (path == '/sync/ping') {
      req.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'ok', 'deviceId': log.deviceId, 'deviceName': log.deviceName}))
        ..close();
      return;
    }

    // 2. Pair
    if (path == '/sync/pair') {
      try {
        final body = await utf8.decoder.bind(req).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final peerSecret = json['secret'] as String;
        final peerDevice = json['deviceId'] as String;
        final peerName = json['deviceName'] as String? ?? 'Peer';
        final peerPort = (json['port'] as num?)?.toInt() ?? defaultPort;
        final remoteIp = req.connectionInfo?.remoteAddress.address ?? '';

        // Add / update the peer
        _addOrUpdatePeer(
          SyncPeer(
            deviceId: peerDevice,
            deviceName: peerName,
            host: remoteIp,
            port: peerPort,
            secret: peerSecret,
            lastSeenMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );

        // Return our own pairing data
        req.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({'deviceId': log.deviceId, 'deviceName': log.deviceName, 'secret': pairingSecret, 'port': port}),
          )
          ..close();
        return;
      } catch (e) {
        req.response.statusCode = HttpStatus.badRequest;
        req.response.close();
        return;
      }
    }

    // Pull & push require auth (constant-time comparison prevents timing side-channel attacks)
    final isAuthorized = _constantTimeEquals(auth, pairingSecret) ||
        _peers.any((p) => _constantTimeEquals(p.secret, auth));
    if (!isAuthorized) {
      req.response.statusCode = HttpStatus.unauthorized;
      req.response.close();
      return;
    }

    if (path == '/sync/pull') {
      final sinceSeq = int.tryParse(req.uri.queryParameters['since'] ?? '0') ?? 0;
      final events = log.eventsSince(sinceSeq);
      req.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'events': events.map((e) => e.toJson()).toList()}))
        ..close();
      return;
    }

    if (path == '/sync/push') {
      try {
        final body = await utf8.decoder.bind(req).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final rawEvents = json['events'] as List<dynamic>? ?? [];
        final events = rawEvents
            .map((e) => SyncEvent.fromJson(e as Map<String, dynamic>))
            .whereType<SyncEvent>()
            .toList();
        final added = log.mergeRemote(events);

        req.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'status': 'ok', 'merged': added}))
          ..close();
        return;
      } catch (e) {
        req.response.statusCode = HttpStatus.badRequest;
        req.response.close();
        return;
      }
    }

    req.response.statusCode = HttpStatus.notFound;
    req.response.close();
  }

  void _addOrUpdatePeer(SyncPeer peer) {
    final idx = _peers.indexWhere((p) => p.deviceId == peer.deviceId);
    if (idx >= 0) {
      _peers[idx].host = peer.host;
      _peers[idx].port = peer.port;
      _peers[idx].deviceName = peer.deviceName;
      _peers[idx].lastSeenMs = DateTime.now().millisecondsSinceEpoch;
    } else {
      _peers.add(peer);
    }
    _savePeers();
  }

  /// Generates the Base64 pairing code for this device.
  Future<String> pairingCode() async {
    final ip = await _getLocalIp();
    final map = {
      'host': ip,
      'port': port,
      'secret': pairingSecret,
      'deviceId': log.deviceId,
      'deviceName': log.deviceName,
    };
    return base64Url.encode(utf8.encode(jsonEncode(map)));
  }

  /// Pairs this device with a peer using its code.
  Future<bool> pairWithCode(String code) async {
    try {
      final decoded = utf8.decode(base64Url.decode(code.trim()));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final host = json['host'] as String;
      final peerPort = (json['port'] as num?)?.toInt() ?? defaultPort;
      final secret = json['secret'] as String;
      final peerId = json['deviceId'] as String;
      final peerName = json['deviceName'] as String? ?? 'Peer';

      final res = await http
          .post(
            Uri.parse('http://$host:$peerPort/sync/pair'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'deviceId': log.deviceId,
              'deviceName': log.deviceName,
              'secret': pairingSecret,
              'port': port,
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        _addOrUpdatePeer(
          SyncPeer(
            deviceId: peerId,
            deviceName: peerName,
            host: host,
            port: peerPort,
            secret: secret,
            lastSeenMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        await syncNow();
        return true;
      }
    } catch (e) {
      debugPrint('Pair error: $e');
    }
    return false;
  }

  /// Immediately starts a sync with all known peers.
  Future<void> syncNow() async {
    var syncedCount = 0;
    for (final peer in _peers) {
      try {
        // 1. Pull from peer
        final pullRes = await http
            .get(
              Uri.parse('http://${peer.host}:${peer.port}/sync/pull?since=${peer.lastSyncedSeq}'),
              headers: {'Authorization': peer.secret},
            )
            .timeout(const Duration(seconds: 4));

        if (pullRes.statusCode == 200) {
          final json = jsonDecode(pullRes.body) as Map<String, dynamic>;
          final rawEvents = json['events'] as List<dynamic>? ?? [];
          final events = rawEvents
              .map((e) => SyncEvent.fromJson(e as Map<String, dynamic>))
              .whereType<SyncEvent>()
              .toList();

          if (events.isNotEmpty) {
            final merged = log.mergeRemote(events);
            syncedCount += merged;
            peer.lastSyncedSeq = events.map((e) => e.seq).fold(peer.lastSyncedSeq, max);
          }
          peer.lastSeenMs = DateTime.now().millisecondsSinceEpoch;
        }

        // 2. Push own events to peer
        final localEvents = log.eventsSince(0);
        if (localEvents.isNotEmpty) {
          await http
              .post(
                Uri.parse('http://${peer.host}:${peer.port}/sync/push'),
                headers: {'Authorization': peer.secret, 'Content-Type': 'application/json'},
                body: jsonEncode({'events': localEvents.map((e) => e.toJson()).toList()}),
              )
              .timeout(const Duration(seconds: 4));
        }
      } catch (e) {
        debugPrint('Sync peer ${peer.deviceName} error: $e');
      }
    }

    _lastSyncTimeMs = DateTime.now().millisecondsSinceEpoch;
    _lastSyncedEvents = _peers.isEmpty ? null : syncedCount;
    _savePeers();
    notifyListeners();
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_peers.isNotEmpty) syncNow();
    });
  }

  Future<String> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  static String _randomSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(24, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Secure constant-time string comparison to prevent timing side-channel attacks.
  static bool _constantTimeEquals(String? a, String? b) {
    if (a == null || b == null) return a == b;
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);

    var result = aBytes.length ^ bBytes.length;
    final length = aBytes.length < bBytes.length ? aBytes.length : bBytes.length;
    for (var i = 0; i < length; i++) {
      result |= aBytes[i] ^ bBytes[i];
    }
    return result == 0;
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _server?.close();
    super.dispose();
  }
}
