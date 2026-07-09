import 'package:flutter/foundation.dart';

import '../../../../data/repositories/post_repository.dart';
import '../../../../domain/models/post.dart';

/// Lifecycle of the feed's data.
enum FeedStatus { loading, ready, error }

/// Presentation state for the feed screen.
///
/// Owns the post list plus the active tag and search filters. Filtering is
/// delegated to [PostRepository.fetchFeed] rather than done in memory, so the
/// same view model works against a paginated backend later.
class FeedViewModel extends ChangeNotifier {
  FeedViewModel(this._repository) {
    load();
  }

  final PostRepository _repository;

  /// Identifies the most recent fetch. Responses from superseded fetches are
  /// discarded, so a slow request can't overwrite a newer one's results —
  /// easy to trigger by typing quickly into the search field.
  int _requestId = 0;

  FeedStatus _status = FeedStatus.loading;
  FeedStatus get status => _status;

  List<Post> _posts = const [];
  List<Post> get posts => _posts;

  /// Every tag across the unfiltered feed, alphabetically. Captured from the
  /// unfiltered fetch so the filter bar keeps its full set of chips even while
  /// a tag narrows the visible posts.
  List<String> _allTags = const [];
  List<String> get allTags => _allTags;

  String? _activeTag;
  String? get activeTag => _activeTag;

  String _query = '';
  String get query => _query;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasFilters => _activeTag != null || _query.isNotEmpty;

  /// A successful fetch that matched nothing, as opposed to one still running.
  bool get isEmpty => _status == FeedStatus.ready && _posts.isEmpty;

  /// Fetches the feed, showing a spinner while it runs.
  Future<void> load() => _fetch(showSpinner: true);

  /// Pull-to-refresh. Leaves the currently displayed posts in place if the
  /// fetch fails, so a dropped connection never blanks a populated feed;
  /// [errorMessage] is set for the caller to surface.
  Future<void> refresh() => _fetch(showSpinner: false);

  /// Applies [tag] as the filter, or clears it if it is already active.
  Future<void> selectTag(String tag) {
    _activeTag = _activeTag == tag ? null : tag;
    notifyListeners();
    return _fetch(showSpinner: true);
  }

  Future<void> search(String query) {
    final next = query.trim();
    if (next == _query) return Future<void>.value();
    _query = next;
    notifyListeners();
    return _fetch(showSpinner: true);
  }

  Future<void> clearFilters() {
    if (!hasFilters) return Future<void>.value();
    _activeTag = null;
    _query = '';
    notifyListeners();
    return _fetch(showSpinner: true);
  }

  /// Flips the like on [id] immediately, then reconciles with the repository.
  /// A failure rolls the post back to its previous state.
  Future<void> toggleLike(String id) async {
    final index = _posts.indexWhere((post) => post.id == id);
    if (index == -1) return;

    final original = _posts[index];
    _replace(
      id,
      original.copyWith(
        likedByMe: !original.likedByMe,
        likeCount: original.likeCount + (original.likedByMe ? -1 : 1),
      ),
    );
    notifyListeners();

    try {
      _replace(id, await _repository.toggleLike(id));
    } catch (_) {
      _replace(id, original);
    }
    notifyListeners();
  }

  Future<void> _fetch({required bool showSpinner}) async {
    final requestId = ++_requestId;
    if (showSpinner) {
      _status = FeedStatus.loading;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final posts = await _repository.fetchFeed(
        tag: _activeTag,
        query: _query.isEmpty ? null : _query,
      );
      if (requestId != _requestId) return;

      _posts = posts;
      if (!hasFilters) _allTags = _tagsOf(posts);
      _errorMessage = null;
      _status = FeedStatus.ready;
    } catch (_) {
      if (requestId != _requestId) return;

      _errorMessage = "Couldn't load the feed. Check your connection.";
      // A refresh keeps whatever is already on screen; a load has nothing to
      // fall back to and must hand the user a retry.
      _status =
          !showSpinner && _posts.isNotEmpty ? FeedStatus.ready : FeedStatus.error;
    }
    notifyListeners();
  }

  /// Swaps the post carrying [id]. Looks the index up again because an
  /// in-flight fetch may have reordered or dropped it since the caller looked.
  void _replace(String id, Post post) {
    final index = _posts.indexWhere((p) => p.id == id);
    if (index == -1) return;
    _posts = [..._posts]..[index] = post;
  }

  static List<String> _tagsOf(List<Post> posts) {
    final tags = {for (final post in posts) ...post.tags}.toList()..sort();
    return List.unmodifiable(tags);
  }
}
