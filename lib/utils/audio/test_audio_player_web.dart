import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Lecteur audio pour Flutter Web (HTML5 Audio, sans canal just_audio).
class TestAudioPlayer {
  web.HTMLAudioElement? _el;
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<void> _completed = StreamController<void>.broadcast();
  Timer? _ticker;
  bool _playing = false;

  Stream<void> get onPlaybackCompleted => _completed.stream;

  bool get playing => _playing;

  Stream<Duration> get positionStream => _positionController.stream;

  Duration? get duration {
    final e = _el;
    if (e == null) return null;
    final d = e.duration;
    if (d.isNaN || d.isInfinite) return null;
    return Duration(milliseconds: (d * 1000).round());
  }

  Future<void> setUrl(String url) async {
    await stop();
    _el = web.HTMLAudioElement()..src = url;
    _el!.preload = 'auto';
    _el!.load();
    _positionController.add(Duration.zero);
  }

  Future<void> play() async {
    final e = _el;
    if (e == null) return;
    try {
      await e.play().toDart;
      _playing = true;
      _startTicker();
    } catch (_) {
      _playing = false;
    }
  }

  Future<void> pause() async {
    _el?.pause();
    _playing = false;
    _stopTicker();
  }

  Future<void> stop() async {
    _el?.pause();
    if (_el != null) {
      _el!.currentTime = 0;
    }
    _playing = false;
    _stopTicker();
    _positionController.add(Duration.zero);
  }

  Future<void> seek(Duration position) async {
    final e = _el;
    if (e == null) return;
    e.currentTime = position.inMilliseconds / 1000.0;
    _positionController.add(position);
  }

  void _startTicker() {
    _stopTicker();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final e = _el;
      if (e == null) return;
      _positionController.add(
        Duration(milliseconds: (e.currentTime * 1000).round()),
      );
      if (e.ended) {
        _playing = false;
        _stopTicker();
        _completed.add(null);
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void dispose() {
    _stopTicker();
    _el?.pause();
    _el = null;
    _positionController.close();
    _completed.close();
  }
}
