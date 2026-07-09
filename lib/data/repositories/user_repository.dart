import '../../domain/models/user.dart';

/// Single source of truth for the current user/profile.
///
/// Backed by an in-memory sample user for now.
class UserRepository {
  final User _currentUser = const User(
    id: 'me',
    name: 'Senuka Rodrigo',
    handle: '@senuka',
    bio: 'Writing about Flutter, design, and the craft of shipping software.',
    avatarUrl: 'https://picsum.photos/seed/inkflow-avatar/200/200',
    postCount: 3,
  );

  /// Returns the currently signed-in user.
  Future<User> fetchCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _currentUser;
  }
}
