import 'package:flutter/foundation.dart';

import '../../../../data/repositories/auth_repository.dart';

/// Whether the auth form signs an existing user in or creates a new account.
enum AuthMode { login, signup }

/// Presentation state for the auth screen.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel(this._repository);

  final AuthRepository _repository;

  AuthMode _mode = AuthMode.login;
  AuthMode get mode => _mode;

  bool get isLogin => _mode == AuthMode.login;

  String _email = '';
  String get email => _email;

  String _password = '';
  String get password => _password;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Deliberately loose: something, an @, something, a dot, something. Strict
  /// email regexes reject valid addresses, and the server is the real authority.
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const int minPasswordLength = 8;

  /// Validation messages for the form fields, or `null` when each is valid.
  /// Returned rather than shown eagerly, so the UI can hold them back until the
  /// user has actually typed something or pressed submit.
  String? get emailError {
    if (_email.trim().isEmpty) return 'Enter your email address.';
    if (!_emailPattern.hasMatch(_email.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? get passwordError {
    if (_password.isEmpty) return 'Enter your password.';
    if (_password.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters.';
    }
    return null;
  }

  bool get isValid => emailError == null && passwordError == null;

  void updateEmail(String value) {
    _email = value;
    _errorMessage = null;
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    _errorMessage = null;
    notifyListeners();
  }

  void toggleMode() {
    _mode = isLogin ? AuthMode.signup : AuthMode.login;
    _errorMessage = null;
    notifyListeners();
  }

  /// Signs in or registers, returning whether it succeeded. On failure
  /// [errorMessage] carries something worth showing the user.
  ///
  /// Navigation is left to the router's redirect, which is watching auth state:
  /// this only reports the outcome.
  Future<bool> submit() async {
    if (!isValid || _isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (isLogin) {
        await _repository.signIn(email: _email, password: _password);
      } else {
        await _repository.signUp(email: _email, password: _password);
      }
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
