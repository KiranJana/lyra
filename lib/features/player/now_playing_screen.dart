import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/extensions.dart';
import '../../data/services/audio_service.dart';

/// Full-screen now playing view
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final track = playerState.currentTrack;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.playerGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Album art
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _buildAlbumArt(track?.thumbnailUrl),
                    ),
                  ),
                ),
              ),

              // Track info and controls
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Track info
                    _buildTrackInfo(track),
                    const SizedBox(height: 24),

                    // Progress bar
                    _buildProgressBar(context, ref, playerState),
                    const SizedBox(height: 16),

                    // Playback controls
                    _buildPlaybackControls(ref, playerState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 32,
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Column(
              children: [
                Text(
                  'PLAYING FROM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  'Search Results',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show track options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(String? thumbnailUrl) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(128),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(
                  Icons.music_note,
                  size: 80,
                  color: AppColors.textTertiary,
                ),
              ),
            )
          : const Center(
              child: Icon(
                Icons.music_note,
                size: 80,
                color: AppColors.textTertiary,
              ),
            ),
    );
  }

  Widget _buildTrackInfo(dynamic track) {
    return Column(
      children: [
        Text(
          track?.title ?? 'No track playing',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          track?.artist ?? 'Search for music to start',
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    WidgetRef ref,
    AudioPlayerState playerState,
  ) {
    final position = playerState.position;
    final duration = playerState.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds: (value * duration.inMilliseconds).round(),
              );
              ref.read(audioPlayerProvider.notifier).seek(newPosition);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                position.formatted,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                duration.formatted,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(WidgetRef ref, AudioPlayerState playerState) {
    final notifier = ref.read(audioPlayerProvider.notifier);

    // Shuffle button color
    final shuffleColor = playerState.isShuffled
        ? AppColors.primary
        : AppColors.textSecondary;

    // Repeat button color and icon
    Color repeatColor;
    IconData repeatIcon;
    switch (playerState.loopMode) {
      case LoopModeState.off:
        repeatColor = AppColors.textSecondary;
        repeatIcon = Icons.repeat;
        break;
      case LoopModeState.all:
        repeatColor = AppColors.primary;
        repeatIcon = Icons.repeat;
        break;
      case LoopModeState.one:
        repeatColor = AppColors.primary;
        repeatIcon = Icons.repeat_one;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        IconButton(
          icon: const Icon(Icons.shuffle),
          color: shuffleColor,
          iconSize: 24,
          onPressed: () => notifier.toggleShuffle(),
        ),

        // Previous / Rewind
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 40,
          onPressed: () => notifier.skipBackward(),
        ),

        // Play/Pause
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.textPrimary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(playerState.isPlaying ? Icons.pause : Icons.play_arrow),
            color: AppColors.background,
            iconSize: 40,
            onPressed: () => notifier.playPause(),
          ),
        ),

        // Next / Forward
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 40,
          onPressed: () => notifier.skipForward(),
        ),

        // Repeat
        IconButton(
          icon: Icon(repeatIcon),
          color: repeatColor,
          iconSize: 24,
          onPressed: () => notifier.cycleLoopMode(),
        ),
      ],
    );
  }
}
