import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/extensions.dart';
import '../models/search_result.dart';
import '../models/track.dart';

/// Reusable track tile widget for displaying tracks in lists
class TrackTile extends StatelessWidget {
  final String title;
  final String? artist;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final VoidCallback? onTap;
  final VoidCallback? onMorePressed;
  final bool isPlaying;
  final bool showDuration;
  final Widget? trailing;

  const TrackTile({
    super.key,
    required this.title,
    this.artist,
    this.thumbnailUrl,
    this.durationSeconds,
    this.onTap,
    this.onMorePressed,
    this.isPlaying = false,
    this.showDuration = true,
    this.trailing,
  });

  /// Create from SearchResult
  factory TrackTile.fromSearchResult({
    required SearchResult result,
    VoidCallback? onTap,
    VoidCallback? onMorePressed,
    bool isPlaying = false,
  }) {
    return TrackTile(
      title: result.title,
      artist: result.uploaderName,
      thumbnailUrl: result.thumbnailUrl,
      durationSeconds: result.duration,
      onTap: onTap,
      onMorePressed: onMorePressed,
      isPlaying: isPlaying,
    );
  }

  /// Create from Track
  factory TrackTile.fromTrack({
    required Track track,
    VoidCallback? onTap,
    VoidCallback? onMorePressed,
    bool isPlaying = false,
    Widget? trailing,
  }) {
    return TrackTile(
      title: track.title,
      artist: track.artist,
      thumbnailUrl: track.thumbnailUrl,
      durationSeconds: track.durationSeconds,
      onTap: onTap,
      onMorePressed: onMorePressed,
      isPlaying: isPlaying,
      trailing: trailing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        child: Row(
          children: [
            // Thumbnail
            _buildThumbnail(),
            const SizedBox(width: 12),

            // Title and artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPlaying
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isPlaying) ...[
                        const Icon(
                          Icons.volume_up,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          _buildSubtitle(),
                          style: TextStyle(
                            fontSize: 13,
                            color: isPlaying
                                ? AppColors.primary.withAlpha(179)
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing widget or more button
            if (trailing != null)
              trailing!
            else if (onMorePressed != null)
              IconButton(
                icon: const Icon(Icons.more_vert),
                color: AppColors.textSecondary,
                iconSize: 20,
                onPressed: onMorePressed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(4),
      ),
      clipBehavior: Clip.antiAlias,
      child: thumbnailUrl != null
          ? CachedNetworkImage(
              imageUrl: thumbnailUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: Icon(
                  Icons.music_note,
                  color: AppColors.textTertiary,
                  size: 24,
                ),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(
                  Icons.music_note,
                  color: AppColors.textTertiary,
                  size: 24,
                ),
              ),
            )
          : const Center(
              child: Icon(
                Icons.music_note,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];

    if (artist != null && artist!.isNotEmpty) {
      parts.add(artist!);
    }

    if (showDuration && durationSeconds != null) {
      parts.add(durationSeconds!.formattedDuration);
    }

    return parts.isEmpty ? 'Unknown' : parts.join(' • ');
  }
}
