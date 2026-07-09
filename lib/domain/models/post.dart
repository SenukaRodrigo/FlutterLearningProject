import 'package:intl/intl.dart';

/// A blog author.
///
/// Immutable domain model. Serializes cleanly to/from a plain map so it can be
/// stored as a Firestore document (or nested field) without changes.
class Author {
  const Author({
    required this.id,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String bio;

  /// Optional profile image URL.
  final String? avatarUrl;

  factory Author.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final String id,
        'displayName': final String displayName,
        'bio': final String bio,
      } =>
        Author(
          id: id,
          displayName: displayName,
          bio: bio,
          avatarUrl: json['avatarUrl'] as String?,
        ),
      _ => throw const FormatException('Failed to parse Author.'),
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'bio': bio,
        'avatarUrl': avatarUrl,
      };
}

/// A blog post.
///
/// Immutable; mutations are expressed via [copyWith]. Serializes cleanly to/from
/// a Firestore-style map (dates as ISO-8601 strings, author as a nested map).
class Post {
  const Post({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.tags,
    required this.createdAt,
    this.coverImageUrl,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
  });

  final String id;
  final String title;

  /// Full article content, formatted as Markdown.
  final String body;

  final Author author;
  final List<String> tags;

  /// Optional hero image URL.
  final String? coverImageUrl;

  final DateTime createdAt;
  final int likeCount;
  final int commentCount;

  /// Whether the current user has liked this post.
  final bool likedByMe;

  /// A short plain-text teaser derived from the Markdown [body].
  String get excerpt {
    final plain = body
        // A body conventionally opens with its own title as an H1; repeating it
        // under the title on a feed card wastes both excerpt lines.
        .replaceFirst(RegExp(r'^\s*#{1,6}[^\n]*\n'), '')
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ') // fenced code blocks
        .replaceAll(RegExp(r'[#>*_`~\-\[\]()]'), ' ') // markdown tokens
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (plain.length <= 140) return plain;
    return '${plain.substring(0, 140).trimRight()}…';
  }

  /// Estimated reading time in whole minutes (~200 words/minute, min 1).
  int get readMinutes {
    final words = body.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / 200).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  /// Human-friendly created date, e.g. "July 7, 2026".
  String get formattedDate => DateFormat.yMMMMd().format(createdAt);

  /// Compact created date for dense surfaces like feed cards, e.g. "Jul 7".
  String get shortDate => DateFormat.MMMd().format(createdAt);

  Post copyWith({
    String? id,
    String? title,
    String? body,
    Author? author,
    List<String>? tags,
    String? coverImageUrl,
    DateTime? createdAt,
    int? likeCount,
    int? commentCount,
    bool? likedByMe,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      author: author ?? this.author,
      tags: tags ?? this.tags,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': final String id,
        'title': final String title,
        'body': final String body,
        'author': final Map<String, dynamic> author,
        'tags': final List<dynamic> tags,
        'createdAt': final String createdAt,
        'likeCount': final int likeCount,
        'commentCount': final int commentCount,
        'likedByMe': final bool likedByMe,
      } =>
        Post(
          id: id,
          title: title,
          body: body,
          author: Author.fromJson(author),
          tags: tags.cast<String>(),
          coverImageUrl: json['coverImageUrl'] as String?,
          createdAt: DateTime.parse(createdAt),
          likeCount: likeCount,
          commentCount: commentCount,
          likedByMe: likedByMe,
        ),
      _ => throw const FormatException('Failed to parse Post.'),
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'author': author.toJson(),
        'tags': tags,
        'coverImageUrl': coverImageUrl,
        'createdAt': createdAt.toIso8601String(),
        'likeCount': likeCount,
        'commentCount': commentCount,
        'likedByMe': likedByMe,
      };
}

/// A comment on a [Post].
class Comment {
  const Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final Author author;
  final String text;
  final DateTime createdAt;

  /// Human-friendly created date, e.g. "Jul 7, 2026".
  String get formattedDate => DateFormat.yMMMd().format(createdAt);
}
