import 'package:flutter/foundation.dart';

/// Whether the auth form signs an existing user in or creates a new account.
enum AuthMode { login, signup }

/// Presentation state for the auth screen.
///
/// Authentication itself is not wired up yet: [submit] fakes a round trip so
/// the UI can be built and tested. See the TODO in [submit] for where Firebase
/// Auth plugs in during the backend phase.
class LoginViewModel extends ChangeNotifier {
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

  /// Signs in or registers, returning whether it succeeded.
  Future<bool> submit() async {
    if (!isValid || _isSubmitting) return false;

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // TODO(backend): replace with Firebase Auth. This is the only place the
      // screen touches authentication, so swapping it in means calling
      //
      //   isLogin
      //     ? FirebaseAuth.instance.signInWithEmailAndPassword(...)
      //     : FirebaseAuth.instance.createUserWithEmailAndPassword(...)
      //
      // and mapping FirebaseAuthException.code onto _errorMessage. The router
      // will also need a redirect guarding the shell routes on authState.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      return true;
    } catch (_) {
      _errorMessage = 'Something went wrong. Try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
