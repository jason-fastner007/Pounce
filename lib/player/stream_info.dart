/// A directly playable stream, as resolved by a source module (or a radio station).
class StreamInfo {
  const StreamInfo(
    this.url, {
    required this.hls,
    this.mime = '',
    this.preset = '',
    this.live = false,
    this.licenseToken,
  });
  final String url;
  final bool hls;
  final String mime;
  final String preset;

  /// Endless live stream (radio): no duration, no seeking, possibly without CORS.
  final bool live;

  /// JWT for the SoundCloud license server; set = DRM stream (decrypted in the browser's CDM).
  final String? licenseToken;
  bool get drm => licenseToken != null;

  /// e.g. "AAC 160k · HLS" for telemetry.
  String get label {
    if (live) return ['LIVE', if (hls) 'HLS'].join(' · ');
    final codec = mime.contains('mp4') ? 'AAC' : (mime.contains('ogg') || mime.contains('opus') ? 'OPUS' : 'MP3');
    final rate = RegExp(r'(\d+)k').firstMatch(preset)?.group(0) ?? (codec == 'MP3' ? '128k' : '');
    return [codec, if (rate.isNotEmpty) rate, if (hls) 'HLS' else 'PROG', if (drm) 'DRM'].join(' · ');
  }
}
