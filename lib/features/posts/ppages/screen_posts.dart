import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/features/posts/blocs/post_mutation_bloc/post_mutation_bloc.dart';
import 'package:crisant_connect/features/posts/blocs/posts_list_bloc/posts_list_bloc.dart';
import 'package:crisant_connect/features/posts/models/posts_list_response.dart';
import 'package:crisant_connect/features/posts/ppages/screen_create_post.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/crisant_app_bar.dart';
import 'package:crisant_connect/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScreenPosts extends StatefulWidget {
  final bool isActive;

  const ScreenPosts({super.key, this.isActive = false});

  @override
  State<ScreenPosts> createState() => _ScreenPostsState();
}

class _ScreenPostsState extends State<ScreenPosts>
    with SingleTickerProviderStateMixin {
  static const _views = ['scheduled', 'published', 'rejected'];
  static const _tabLabels = ['Scheduled', 'Published', 'Rejected'];

  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _postsRequested = false;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _views.length, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _searchController.addListener(_handleSearchChanged);
    _requestPostsIfActive();
  }

  @override
  void didUpdateWidget(covariant ScreenPosts oldWidget) {
    super.didUpdateWidget(oldWidget);
    _requestPostsIfActive();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _requestPostsIfActive() {
    if (!widget.isActive || _postsRequested) return;
    _postsRequested = true;
    _fetchPosts();
  }

  void _handleTabChanged() {
    if (_selectedTabIndex != _tabController.index) {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    }

    if (_tabController.indexIsChanging) return;
    _fetchPosts();
  }

  void _handleSearchChanged() {
    if (mounted) setState(() {});
  }

  void _fetchPosts() {
    context.read<PostsListBloc>().add(
      FetchPostsListRequested(view: _views[_selectedTabIndex]),
    );
  }

  bool get _canEditCurrentView {
    final view = _views[_selectedTabIndex];
    return view == 'scheduled' || view == 'rejected';
  }

  Future<void> _openEditPost(PostListItem post) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScreenCreatePost(isActive: true, initialPost: post),
      ),
    );

    if (!mounted || updated != true) return;
    _fetchPosts();
  }

  Future<void> _confirmDeletePost(PostListItem post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete post?'),
        content: Text(
          'This will permanently delete "${post.displayTitle}".',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD30000),
              foregroundColor: Appcolors.kwhitecolor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;
    context.read<PostMutationBloc>().add(DeletePostRequested(postId: post.id));
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return BlocListener<PostMutationBloc, PostMutationState>(
      listener: (context, state) {
        if (state is DeletePostSuccess) {
          CustomSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.success,
          );
          _fetchPosts();
        } else if (state is PostMutationFailure &&
            state.action == PostMutationAction.delete) {
          CustomSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
        }
      },
      child: AppBackground(
        opacity: 0.35,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CrisantAppBar(),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.wp(4.6),
                  ResponsiveUtils.hp(1.6),
                  ResponsiveUtils.wp(4.6),
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PostsHeader(label: _tabLabels[_selectedTabIndex]),
                    SizedBox(height: ResponsiveUtils.hp(1.8)),
                    _PostsSearchField(controller: _searchController),
                    SizedBox(height: ResponsiveUtils.hp(1.8)),
                    _PostsTabBar(
                      controller: _tabController,
                      labels: _tabLabels,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<PostsListBloc, PostsListState>(
                  builder: (context, state) {
                    if (state is PostsListLoading ||
                        state is PostsListInitial) {
                      return const _PostsLoading();
                    }

                    if (state is PostsListFailure) {
                      return _PostsError(
                        message: state.message,
                        onRetry: _fetchPosts,
                      );
                    }

                    final posts = state is PostsListSuccess
                        ? _filteredPosts(state.posts)
                        : const <PostListItem>[];

                    if (posts.isEmpty) {
                      return _PostsEmpty(
                        hasSearch: _searchController.text.trim().isNotEmpty,
                      );
                    }

                    return RefreshIndicator(
                      color: Appcolors.kprimarycolor,
                      onRefresh: () async => _fetchPosts(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveUtils.wp(4.6),
                          ResponsiveUtils.hp(2.2),
                          ResponsiveUtils.wp(4.6),
                          ResponsiveUtils.hp(15),
                        ),
                        itemCount: posts.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: ResponsiveUtils.hp(1.8)),
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          return BlocBuilder<
                            PostMutationBloc,
                            PostMutationState
                          >(
                            builder: (context, mutationState) {
                              final isDeleting =
                                  mutationState is DeletePostLoading &&
                                  mutationState.postId == post.id;
                              return _PostHistoryCard(
                                post: post,
                                canEdit: _canEditCurrentView,
                                isDeleting: isDeleting,
                                onEdit: () => _openEditPost(post),
                                onDelete: () => _confirmDeletePost(post),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PostListItem> _filteredPosts(List<PostListItem> posts) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return posts;

    return posts.where((post) {
      return post.displayTitle.toLowerCase().contains(query) ||
          post.clientName.toLowerCase().contains(query) ||
          post.createdByName.toLowerCase().contains(query) ||
          post.targets.any(
            (target) =>
                target.platform.toLowerCase().contains(query) ||
                target.profileName.toLowerCase().contains(query),
          );
    }).toList();
  }
}

class _PostsHeader extends StatelessWidget {
  final String label;

  const _PostsHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${label.toUpperCase()} CONTENT',
          style: TextStyle(
            color: const Color(0xFFB33620),
            fontSize: ResponsiveUtils.sp(3.1).clamp(10, 12).toDouble(),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$label posts',
          style: TextStyle(
            color: const Color(0xFF071426),
            fontSize: ResponsiveUtils.sp(6.6).clamp(24, 30).toDouble(),
            fontWeight: FontWeight.w800,
            height: 1.22,
          ),
        ),
      ],
    );
  }
}

class _PostsSearchField extends StatelessWidget {
  final TextEditingController controller;

  const _PostsSearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6DCE4)),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF111827)),
          hintText: 'Search posts, clients, or targets',
          hintStyle: TextStyle(
            color: Color(0xFF929AA7),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        ),
      ),
    );
  }
}

