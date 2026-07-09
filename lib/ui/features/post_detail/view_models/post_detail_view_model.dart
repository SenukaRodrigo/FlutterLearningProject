import 'package:flutter/foundation.dart';

import '../../../../data/repositories/post_repository.dart';
import '../../../../domain/models/post.dart';

/// Presentation state for a single post, loaded by id (deep-linkable).
class PostDetailViewModel extends ChangeNotifier {
  PostDetailViewModel(this._repository, this._postId) {
    load();
  }

  final PostRepository _repository;
  final String _postId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Post? _post;
  Post? get post => _post;

  List<Comment> _comments = const [];
  List<Comment> get comments => _comments;

  bool get notFound => !_isLoading && _post == null;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _post = await _repository.fetchPost(_postId);
    if (_post != null) {
      _comments = await _repository.fetchComments(_postId);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Optimistically toggles the like, then reconciles with the repository.
  Future<void> toggleLike() async {
    final current = _post;
    if (current == null) return;
    _post = await _repository.toggleLike(current.id);
    notifyListeners();
  }

  Future<void> addComment(String text) async {
    final current = _post;
    if (current == null || text.trim().isEmpty) return;

    final comment = await _repository.addComment(current.id, text.trim());
    _comments = [..._comments, comment];
    _post = current.copyWith(commentCount: current.commentCount + 1);
    notifyListeners();
  }
}
