import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/services/audio_service.dart';
import '../../models/search_result.dart';
import '../../widgets/track_tile.dart';
import 'search_provider.dart';

/// Search screen for finding music
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search input
                  TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Songs, artists, or albums',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: _clearSearch,
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {}); // Update clear button visibility
                      ref.read(searchNotifierProvider.notifier).setQuery(value);
                    },
                    textInputAction: TextInputAction.search,
                  ),
                ],
              ),
            ),
            // Content
            Expanded(child: _buildContent(searchState)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(SearchState searchState) {
    // Empty state
    if (searchState.query.isEmpty) {
      return _buildEmptyState();
    }

    // Loading state
    if (searchState.isLoading && searchState.results.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    // Error state
    if (searchState.errorMessage != null && searchState.results.isEmpty) {
      return _buildErrorState(searchState.errorMessage!);
    }

    // No results
    if (searchState.results.isEmpty && !searchState.isLoading) {
      return _buildNoResultsState();
    }

    // Results
    return _buildResultsList(searchState.results, searchState.isLoading);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.search,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Find your music',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for songs, artists, or albums',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(searchNotifierProvider.notifier).retry(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try different keywords',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<SearchResult> results, bool isLoading) {
    return Column(
      children: [
        // Loading indicator at top when refreshing
        if (isLoading)
          const LinearProgressIndicator(
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              final currentTrack = ref.watch(currentTrackProvider);
              final isPlaying = currentTrack?.youtubeId == result.videoId;

              return TrackTile.fromSearchResult(
                result: result,
                isPlaying: isPlaying,
                onTap: () => _playTrack(result),
                onMorePressed: () => _showTrackOptions(result),
              );
            },
          ),
        ),
      ],
    );
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchNotifierProvider.notifier).clear();
    setState(() {});
  }

  Future<void> _playTrack(SearchResult result) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading "${result.title}"...'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.surface,
      ),
    );

    try {
      // Play the track - AudioService handles stream resolution (Piped -> Proxy)
      final track = result.toTrack();
      await ref
          .read(audioPlayerProvider.notifier)
          .playTrack(track); // No streamUrl needed!
    } catch (e) {
      print('[SearchScreen] Error playing track: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showTrackOptions(SearchResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Track info header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: result.thumbnailUrl != null
                        ? Image.network(
                            result.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.music_note,
                              color: AppColors.textTertiary,
                            ),
                          )
                        : const Icon(
                            Icons.music_note,
                            color: AppColors.textTertiary,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (result.uploaderName != null)
                          Text(
                            result.uploaderName!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                _playTrack(result);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Add to playlist'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show add to playlist dialog
              },
            ),
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: const Text('Add to queue'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Add to queue
              },
            ),
          ],
        ),
      ),
    );
  }
}
