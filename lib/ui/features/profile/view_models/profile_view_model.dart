import 'package:flutter/foundation.dart';

import '../../../../data/repositories/post_repository.dart';
import '../../../../domain/models/post.dart';

/// Presentation state for the Profile tab.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel(this._repository) {
    load();
  }

  final PostRepository _repository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Author? _author;
  Author? get author => _author;

  int _postCount = 0;
  int get postCount => _postCount;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    final author = _repository.currentAuthor;
    final feed = await _repository.fetchFeed();

    _author = author;
    _postCount = feed.where((post) => post.author.id == author.id).length;

    _isLoading = false;
    notifyListeners();
  }
}
