import 'package:flutter/services.dart';

import 'models/update_info.dart';
import 'release_provider.dart';

/// Updates in the Play build: exclusively Google's in-app update API (Play doesn't allow its own
/// APK downloads). Play doesn't provide version names – the version code is shown.
class PlayReleaseProvider implements ReleaseProvider {
  PlayReleaseProvider([this._ch = const MethodChannel('pounce/updates')]);

  final MethodChannel _ch;

  @override
  Future<UpdateInfo?> checkForUpdate({required String currentVersion}) async {
    try {
      final r = await _ch.invokeMapMethod<String, Object?>('check');
      if (r?['available'] != true) return null;
      return UpdateInfo(version: '${r!['versionCode']}', channel: UpdateChannel.play);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<InstallResult> install(UpdateInfo info, {void Function(double progress)? onProgress}) async {
    try {
      return await _ch.invokeMethod<bool>('start') == true ? InstallResult.started : InstallResult.failed;
    } catch (_) {
      return InstallResult.failed;
    }
  }
}
