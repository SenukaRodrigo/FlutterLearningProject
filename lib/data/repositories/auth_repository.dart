import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/models/post.dart';

/// A failure surfaced by [AuthRepository], carrying a message already written
/// for the person reading it.
///
/// Keeping Firebase's error codes behind this class means the UI never imports
/// `firebase_auth`, and a different auth backend would only have to produce the
/// same small set of messages.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

/// Contract for signing in, signing up, and signing out.
///
/// The UI depends only on this abstraction, so tests can swap in a fake and run
/// without Firebase.
abstract class AuthRepository {
  /// The signed-in author, or `null` when signed out.
  ///
  /// Emits the current value on subscribe and again on every auth change, so a
  /// listener never misses the initial state.
  Stream<Author?> get currentUser;

  /// The signed-in author right now, without waiting for the stream.
  Author? get currentAuthor;

  /// Throws an [AuthException] if the credentials are rejected.
  Future<Author> signIn({required String email, required String password});

  /// Creates an account. Throws an [AuthException] if it cannot be created.
  Future<Author> signUp({required String email, required String password});

  Future<void> signOut();
}

/// [AuthRepository] backed by Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  Stream<Author?> get currentUser =>
      _auth.authStateChanges().map(_toAuthor);

  @override
  Author? get currentAuthor => _toAuthor(_auth.currentUser);

  @override
  Future<Author> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _toAuthor(credential.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<Author> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _toAuthor(credential.user)!;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Maps a Firebase user onto the app's own [Author] model, so nothing above
  /// the data layer has to know Firebase exists.
  ///
  /// Firebase has no bio, and a fresh email/password account has no display
  /// name, so the local part of the address stands in until profiles are
  /// stored for real in the backend phase.
  static Author? _toAuthor(fb.User? user) {
    if (user == null) return null;

    final email = user.email ?? '';
    final fallbackName = email.contains('@') ? email.split('@').first : 'Reader';
    final displayName = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : fallbackName;

    return Author(
      id: user.uid,
      displayName: displayName,
      bio: '',
      avatarUrl: user.photoURL,
    );
  }

  /// Turns a Firebase error code into something worth showing a person.
  ///
  /// `invalid-credential` is what recent Firebase versions return for both a
  /// wrong password and an unknown email, since saying which would let an
  /// attacker enumerate accounts. The message stays deliberately vague to match.
  static String _messageFor(fb.FirebaseAuthException e) => switch (e.code) {
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'That email already has an account. Sign in instead.',
        'weak-password' => 'Choose a stronger password of at least 8 characters.',
        'invalid-email' => 'Enter a valid email address.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Try again in a few minutes.',
        'network-request-failed' => 'No connection. Check your network and try again.',
        'operation-not-allowed' =>
          'Email sign-in is not enabled for this project yet.',
        _ => 'Something went wrong. Try again.',
      };
}
