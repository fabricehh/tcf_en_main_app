import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/audio/audio_cache_service.dart';
import '../../utils/audio/test_audio_player.dart';
import '../../routes/routes.dart';
import '../../theme/theme.dart';

class AudioTestScreen extends StatefulWidget {
  const AudioTestScreen({super.key});

  @override
  State<AudioTestScreen> createState() => _AudioTestScreenState();
}

class _AudioTestScreenState extends State<AudioTestScreen> {
  final _supabase = Supabase.instance.client;
  final _audioPlayer = TestAudioPlayer();

  List<FileObject> _audioFiles = [];
  bool _isLoadingList = true;
  bool _isLoggingOut = false;
  int? _currentPlayingIndex;
  bool _isLoadingAudio = false;

  bool _preloadRunning = false;
  int _preloadDone = 0;
  int _preloadTotal = 0;

  String get _userName {
    final user = _supabase.auth.currentUser;
    final firstName = user?.userMetadata?['first_name'] ?? '';
    final lastName = user?.userMetadata?['last_name'] ?? '';
    if (firstName.toString().isNotEmpty) return firstName.toString();
    if (lastName.toString().isNotEmpty) return lastName.toString();
    return user?.email?.split('@').first ?? 'Utilisateur';
  }

  @override
  void initState() {
    super.initState();
    _loadAudioFiles();

    _audioPlayer.onPlaybackCompleted.listen((_) {
      if (mounted) {
        setState(() => _currentPlayingIndex = null);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = true}) {
    final bgColor = isError ? '#e53935' : '#43a047';
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      timeInSecForIosWeb: 5,
      gravity: ToastGravity.TOP,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 14,
      webBgColor: bgColor,
    );
  }

  Future<void> _loadAudioFiles() async {
    try {
      final files = await _supabase.storage.from('Audios').list();
      final mp3Files = files
          .where((f) => f.name.toLowerCase().endsWith('.mp3'))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));

      if (!mounted) return;
      setState(() {
        _audioFiles = mp3Files;
        _isLoadingList = false;
        _preloadTotal = mp3Files.length;
        _preloadDone = 0;
        _preloadRunning = mp3Files.isNotEmpty;
      });

      if (mp3Files.isNotEmpty) {
        AudioCacheService.instance
            .preloadAll(
          _supabase,
          mp3Files,
          onProgress: (done, total) {
            if (mounted) {
              setState(() {
                _preloadDone = done;
                _preloadTotal = total;
              });
            }
          },
        )
            .whenComplete(() {
          if (mounted) setState(() => _preloadRunning = false);
        });
      }
    } catch (_) {
      if (!mounted) return;
      _showToast('Erreur lors du chargement des fichiers audio');
      setState(() => _isLoadingList = false);
    }
  }

  Future<void> _playAudio(int index) async {
    final file = _audioFiles[index];

    if (_currentPlayingIndex == index && _audioPlayer.playing) {
      await _audioPlayer.pause();
      return;
    }

    if (_currentPlayingIndex == index && !_audioPlayer.playing) {
      await _audioPlayer.play();
      return;
    }

    setState(() {
      _isLoadingAudio = true;
      _currentPlayingIndex = index;
    });

    try {
      final url = await AudioCacheService.instance.playbackUrl(
        _supabase,
        file.name,
      );

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      if (mounted) setState(() => _isLoadingAudio = false);
    } catch (_) {
      if (!mounted) return;
      _showToast('Erreur lors de la lecture audio');
      setState(() {
        _currentPlayingIndex = null;
        _isLoadingAudio = false;
      });
    }
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    if (mounted) setState(() => _currentPlayingIndex = null);
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    try {
      await _stopAudio();
      await _supabase.auth.signOut();
      if (!mounted) return;
      _showToast('Déconnexion réussie', isError: false);
      context.go(RoutesClass.login);
    } catch (_) {
      if (!mounted) return;
      _showToast('Erreur lors de la déconnexion');
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatFileName(String name) {
    return name.replaceAll('.mp3', '').replaceAll('_', ' ').replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgPanel, AppColors.bgPanelDark],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logos/logo_app.png',
                width: 40,
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'TCF En Main',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Niveau B2',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoggingOut ? null : _handleLogout,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isLoggingOut
                ? AppColors.error.withValues(alpha: 0.9)
                : AppColors.error.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _isLoggingOut
              ? const SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitThreeBounce(color: Colors.white, size: 16),
                    ],
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingList) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SpinKitFadingCircle(color: AppColors.accent, size: 48),
            const SizedBox(height: 20),
            Text(
              'Chargement des fichiers audio...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_audioFiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.headphones_outlined,
                size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Aucun fichier audio disponible',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les fichiers audio apparaîtront ici une fois ajoutés.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.go(RoutesClass.overview),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text("Retour à l'accueil"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackLink(),
              const SizedBox(height: 16),
              _buildPageTitle(),
              const SizedBox(height: 24),
              ..._audioFiles.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildAudioCard(entry.key, entry.value),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackLink() {
    return InkWell(
      onTap: () => context.go(RoutesClass.overview),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              "Retour à la vue d'ensemble",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return Row(
      children: [
        const Icon(Icons.headphones, color: AppColors.accent, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Test Audio',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_audioFiles.length} fichier${_audioFiles.length > 1 ? 's' : ''} audio disponible${_audioFiles.length > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (_preloadRunning) ...[
                const SizedBox(height: 6),
                Text(
                  'Préchargement : $_preloadDone / $_preloadTotal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAudioCard(int index, FileObject file) {
    final isCurrentTrack = _currentPlayingIndex == index;
    final isPlaying = isCurrentTrack && _audioPlayer.playing;
    final isLoading = isCurrentTrack && _isLoadingAudio;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentTrack
            ? AppColors.accent.withValues(alpha: 0.05)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTrack ? AppColors.accent : AppColors.border,
          width: isCurrentTrack ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildPlayButton(index, isPlaying, isLoading),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatFileName(file.name),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: isCurrentTrack
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrentTrack && !_isLoadingAudio)
                IconButton(
                  onPressed: _stopAudio,
                  icon: const Icon(Icons.stop_circle_outlined),
                  color: AppColors.error,
                  iconSize: 28,
                  tooltip: 'Arrêter',
                ),
            ],
          ),
          if (isCurrentTrack && !_isLoadingAudio) ...[
            const SizedBox(height: 12),
            _buildProgressBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayButton(int index, bool isPlaying, bool isLoading) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () => _playAudio(index),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isPlaying
                ? AppColors.accent
                : AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: isLoading
              ? const SpinKitFadingCircle(
                  color: AppColors.accent, size: 24)
              : Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isPlaying ? Colors.white : AppColors.accent,
                  size: 26,
                ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: _audioPlayer.positionStream,
      builder: (context, posSnapshot) {
        final position = posSnapshot.data ?? Duration.zero;
        final duration = _audioPlayer.duration ?? Duration.zero;
        final progress = duration.inMilliseconds > 0
            ? position.inMilliseconds / duration.inMilliseconds
            : 0.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.accent,
                overlayColor: AppColors.accent.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (value) {
                  if (duration.inMilliseconds > 0) {
                    _audioPlayer.seek(
                      Duration(
                          milliseconds:
                              (value * duration.inMilliseconds).round()),
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
