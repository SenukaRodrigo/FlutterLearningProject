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

  bool get notFound => !_isLoading && _post == null;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _post = await _repository.fetchById(_postId);

    _isLoading = false;
    notifyListeners();
  }
}
