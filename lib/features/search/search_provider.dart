import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../data/services/youtube_service.dart';
import '../../models/search_result.dart';

/// Provider for the current search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search results with debounce
final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.trim().isEmpty) {
    return [];
  }

  // Debounce: wait before searching
  await Future.delayed(
    const Duration(milliseconds: ApiConstants.searchDebounceMs),
  );

  // Check if query changed during debounce
  if (ref.read(searchQueryProvider) != query) {
    throw Exception('Query changed'); // This will be caught and ignored
  }

  final youtubeService = ref.read(youtubeServiceProvider);
  return youtubeService.search(query);
});

/// Provider for search state (includes loading and error states)
class SearchState {
  final List<SearchResult> results;
  final bool isLoading;
  final String? errorMessage;
  final String query;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
    this.query = '',
  });

  SearchState copyWith({
    List<SearchResult>? results,
    bool? isLoading,
    String? errorMessage,
    String? query,
    bool clearError = false,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      query: query ?? this.query,
    );
  }
}

/// Search notifier for managing search state
class SearchNotifier extends StateNotifier<SearchState> {
  final YouTubeService _youtubeService;
  Timer? _debounceTimer;

  SearchNotifier(this._youtubeService) : super(const SearchState());

  /// Update search query with debounce
  void setQuery(String query) {
    _debounceTimer?.cancel();

    state = state.copyWith(query: query, clearError: true);

    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    _debounceTimer = Timer(
      const Duration(milliseconds: ApiConstants.searchDebounceMs),
      () => _performSearch(query),
    );
  }

  /// Perform the actual search
  Future<void> _performSearch(String query) async {
    // Double-check query hasn't changed
    if (state.query != query) return;

    try {
      final results = await _youtubeService.search(query);

      // Only update if query is still the same
      if (state.query == query) {
        state = state.copyWith(results: results, isLoading: false);
      }
    } catch (e) {
      if (state.query == query) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Search failed. Please try again.',
        );
      }
    }
  }

  /// Clear search
  void clear() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  /// Retry last search
  void retry() {
    if (state.query.isNotEmpty) {
      setQuery(state.query);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Provider for search notifier
final searchNotifierProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
      return SearchNotifier(ref.watch(youtubeServiceProvider));
    });
