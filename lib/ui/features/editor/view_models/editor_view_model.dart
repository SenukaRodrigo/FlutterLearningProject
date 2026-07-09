import 'package:flutter/foundation.dart';

/// Presentation state for the post editor (Write tab).
class EditorViewModel extends ChangeNotifier {
  String _title = '';
  String get title => _title;

  String _body = '';
  String get body => _body;

  /// Publishing is enabled once there is a title and some content.
  bool get canPublish => _title.trim().isNotEmpty && _body.trim().isNotEmpty;

  void updateTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void updateBody(String value) {
    _body = value;
    notifyListeners();
  }

  /// Placeholder publish action. Wire this to the data layer later.
  Future<void> publish() async {
    // No-op for now.
  }
}
