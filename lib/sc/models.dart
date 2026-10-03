// SoundCloud data models (only fields the app uses).

class Transcoding {
  const Transcoding({
    required this.url,
    required this.preset,
    required this.protocol,
    required this.mime,
    required this.snipped,
  });

  final String url;
  final String preset;
  final String protocol;
  final String mime;
  final bool snipped;

  bool get isHls => protocol == 'hls';

  /// DRM-encrypted: `ctr-encrypted-hls` (cenc: Widevine/PlayReady) or `cbc-encrypted-hls` (cbcs: FairPlay).
  bool get isEncrypted => protocol.contains('encrypted');

  factory Transcoding.fromJson(Map<String, dynamic> j) => Transcoding(
    url: j['url'] as String? ?? '',
    preset: j['preset'] as String? ?? '',
    protocol: (j['format']?['protocol'] as String?) ?? '',
    mime: (j['format']?['mime_type'] as String?) ?? '',
    snipped: j['snipped'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'preset': preset,
    'format': {'protocol': protocol, 'mime_type': mime},
    'snipped': snipped,
  };
}

class ScUser {
  const ScUser({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.followers = 0,
    this.trackCount = 0,
    this.description,
    this.city,
    this.verified = false,
    this.bannerUrl,
  });

  final int id;
  final String username;
  final String? avatarUrl;
  final int followers;
  final int trackCount;
  final String? description;
  final String? city;
  final bool verified;
  final String? bannerUrl;

  factory ScUser.fromJson(Map<String, dynamic> j) {
    final visuals = j['visuals']?['visuals'] as List?;
    return ScUser(
      id: j['id'] as int,
      username: j['username'] as String? ?? '',
      avatarUrl: j['avatar_url'] as String?,
      followers: j['followers_count'] as int? ?? 0,
      trackCount: j['track_count'] as int? ?? 0,
      description: j['description'] as String?,
      city: j['city'] as String?,
      verified: j['verified'] as bool? ?? false,
      bannerUrl: visuals != null && visuals.isNotEmpty ? visuals.first['visual_url'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar_url': avatarUrl,
    'followers_count': followers,
    'track_count': trackCount,
    'verified': verified,
  };
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.user,
    required this.durationMs,
    this.artworkUrl,
    this.waveformUrl,
    this.permalinkUrl,
    this.genre,
    this.plays = 0,
    this.likes = 0,
    this.transcodings = const [],
    this.trackAuthorization,
    this.policy,
    this.bpm,
    this.streamUrl,
    this.artist,
  });

  final int id;
  final String title;
  final ScUser user;
  final int durationMs;
  final String? artworkUrl;
  final String? waveformUrl;
  final String? permalinkUrl;
  final String? genre;
  final int plays;
  final int likes;
  final List<Transcoding> transcodings;
  final String? trackAuthorization;
  final String? policy;
  final double? bpm;

  /// Direct stream URL of a radio station; set = live stream without SoundCloud.
  final String? streamUrl;

  /// Real artist according to the label (publisher_metadata) – often different from the uploader.
  final String? artist;

  bool get isLive => streamUrl != null;

  /// ID only, without metadata (occurs in playlists).
  bool get isStub => title.isEmpty;

  bool get isBlocked => policy == 'BLOCK';

  /// DRM streams only (major labels) – in the browser only available encrypted, even when signed in.
  bool get isProtected => transcodings.any((t) => t.isEncrypted);

  /// Can this platform play SoundCloud DRM (browser with Widevine/PlayReady)? Set at startup.
  static bool drmPlayback = false;

  bool get playable => !isBlocked && (!isProtected || drmPlayback);

  /// Only a 30-second preview is available (e.g. major-label tracks in guest mode).
  bool get isPreview => policy == 'SNIP' || (transcodings.isNotEmpty && transcodings.every((t) => t.snipped));

  /// Artwork in the requested size, falls back to the avatar.
  String? art([String size = 't500x500']) => sized(artworkUrl ?? user.avatarUrl, size);

