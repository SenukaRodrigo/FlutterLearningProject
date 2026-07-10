import 'package:flutter/foundation.dart';

import '../../../../data/repositories/post_repository.dart';
import '../../../../domain/models/post.dart';

/// Lifecycle of a single post's data.
enum PostDetailStatus { loading, ready, notFound, error }

/// Presentation state for one post, loaded by id (deep-linkable).
///
/// Created per route, so navigating to a different post gets a fresh instance.
class PostDetailViewModel extends ChangeNotifier {
  PostDetailViewModel(this._repository, this.postId) {
    load();
  }

  final PostRepository _repository;
  final String postId;

  PostDetailStatus _status = PostDetailStatus.loading;
  PostDetailStatus get status => _status;

  Post? _post;
  Post? get post => _post;

  List<Comment> _comments = const [];
  List<Comment> get comments => _comments;

  /// True while a comment is in flight, so the composer can disable its button.
  bool _isSendingComment = false;
  bool get isSendingComment => _isSendingComment;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = PostDetailStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final post = await _repository.fetchPost(postId);
      if (post == null) {
        _status = PostDetailStatus.notFound;
        notifyListeners();
        return;
      }
      _post = post;
      _comments = await _repository.fetchComments(postId);
      _status = PostDetailStatus.ready;
    } catch (_) {
      _errorMessage = "Couldn't load this post.";
      _status = PostDetailStatus.error;
    }
    notifyListeners();
  }

  /// Flips the like immediately, then reconciles with the repository. The
  /// repository broadcasts the change, so the feed behind this screen updates
  /// its own copy of the post.
  Future<void> toggleLike() async {
    final current = _post;
    if (current == null) return;

    _post = current.copyWith(
      likedByMe: !current.likedByMe,
      likeCount: current.likeCount + (current.likedByMe ? -1 : 1),
    );
    notifyListeners();

    try {
      _post = await _repository.toggleLike(current.id);
    } catch (_) {
      _post = current;
    }
    notifyListeners();
  }

  /// Appends [text] as a comment. Returns whether it was accepted, so the
  /// composer only clears its field on success.
  Future<bool> addComment(String text) async {
    final current = _post;
    final trimmed = text.trim();
    if (current == null || trimmed.isEmpty || _isSendingComment) return false;

    _isSendingComment = true;
    notifyListeners();

    try {
      final comment = await _repository.addComment(current.id, trimmed);
      _comments = [..._comments, comment];
      _post = current.copyWith(commentCount: current.commentCount + 1);
      return true;
    } catch (_) {
      _errorMessage = "Couldn't post your comment.";
      return false;
    } finally {
      _isSendingComment = false;
      notifyListeners();
    }
  }
}
