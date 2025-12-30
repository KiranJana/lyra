import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/audio_service.dart';

/// Mini player shown at the bottom of the screen when a track is playing
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final track = playerState.currentTrack;

    // Don't show if no track is loaded
    if (track == null) {
      return const SizedBox.shrink();
    }

    // Progress indicator
    final progress = playerState.duration.inMilliseconds > 0
        ? playerState.position.inMilliseconds /
              playerState.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/now-playing'),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          border: Border(
            top: BorderSide(color: AppColors.surfaceHighlight, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceHighlight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 2,
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: track.thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: track.thumbnailUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: Icon(
                                  Icons.music_note,
                                  color: AppColors.textTertiary,
                                  size: 20,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Icon(
                                      Icons.music_note,
                                      color: AppColors.textTertiary,
                                      size: 20,
                                    ),
                                  ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.music_note,
                                color: AppColors.textTertiary,
                                size: 20,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Track info
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (track.artist != null)
                            Text(
                              track.artist!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        playerState.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      color: AppColors.textPrimary,
                      iconSize: 28,
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).playPause();
                      },
                    ),

                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                      iconSize: 20,
                      onPressed: () {
                        ref.read(audioPlayerProvider.notifier).stop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
