import 'package:intl/intl.dart';

/// A blog post. Immutable domain model exposed by the data layer to the UI.
class Post {
  const Post({
    required this.id,
    required this.title,
    required this.author,
    required this.excerpt,
    required this.body,
    required this.coverImageUrl,
    required this.publishedAt,
    this.readMinutes = 3,
  });

  final String id;
  final String title;
  final String author;

  /// Short teaser shown in the feed.
  final String excerpt;

  /// Full article content, formatted as Markdown.
  final String body;

  final String coverImageUrl;
  final DateTime publishedAt;
  final int readMinutes;

  /// Human-friendly published date, e.g. "July 7, 2026".
  String get formattedDate => DateFormat.yMMMMd().format(publishedAt);
}
