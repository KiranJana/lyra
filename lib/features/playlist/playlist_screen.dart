import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Playlist detail screen
class PlaylistScreen extends StatelessWidget {
  final int playlistId;

  const PlaylistScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header with back button
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Playlist'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withAlpha(102),
                      AppColors.surface,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.library_music,
                    size: 80,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),

          // Playlist controls
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Play all
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Play'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.shuffle),
                    onPressed: () {
                      // TODO: Shuffle play
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {
                      // TODO: Show options
                    },
                  ),
                ],
              ),
            ),
          ),

          // Empty state
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.music_off,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No tracks yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add songs from search to get started',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
