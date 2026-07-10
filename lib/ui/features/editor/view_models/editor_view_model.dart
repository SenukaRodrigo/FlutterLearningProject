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

  /// Why the post can't be published yet, or `null` once it is ready. The
  /// editor surfaces this rather than disabling the button, so pressing
  /// Publish on an empty draft explains itself.
  String? get validationError {
    if (_title.trim().isEmpty) return 'Add a title before publishing.';
    if (_body.trim().isEmpty) return 'Write some content before publishing.';
    return null;
  }

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
  /// is not ready to publish or the write failed.
  Future<Post?> publish() async {
    if (validationError != null || _isPublishing) return null;

    _isPublishing = true;
    notifyListeners();

    try {
      return await _repository.createPost(
        title: _title.trim(),
        body: _body.trim(),
        tags: _parseTags(),
      );
    } catch (_) {
      return null;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  /// Empties the draft after a successful publish.
  void reset() {
    _title = '';
    _body = '';
    _tagsInput = '';
    notifyListeners();
  }
}
