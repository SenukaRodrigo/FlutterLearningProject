import 'package:flutter/foundation.dart';

import '../../../../data/repositories/post_repository.dart';
import '../../../../domain/models/post.dart';

/// Presentation state for the post editor (Write tab).
class EditorViewModel extends ChangeNotifier {
  EditorViewModel(this._repository);

  final PostRepository _repository;

  String _title = '';
  String get title => _title;

  String _body = '';
  String get body => _body;

  String _tagsInput = '';
  String get tagsInput => _tagsInput;

  bool _isPublishing = false;
  bool get isPublishing => _isPublishing;

  /// Publishing is enabled once there is a title and some content.
  bool get canPublish =>
      _title.trim().isNotEmpty && _body.trim().isNotEmpty && !_isPublishing;

  void updateTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void updateBody(String value) {
    _body = value;
    notifyListeners();
  }

  void updateTags(String value) {
    _tagsInput = value;
    notifyListeners();
  }

  List<String> _parseTags() => _tagsInput
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();

  /// Creates the post via the repository and returns it, or `null` if the form
  /// is not ready to publish.
  Future<Post?> publish() async {
    if (!canPublish) return null;

    _isPublishing = true;
    notifyListeners();

    try {
      return await _repository.createPost(
        title: _title.trim(),
        body: _body.trim(),
        tags: _parseTags(),
      );
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }
}