  factory Track.fromJson(Map<String, dynamic> j) => Track(
    id: j['id'] as int,
    title: j['title'] as String? ?? '',
    user: j['user'] is Map ? ScUser.fromJson(j['user'] as Map<String, dynamic>) : const ScUser(id: 0, username: ''),
    durationMs: (j['full_duration'] ?? j['duration']) as int? ?? 0,
    artworkUrl: j['artwork_url'] as String?,
    waveformUrl: j['waveform_url'] as String?,
    permalinkUrl: j['permalink_url'] as String?,
    genre: j['genre'] as String?,
    plays: j['playback_count'] as int? ?? 0,
    likes: j['likes_count'] as int? ?? 0,
    transcodings: ((j['media']?['transcodings'] as List?) ?? const [])
        .map((e) => Transcoding.fromJson(e as Map<String, dynamic>))
        .toList(),
    trackAuthorization: j['track_authorization'] as String?,
    policy: j['policy'] as String?,
    bpm: (j['bpm'] as num?)?.toDouble(),
    streamUrl: j['kf_live_url'] as String?,
    artist: _nonEmpty(j['publisher_metadata']?['artist']) ?? _nonEmpty(j['metadata_artist']),
  );

  static String? _nonEmpty(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'user': user.toJson(),
    'duration': durationMs,
    'artwork_url': artworkUrl,
    'waveform_url': waveformUrl,
    'permalink_url': permalinkUrl,
    'genre': genre,
    'playback_count': plays,
    'likes_count': likes,
    'policy': policy,
    'bpm': bpm,
    if (streamUrl != null) 'kf_live_url': streamUrl,
    if (artist != null) 'publisher_metadata': {'artist': artist},
    // Transcodings/auth expire – fetched again on playback.
  };

  @override
  bool operator ==(Object other) => other is Track && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class ScPlaylist {
  const ScPlaylist({
    required this.id,
    required this.title,
    required this.user,
    this.artworkUrl,
    this.trackCount = 0,
    this.tracks = const [],
    this.isAlbum = false,
    this.description,
  });

  final int id;
  final String title;
  final ScUser user;
  final String? artworkUrl;
  final int trackCount;
  final List<Track> tracks;
  final bool isAlbum;
  final String? description;

  String? art([String size = 't500x500']) {
    final fromTracks = tracks.where((t) => t.artworkUrl != null).map((t) => t.artworkUrl).firstOrNull;
    return sized(artworkUrl ?? fromTracks ?? user.avatarUrl, size);
  }

  factory ScPlaylist.fromJson(Map<String, dynamic> j) => ScPlaylist(
    id: j['id'] as int,
    title: j['title'] as String? ?? '',
    user: j['user'] is Map ? ScUser.fromJson(j['user'] as Map<String, dynamic>) : const ScUser(id: 0, username: ''),
    artworkUrl: j['artwork_url'] as String? ?? (j['calculated_artwork_url'] as String?),
    trackCount: j['track_count'] as int? ?? 0,
    tracks: ((j['tracks'] as List?) ?? const []).map((e) => _trackOrStub(e as Map<String, dynamic>)).toList(),
    isAlbum: j['is_album'] as bool? ?? false,
    description: j['description'] as String?,
  );

  ScPlaylist copyWith({List<Track>? tracks}) => ScPlaylist(
    id: id,
    title: title,
    user: user,
    artworkUrl: artworkUrl,
    trackCount: trackCount,
    tracks: tracks ?? this.tracks,
    isAlbum: isAlbum,
    description: description,
  );
}

Track _trackOrStub(Map<String, dynamic> j) => j.containsKey('title')
    ? Track.fromJson(j)
    : Track(
        id: j['id'] as int,
        title: '',
        user: const ScUser(id: 0, username: ''),
        durationMs: 0,
      );

/// A curated row on the home page.
class Selection {
  const Selection({required this.title, required this.playlists});

  final String title;
  final List<ScPlaylist> playlists;
}

/// Result of a link resolve.
sealed class Resolved {}

class ResolvedTrack extends Resolved {
  ResolvedTrack(this.track);
  final Track track;
}

class ResolvedPlaylist extends Resolved {
  ResolvedPlaylist(this.playlist);
  final ScPlaylist playlist;
}

class ResolvedUser extends Resolved {
  ResolvedUser(this.user);
  final ScUser user;
}

String? sized(String? url, String size) => url?.replaceFirst(RegExp(r'-(large|t\d+x\d+|crop|original)\.'), '-$size.');
