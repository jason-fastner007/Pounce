class SyncPeer {
  SyncPeer({
    required this.deviceId,
    required this.deviceName,
    required this.host,
    required this.port,
    required this.secret,
    this.lastSeenMs = 0,
    this.lastSyncedSeq = 0,
  });

  final String deviceId;
  String deviceName;
  String host;
  int port;
  final String secret;
  int lastSeenMs;
  int lastSyncedSeq;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'host': host,
    'port': port,
    'secret': secret,
    'lastSeenMs': lastSeenMs,
    'lastSyncedSeq': lastSyncedSeq,
  };

  static SyncPeer? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final deviceId = json['deviceId'] as String?;
    final host = json['host'] as String?;
    final secret = json['secret'] as String?;
    if (deviceId == null || host == null || secret == null) return null;

    return SyncPeer(
      deviceId: deviceId,
      deviceName: json['deviceName'] as String? ?? 'Peer',
      host: host,
      port: (json['port'] as num?)?.toInt() ?? 47653,
      secret: secret,
      lastSeenMs: (json['lastSeenMs'] as num?)?.toInt() ?? 0,
      lastSyncedSeq: (json['lastSyncedSeq'] as num?)?.toInt() ?? 0,
    );
  }
}
