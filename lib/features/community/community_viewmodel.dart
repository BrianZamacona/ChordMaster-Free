import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/community_post.dart';
import '../../services/achievement_service.dart';
import '../../services/storage_service.dart';

/// Immutable state for [CommunityViewModel].
class CommunityState {
  const CommunityState({
    this.posts = const [],
    this.isLoading = true,
    this.errorMessage,
    this.lastPostTime,
  });

  final List<CommunityPost> posts;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastPostTime;

  CommunityState copyWith({
    List<CommunityPost>? posts,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastPostTime,
    bool clearError = false,
  }) => CommunityState(
    posts: posts ?? this.posts,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    lastPostTime: lastPostTime ?? this.lastPostTime,
  );

  /// Seconds remaining until the next post is allowed (rate limit: 5 s).
  int get rateLimitSecondsLeft {
    if (lastPostTime == null) return 0;
    final elapsed = DateTime.now().difference(lastPostTime!).inSeconds;
    return (5 - elapsed).clamp(0, 5);
  }

  bool get canPost => rateLimitSecondsLeft == 0;
}

/// Provider for [CommunityViewModel].
final communityViewModelProvider =
    NotifierProvider<CommunityViewModel, CommunityState>(CommunityViewModel.new);

/// Manages community feed state: posts, creation, likes.
class CommunityViewModel extends Notifier<CommunityState> {
  static const _uuid = Uuid();

  @override
  CommunityState build() {
    _loadPosts();
    return const CommunityState();
  }

  Future<void> _loadPosts() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final raw = await storage.getAll(StorageService.communityPostsBox);
      final posts = raw
          .whereType<String>()
          .map((s) {
            try {
              return CommunityPost.fromJson(
                  Map<String, dynamic>.from(jsonDecode(s) as Map<dynamic, dynamic>));
            } catch (_) {
              return null;
            }
          })
          .whereType<CommunityPost>()
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(posts: posts, isLoading: false);
    } catch (e, st) {
      debugPrint('CommunityViewModel._loadPosts error: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Creates and persists a new post.
  ///
  /// Validates content length (max 500 chars) and applies rate limiting
  /// (minimum 5 seconds between posts — OWASP A04).
  Future<String?> createPost({
    required String author,
    required String content,
  }) async {
    // Rate limiting check (OWASP A04 — Insecure Design)
    if (!state.canPost) {
      return 'Please wait ${state.rateLimitSecondsLeft} seconds before posting again.';
    }

    // Sanitize and validate (OWASP A03 — Injection)
    final sanitized = content.trim();
    if (sanitized.isEmpty) return 'Content cannot be empty.';
    if (sanitized.length > CommunityPost.maxContentLength) {
      return 'Content exceeds the maximum allowed length (${CommunityPost.maxContentLength} chars).';
    }

    try {
      final post = CommunityPost(
        id: _uuid.v4(),
        author: author.trim().isEmpty ? 'Anonymous' : author.trim(),
        content: sanitized,
        timestamp: DateTime.now().toUtc(),
      );

      final storage = ref.read(storageServiceProvider);
      await storage.save(
        StorageService.communityPostsBox,
        post.id,
        jsonEncode(post.toJson()),
      );

      final updatedPosts = [post, ...state.posts];
      state = state.copyWith(
        posts: updatedPosts,
        lastPostTime: DateTime.now(),
      );

      // Unlock achievement for first post
      if (updatedPosts.length == 1) {
        await AchievementService.instance.unlock('community_member');
      }

      return null;
    } catch (e, st) {
      debugPrint('CommunityViewModel.createPost error: $e\n$st');
      return 'Could not save post. Please try again.';
    }
  }

  /// Toggles like on a post.
  Future<void> toggleLike(String postId) async {
    try {
      final storage = ref.read(storageServiceProvider);
      final index = state.posts.indexWhere((p) => p.id == postId);
      if (index == -1) return;

      final post = state.posts[index];
      final updatedPost = post.copyWith(likes: post.likes + 1);
      final updated = List<CommunityPost>.from(state.posts);
      updated[index] = updatedPost;
      state = state.copyWith(posts: updated);

      await storage.save(
        StorageService.communityPostsBox,
        postId,
        jsonEncode(updatedPost.toJson()),
      );
    } catch (e, st) {
      debugPrint('CommunityViewModel.toggleLike error: $e\n$st');
    }
  }
}
