import 'package:flutter/foundation.dart';

/// Presentation state for the login screen. Placeholder authentication.
class LoginViewModel extends ChangeNotifier {
  String _email = '';
  String _password = '';

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool get canSubmit =>
      _email.contains('@') && _password.length >= 6 && !_isSubmitting;

  void updateEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    notifyListeners();
  }

  /// Placeholder sign-in. Returns true on "success".
  Future<bool> signIn() async {
    _isSubmitting = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 400));

    _isSubmitting = false;
    notifyListeners();
    return true;
  }
}
