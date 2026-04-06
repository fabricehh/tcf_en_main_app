import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'audio_cache_storage.dart';

/// Télécharge les MP3 une fois et les garde en cache local (fichier ou blob web).
class AudioCacheService {
  AudioCacheService._();
  static final AudioCacheService instance = AudioCacheService._();

  static const String bucket = 'Audios';
  static const int signedUrlTtlSec = 3600;

  final Set<String> _inFlight = {};

  /// Télécharge les fichiers par paquets pour remplir le cache sans saturer le réseau.
  Future<void> preloadAll(
    SupabaseClient client,
    List<FileObject> files, {
    void Function(int done, int total)? onProgress,
  }) async {
    if (files.isEmpty) return;

    const chunkSize = 3;
    var done = 0;
    final total = files.length;

    for (var i = 0; i < files.length; i += chunkSize) {
      final chunk = files.skip(i).take(chunkSize).toList();
      await Future.wait(
        chunk.map((f) async {
          try {
            await ensureCached(client, f.name);
          } catch (_) {
            // Les autres pistes du lot peuvent réussir
          }
        }),
      );
      done += chunk.length;
      onProgress?.call(done, total);
    }
  }

  /// Assure que le fichier est en cache (télécharge si besoin).
  Future<void> ensureCached(SupabaseClient client, String fileName) async {
    if (await AudioCacheStorage.hasKey(fileName)) return;
    if (_inFlight.contains(fileName)) {
      while (_inFlight.contains(fileName)) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      if (await AudioCacheStorage.hasKey(fileName)) return;
    }
    _inFlight.add(fileName);
    try {
      final signedUrl = await client.storage
          .from(bucket)
          .createSignedUrl(fileName, signedUrlTtlSec);
      final response = await http.get(Uri.parse(signedUrl));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      await AudioCacheStorage.put(fileName, response.bodyBytes);
    } finally {
      _inFlight.remove(fileName);
    }
  }

  /// URL pour lecture : cache local si disponible, sinon URL signée.
  Future<String> playbackUrl(SupabaseClient client, String fileName) async {
    await ensureCached(client, fileName);
    final cached = await AudioCacheStorage.getPath(fileName);
    if (cached != null) return cached;

    return client.storage
        .from(bucket)
        .createSignedUrl(fileName, signedUrlTtlSec);
  }
}
