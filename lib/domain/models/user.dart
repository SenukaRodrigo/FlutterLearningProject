/// The signed-in author. Immutable domain model.
class User {
  const User({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.avatarUrl,
    this.postCount = 0,
  });

  final String id;
  final String name;
  final String handle;
  final String bio;
  final String avatarUrl;
  final int postCount;
}
