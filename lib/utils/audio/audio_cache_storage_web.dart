import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Cache audio en mémoire + URL blob (web).
class AudioCacheStorage {
  AudioCacheStorage._();

  static final Map<String, Uint8List> _bytes = {};
  static final Map<String, String> _blobUrls = {};

  static Future<bool> hasKey(String key) async => _bytes.containsKey(key);

  static Future<void> put(String key, List<int> bytes) async {
    _bytes[key] = Uint8List.fromList(bytes);
    _revokeIfNeeded(key);
  }

  static void _revokeIfNeeded(String key) {
    final old = _blobUrls.remove(key);
    if (old != null) {
      web.URL.revokeObjectURL(old);
    }
  }

  static Future<String?> getPath(String key) async {
    final bytes = _bytes[key];
    if (bytes == null) return null;
    if (_blobUrls.containsKey(key)) return _blobUrls[key];

    final ua = bytes.toJS;
    final parts = [ua].toJS as JSArray<web.BlobPart>;
    final blob = web.Blob(parts);
    final url = web.URL.createObjectURL(blob);
    _blobUrls[key] = url;
    return url;
  }
}