class _PostsTabBar extends StatelessWidget {
  final TabController controller;
  final List<String> labels;

  const _PostsTabBar({required this.controller, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: const Color(0xFFFFE7E1),
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: const Color(0xFFB33620),
        unselectedLabelColor: const Color(0xFF5E6673),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        tabs: labels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}

class _PostHistoryCard extends StatelessWidget {
  final PostListItem post;
  final bool canEdit;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PostHistoryCard({
    required this.post,
    required this.canEdit,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  post.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF071426),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(status: post.displayStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            post.createdByName.isEmpty ? 'Unknown creator' : post.createdByName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF252C36),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          _MetaLine(
            icon: Icons.business_rounded,
            text: post.clientName.isEmpty ? 'Unknown client' : post.clientName,
          ),
          const SizedBox(height: 9),
          _MetaLine(
            icon: Icons.calendar_month_rounded,
            text: _formatPostDate(post.scheduledFor ?? post.createdAt),
          ),
          const SizedBox(height: 13),
          Divider(color: const Color(0xFFCCD2DA), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 9,
                  runSpacing: 8,
                  children: _targetBadges(post),
                ),
              ),
              if (canEdit)
                IconButton(
                  onPressed: isDeleting ? null : onEdit,
                  tooltip: 'Edit post',
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Color(0xFF071426),
                    size: 23,
                  ),
                ),
              IconButton(
                onPressed: isDeleting ? null : onDelete,
                tooltip: 'Delete post',
                icon: isDeleting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFFD30000),
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFD30000),
                        size: 24,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _targetBadges(PostListItem post) {
    if (post.targets.isEmpty) {
      return [
        _PlatformBadge(
          platform: post.mediaKind.isEmpty ? post.contentType : post.mediaKind,
          status: post.displayStatus,
        ),
      ];
    }

    return post.targets
        .map(
          (target) =>
              _PlatformBadge(platform: target.platform, status: target.status),
        )
        .toList();
  }

  String _formatPostDate(DateTime? value) {
    if (value == null) return 'No date available';
    final local = value.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'pm' : 'am';
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '${local.day}/${local.month}/${local.year}, '
        '$hour12:$minute:$second $period';
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF5E6673)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF202833),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isGood = normalized == 'published' || normalized == 'approved';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isGood ? const Color(0xFFDFF8E7) : const Color(0xFFFFDCD5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        normalized,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isGood ? const Color(0xFF127A36) : const Color(0xFFC93119),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlatformBadge extends StatelessWidget {
  final String platform;
  final String status;

  const _PlatformBadge({required this.platform, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = platform.toLowerCase();
    final color = normalized.contains('instagram')
        ? const Color(0xFFD5298D)
        : normalized.contains('facebook')
        ? const Color(0xFF1877F2)
        : const Color(0xFF7C3AED);
    final icon = normalized.contains('instagram')
        ? Icons.camera_alt_rounded
        : normalized.contains('facebook')
        ? Icons.facebook_rounded
        : Icons.public_rounded;

    return Tooltip(
      message: '${platform.isEmpty ? 'Target' : platform}: $status',
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Appcolors.kwhitecolor, size: 18),
      ),
    );
  }
}

class _PostsLoading extends StatelessWidget {
  const _PostsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Appcolors.kprimarycolor),
    );
  }
}

class _PostsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _PostsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Appcolors.kredcolor,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF202833),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: Appcolors.kprimarycolor,
                foregroundColor: Appcolors.kwhitecolor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsEmpty extends StatelessWidget {
  final bool hasSearch;

  const _PostsEmpty({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          hasSearch ? 'No posts match your search' : 'No posts found',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5E6673),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
