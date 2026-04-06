import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Lecteur audio pour mobile / desktop (just_audio).
class TestAudioPlayer {
  TestAudioPlayer() {
    _stateSub = _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _completed.add(null);
      }
    });
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<void> _completed = StreamController<void>.broadcast();
  StreamSubscription<PlayerState>? _stateSub;

  Stream<void> get onPlaybackCompleted => _completed.stream;

  bool get playing => _player.playing;

  Stream<Duration> get positionStream => _player.positionStream;

  Duration? get duration => _player.duration;

  Future<void> setUrl(String url) => _player.setUrl(url);

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> stop() => _player.stop();

  Future<void> seek(Duration position) => _player.seek(position);

  void dispose() {
    _stateSub?.cancel();
    _completed.close();
    _player.dispose();
  }
}
