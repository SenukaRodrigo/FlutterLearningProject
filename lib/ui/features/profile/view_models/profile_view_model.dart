import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/repositories/post_repository.dart';
import '../../../../domain/models/post.dart';

/// Lifecycle of the profile's data.
enum ProfileStatus { loading, ready, error }

/// Presentation state for the Profile tab: the signed-in author and the posts
/// they have published.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._repository) {
    _postChanges = _repository.postChanges.listen(_onPostChanged);
    load();
  }

  final PostRepository _repository;
  late final StreamSubscription<Post> _postChanges;

  ProfileStatus _status = ProfileStatus.loading;
  ProfileStatus get status => _status;

  Author get author => _repository.currentAuthor;

  /// The current author's posts, newest first.
  List<Post> _posts = const [];
  List<Post> get posts => _posts;

  int get postCount => _posts.length;

  int get likeCount =>
      _posts.fold(0, (total, post) => total + post.likeCount);

  Future<void> load() async {
    _status = ProfileStatus.loading;
    notifyListeners();

    try {
      final feed = await _repository.fetchFeed();
      _posts = _mine(feed);
      _status = ProfileStatus.ready;
    } catch (_) {
      _status = ProfileStatus.error;
    }
    notifyListeners();
  }

  /// Mirrors a like, comment, or new post made elsewhere into this list, so
  /// switching back to the Profile tab never shows a stale count.
  void _onPostChanged(Post post) {
    if (post.author.id != author.id) return;

    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _posts = [..._posts]..[index] = post;
    } else {
      _posts = _mine([post, ..._posts]);
    }
    notifyListeners();
  }

  List<Post> _mine(List<Post> posts) {
    final mine = posts.where((post) => post.author.id == author.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(mine);
  }

  @override
  void dispose() {
    _postChanges.cancel();
    super.dispose();
  }
}
