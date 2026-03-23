// ignore_for_file: invalid_annotation_target
import 'package:hive/hive.dart';

part 'community_post.g.dart';

/// Represents a user-generated post in the ChordMaster Free community feed.
///
/// Content is sanitised on assignment (HTML tags stripped) and capped at
/// [maxContentLength] characters.  Stored via Hive (type id 5).
@HiveType(typeId: 5)
class CommunityPost {
  /// Unique identifier (UUID v4).
  @HiveField(0)
  final String id;

  /// Display name of the post author.
  @HiveField(1)
  final String author;

  /// The sanitised post body (max [maxContentLength] characters, no HTML).
  @HiveField(2)
  final String content;

  /// UTC timestamp of when the post was created.
  @HiveField(3)
  final DateTime timestamp;

  /// Number of likes received.
  @HiveField(4)
  final int likes;

  /// Freeform tags associated with the post.
  @HiveField(5)
  final List<String> tags;

  /// Maximum allowed length for [content].
  static const int maxContentLength = 500;

  /// Creates a [CommunityPost].
  ///
  /// [content] is automatically sanitised via [_sanitise].
  CommunityPost({
    required this.id,
    required this.author,
    required String content,
    required this.timestamp,
    this.likes = 0,
    this.tags = const [],
  }) : content = _sanitise(content);

  /// Creates a [CommunityPost] directly with a pre-validated [content] field.
  ///
  /// Intended for internal use only (e.g. Hive deserialization).
  const CommunityPost._raw({
    required this.id,
    required this.author,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.tags,
  });

  /// Deserialises a [CommunityPost] from a JSON map.
  ///
  /// [timestamp] is expected as an ISO 8601 string.
  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String,
      author: json['author'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      likes: json['likes'] as int? ?? 0,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  /// Serialises this [CommunityPost] to a JSON map.
  ///
  /// [timestamp] is written as an ISO 8601 UTC string.
  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'content': content,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'likes': likes,
        'tags': tags,
      };

  /// Returns a copy of this [CommunityPost] with the specified fields replaced.
  ///
  /// If [content] is provided it is re-sanitised.
  CommunityPost copyWith({
    String? id,
    String? author,
    String? content,
    DateTime? timestamp,
    int? likes,
    List<String>? tags,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      tags: tags ?? this.tags,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Strips HTML tags from [raw] and truncates to [maxContentLength].
  static String _sanitise(String raw) {
    // Remove anything that looks like an HTML tag.
    final stripped = raw.replaceAll(RegExp(r'<[^>]*>'), '');
    if (stripped.length <= maxContentLength) return stripped;
    return stripped.substring(0, maxContentLength);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CommunityPost(id: $id, author: $author, likes: $likes, '
      'timestamp: ${timestamp.toIso8601String()})';
}
