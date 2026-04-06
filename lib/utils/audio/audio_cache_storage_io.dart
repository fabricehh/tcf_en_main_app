import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cache audio sur disque (hors web).
class AudioCacheStorage {
  AudioCacheStorage._();

  static Directory? _dir;

  static Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getTemporaryDirectory();
    _dir = Directory(p.join(base.path, 'tcf_audio_cache'));
    if (!await _dir!.exists()) {
      await _dir!.create(recursive: true);
    }
    return _dir!;
  }

  static String _safeName(String key) =>
      key.replaceAll(RegExp(r'[/\\]'), '_');

  static Future<bool> hasKey(String key) async {
    final f = File(p.join((await _cacheDir()).path, _safeName(key)));
    return f.exists();
  }

  static Future<void> put(String key, List<int> bytes) async {
    final f = File(p.join((await _cacheDir()).path, _safeName(key)));
    await f.writeAsBytes(bytes);
  }

  /// URL utilisable par le lecteur (`file://...`).
  static Future<String?> getPath(String key) async {
    final f = File(p.join((await _cacheDir()).path, _safeName(key)));
    if (!await f.exists()) return null;
    return f.uri.toString();
  }
}
