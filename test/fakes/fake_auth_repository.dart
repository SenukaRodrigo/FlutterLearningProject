import 'dart:async';

import 'package:inkflow/data/repositories/auth_repository.dart';
import 'package:inkflow/domain/models/post.dart';

/// In-memory [AuthRepository] for tests, so nothing has to reach Firebase.
///
/// Starts signed in by default: most tests are about a screen behind the login
/// wall and shouldn't have to set up auth to get there. Pass
/// `signedIn: false` to start signed out.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({bool signedIn = true}) {
    if (signedIn) _author = testAuthor;
    _controller.add(_author);
  }

  /// The author a signed-in fake reports.
  static const Author testAuthor = Author(
    id: 'u_test',
    displayName: 'Test User',
    bio: '',
    avatarUrl: null,
  );

  final StreamController<Author?> _controller =
      StreamController<Author?>.broadcast();

  Author? _author;

  /// When set, the next [signIn] or [signUp] throws this instead of succeeding.
  AuthException? nextFailure;

  /// Calls recorded for assertions.
  final List<String> calls = [];

  @override
  Stream<Author?> get currentUser async* {
    // Replays the current value on subscribe, matching the real repository:
    // a late listener still learns the state it missed.
    yield _author;
    yield* _controller.stream;
  }

  @override
  Author? get currentAuthor => _author;

  @override
  Future<Author> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn($email)');
    return _authenticate();
  }

  @override
  Future<Author> signUp({
    required String email,
    required String password,
  }) async {
    calls.add('signUp($email)');
    return _authenticate();
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut()');
    _author = null;
    _controller.add(null);
  }

  Future<Author> _authenticate() async {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
    _author = testAuthor;
    _controller.add(_author);
    return testAuthor;
  }

  void dispose() => _controller.close();
}
