import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/widgets/feature_module_scaffold.dart';
import '../../models/community_post.dart';
import 'community_viewmodel.dart';

/// Community feed screen.
class CommunityScreen extends ConsumerStatefulWidget {
  /// Creates the [CommunityScreen].
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _authorController = TextEditingController();
  final _contentController = TextEditingController();
  int _contentLength = 0;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() {
      setState(() => _contentLength = _contentController.text.length);
    });
  }

  @override
  void dispose() {
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPost(BuildContext context) async {
    final vm = ref.read(communityViewModelProvider.notifier);
    final error = await vm.createPost(
      author: _authorController.text,
      content: _contentController.text,
    );
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      _contentController.clear();
      _authorController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityViewModelProvider);
    final theme = Theme.of(context);

    return FeatureModuleScaffold(
      title: AppStrings.moduleCommunity,
      body: Column(
        children: [
          // Post creation form
          Card(
            margin: const EdgeInsets.all(12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.author,
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.writePostHint,
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    maxLength: CommunityPost.maxContentLength,
                    buildCounter: (context,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$_contentLength / ${CommunityPost.maxContentLength}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _contentLength > CommunityPost.maxContentLength
                            ? Colors.red
                            : theme.colorScheme.onSurface.withAlpha(150),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: state.canPost &&
                            _contentController.text.trim().isNotEmpty
                        ? () => _submitPost(context)
                        : null,
                    icon: const Icon(Icons.send),
                    label: Text(state.canPost
                        ? AppStrings.post
                        : 'Wait ${state.rateLimitSecondsLeft}s…'),
                  ),
                ],
              ),
            ),
          ),
          // Posts list
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.posts.isEmpty
                    ? Center(
                        child: Text(AppStrings.noPostsYet,
                            style: theme.textTheme.bodyLarge))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: state.posts.length,
                        itemBuilder: (context, i) => _PostCard(
                          post: state.posts[i],
                          onLike: () => ref
                              .read(communityViewModelProvider.notifier)
                              .toggleLike(state.posts[i].id),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onLike});
  final CommunityPost post;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dt = post.timestamp.toLocal();
    final dateStr =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    post.author.isNotEmpty ? post.author[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author,
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(150)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.content, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: const Icon(Icons.favorite_outline),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text('${post.likes}', style: theme.textTheme.labelMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
