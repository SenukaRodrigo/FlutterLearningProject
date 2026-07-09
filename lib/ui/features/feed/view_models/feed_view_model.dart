import 'package:flutter/foundation.dart';

import '../../../../data/repositories/post_repository.dart';
import '../../../../domain/models/post.dart';

/// Presentation state for the feed screen.
class FeedViewModel extends ChangeNotifier {
  FeedViewModel(this._repository) {
    load();
  }

  final PostRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Post> _posts = const [];
  List<Post> get posts => _posts;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _posts = await _repository.fetchFeed();

    _isLoading = false;
    notifyListeners();
  }
}
