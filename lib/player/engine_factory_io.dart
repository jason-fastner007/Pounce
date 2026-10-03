import 'dart:io';

import 'audio_engine.dart';
import 'engine_channel.dart';
import 'engine_mpv.dart';

AudioEngine createEngine() => Platform.isLinux || Platform.isWindows ? MpvEngine() : ChannelEngine();
