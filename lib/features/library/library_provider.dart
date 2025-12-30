import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/playlist_repository.dart';
import '../../models/playlist.dart';

/// Provider that watches all playlists from the database
final playlistsStreamProvider = StreamProvider<List<Playlist>>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return repository.watchAllPlaylists();
});

/// Provider for creating a new playlist
final createPlaylistProvider = FutureProvider.family<Playlist, String>((
  ref,
  name,
) async {
  final repository = ref.read(playlistRepositoryProvider);
  return repository.createPlaylist(name);
});

/// Provider for deleting a playlist
final deletePlaylistProvider = FutureProvider.family<void, int>((
  ref,
  id,
) async {
  final repository = ref.read(playlistRepositoryProvider);
  return repository.deletePlaylist(id);
});

/// Provider for getting a single playlist by ID
final playlistByIdProvider = FutureProvider.family<Playlist?, int>((
  ref,
  id,
) async {
  final repository = ref.read(playlistRepositoryProvider);
  return repository.getPlaylistById(id);
});

/// Notifier for library actions (non-stream operations)
class LibraryNotifier extends StateNotifier<AsyncValue<void>> {
  final PlaylistRepository _repository;

  LibraryNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Create a new playlist
  Future<Playlist?> createPlaylist(String name) async {
    state = const AsyncValue.loading();
    try {
      final playlist = await _repository.createPlaylist(name);
      state = const AsyncValue.data(null);
      return playlist;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Delete a playlist
  Future<void> deletePlaylist(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deletePlaylist(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Rename a playlist
  Future<void> renamePlaylist(int id, String newName) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePlaylistName(id, newName);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for library actions
final libraryNotifierProvider =
    StateNotifierProvider<LibraryNotifier, AsyncValue<void>>((ref) {
      return LibraryNotifier(ref.watch(playlistRepositoryProvider));
    });
