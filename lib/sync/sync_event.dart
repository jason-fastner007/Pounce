/// A sync event (event sourcing).
class SyncEvent {
  const SyncEvent({
    required this.deviceId,
    required this.seq,
    required this.timestampMs,
    required this.kind,
    required this.payload,
  });

  final String deviceId;
  final int seq;
  final int timestampMs;
  final String kind;
  final String payload;

  String get id => '$deviceId#$seq';

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'seq': seq,
    'timestampMs': timestampMs,
    'kind': kind,
    'payload': payload,
  };

  static SyncEvent? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final deviceId = json['deviceId'] as String?;
    final seq = (json['seq'] as num?)?.toInt();
    final timestampMs = (json['seq'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
    final kind = json['kind'] as String?;
    final payload = json['payload'] as String?;

    if (deviceId == null || seq == null || kind == null || payload == null) return null;
    return SyncEvent(
      deviceId: deviceId,
      seq: seq,
      timestampMs: timestampMs,
      kind: kind,
      payload: payload,
    );
  }
}

abstract final class SyncKinds {
  static const like = 'like';
  static const listen = 'listen';
  static const playlist = 'playlist';
}
