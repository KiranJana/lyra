import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/track.dart';
import '../../models/search_result.dart';

/// Initialize audio service - must be called before runApp
Future<void> initAudioService() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.lyra.audio',
    androidNotificationChannelName: 'Lyra Audio',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );
}

/// Audio player state
enum PlayerState { idle, loading, playing, paused, completed, error }

/// Loop mode for playback
enum LoopModeState { off, one, all }

/// Player state holder
class AudioPlayerState {
  final PlayerState state;
  final Track? currentTrack;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final bool isShuffled;
  final LoopModeState loopMode;
  final double volume;
  final double speed;
  final String? errorMessage;

  const AudioPlayerState({
    this.state = PlayerState.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.isShuffled = false,
    this.loopMode = LoopModeState.off,
    this.volume = 1.0,
    this.speed = 1.0,
    this.errorMessage,
  });

  bool get isPlaying => state == PlayerState.playing;
  bool get isLoading => state == PlayerState.loading;
  bool get hasTrack => currentTrack != null;

  AudioPlayerState copyWith({
    PlayerState? state,
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    bool? isShuffled,
    LoopModeState? loopMode,
    double? volume,
    double? speed,
    String? errorMessage,
    bool clearTrack = false,
    bool clearError = false,
  }) {
    return AudioPlayerState(
      state: state ?? this.state,
      currentTrack: clearTrack ? null : (currentTrack ?? this.currentTrack),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      isShuffled: isShuffled ?? this.isShuffled,
      loopMode: loopMode ?? this.loopMode,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Audio player notifier - manages playback state
class AudioPlayerNotifier extends StateNotifier<AudioPlayerState> {
  final AudioPlayer _player;

  AudioPlayerNotifier()
    : _player = AudioPlayer(),
      super(const AudioPlayerState()) {
    _initPlayer();
  }

  AudioPlayer get player => _player;

  void _initPlayer() {
    // Listen to player state changes
    _player.playerStateStream.listen((playerState) {
      PlayerState newState;
      if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        newState = PlayerState.loading;
      } else if (playerState.processingState == ProcessingState.completed) {
        newState = PlayerState.completed;
      } else if (playerState.playing) {
        newState = PlayerState.playing;
      } else {
        newState = PlayerState.paused;
      }
      state = state.copyWith(state: newState);
    });

    // Listen to position changes
    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    // Listen to buffered position
    _player.bufferedPositionStream.listen((buffered) {
      state = state.copyWith(bufferedPosition: buffered);
    });

    // Listen to shuffle mode
    _player.shuffleModeEnabledStream.listen((enabled) {
      state = state.copyWith(isShuffled: enabled);
    });

    // Listen to loop mode
    _player.loopModeStream.listen((loopMode) {
      LoopModeState mode;
      switch (loopMode) {
        case LoopMode.off:
          mode = LoopModeState.off;
          break;
        case LoopMode.one:
          mode = LoopModeState.one;
          break;
        case LoopMode.all:
          mode = LoopModeState.all;
          break;
      }
      state = state.copyWith(loopMode: mode);
    });
  }

  /// Play a track from a search result
  Future<void> playSearchResult(SearchResult result) async {
    await playTrack(result.toTrack());
  }

  /// Play a track
  Future<void> playTrack(Track track, {String? streamUrl}) async {
    try {
      print('[AudioPlayer] Playing track: ${track.title}');
      print('[AudioPlayer] Stream URL: $streamUrl');

      state = state.copyWith(
        state: PlayerState.loading,
        currentTrack: track,
        clearError: true,
      );

      // If we have a stream URL, use it directly
      if (streamUrl != null) {
        print('[AudioPlayer] Setting audio source...');
        print('[AudioPlayer] Stream URL: $streamUrl');

        // Local proxy handles headers internally
        final audioSource = AudioSource.uri(
          Uri.parse(streamUrl),
          tag: MediaItem(
            id: track.youtubeId,
            title: track.title,
            artist: track.artist ?? 'Unknown Artist',
            artUri: track.thumbnailUrl != null
                ? Uri.parse(track.thumbnailUrl!)
                : null,
            duration: track.durationSeconds != null
                ? Duration(seconds: track.durationSeconds!)
                : null,
          ),
        );

        await _player.setAudioSource(audioSource);
        print('[AudioPlayer] Audio source set, starting playback...');
        await _player.play();
        print('[AudioPlayer] Playback started!');
      } else {
        print('[AudioPlayer] No stream URL provided');
        state = state.copyWith(
          state: PlayerState.paused,
          errorMessage: 'Stream URL resolution not yet implemented',
        );
      }
    } catch (e, stackTrace) {
      print('[AudioPlayer] ERROR: $e');
      print('[AudioPlayer] Stack trace: $stackTrace');
      state = state.copyWith(
        state: PlayerState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Play/resume
  Future<void> play() async {
    await _player.play();
  }

  /// Pause
  Future<void> pause() async {
    await _player.pause();
  }

  /// Toggle play/pause
  Future<void> playPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  /// Stop playback
  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(
      state: PlayerState.idle,
      clearTrack: true,
      position: Duration.zero,
    );
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  /// Seek by offset (forward/backward)
  Future<void> seekBy(Duration offset) async {
    final newPosition = state.position + offset;
    if (newPosition < Duration.zero) {
      await seek(Duration.zero);
    } else if (newPosition > state.duration) {
      await seek(state.duration);
    } else {
      await seek(newPosition);
    }
  }

  /// Skip forward 10 seconds
  Future<void> skipForward() async {
    await seekBy(const Duration(seconds: 10));
  }

  /// Skip backward 10 seconds
  Future<void> skipBackward() async {
    await seekBy(const Duration(seconds: -10));
  }

  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    await _player.setShuffleModeEnabled(!_player.shuffleModeEnabled);
  }

  /// Cycle through loop modes: off -> all -> one -> off
  Future<void> cycleLoopMode() async {
    switch (_player.loopMode) {
      case LoopMode.off:
        await _player.setLoopMode(LoopMode.all);
        break;
      case LoopMode.all:
        await _player.setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await _player.setLoopMode(LoopMode.off);
        break;
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
    state = state.copyWith(volume: volume);
  }

  /// Set playback speed
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    state = state.copyWith(speed: speed);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// Main audio player provider
final audioPlayerProvider =
    StateNotifierProvider<AudioPlayerNotifier, AudioPlayerState>((ref) {
      return AudioPlayerNotifier();
    });

/// Convenience providers for specific state slices
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(audioPlayerProvider).isPlaying;
});

final currentTrackProvider = Provider<Track?>((ref) {
  return ref.watch(audioPlayerProvider).currentTrack;
});

final positionProvider = Provider<Duration>((ref) {
  return ref.watch(audioPlayerProvider).position;
});

final durationProvider = Provider<Duration>((ref) {
  return ref.watch(audioPlayerProvider).duration;
});

final progressProvider = Provider<double>((ref) {
  final state = ref.watch(audioPlayerProvider);
  if (state.duration.inMilliseconds == 0) return 0.0;
  return state.position.inMilliseconds / state.duration.inMilliseconds;
});
