import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/core/urls.dart';
import 'package:crisant_connect/features/posts/blocs/post_mutation_bloc/post_mutation_bloc.dart';
import 'package:crisant_connect/features/posts/blocs/posts_list_bloc/posts_list_bloc.dart';
import 'package:crisant_connect/features/posts/models/posts_list_response.dart';
import 'package:crisant_connect/features/posts/ppages/screen_create_post.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/crisant_app_bar.dart';
import 'package:crisant_connect/widgets/custom_snackbar.dart';
import 'package:crisant_connect/widgets/social_platform_icon.dart';
import 'package:crisant_connect/widgets/video_thumbnail_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

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

  bool get _canDeleteCurrentView {
    return _views[_selectedTabIndex] != 'published';
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

  Future<void> _openPostDetails(PostListItem post) async {
    if (ResponsiveUtils.isMacBook(context)) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final size = MediaQuery.sizeOf(dialogContext);
          final dialogWidth = (size.width - 64).clamp(360.0, 1180.0).toDouble();
          final dialogHeight = (size.height - 80)
              .clamp(420.0, 760.0)
              .toDouble();

          return AlertDialog(
            backgroundColor: Appcolors.kwhitecolor,
            surfaceTintColor: Appcolors.kwhitecolor,
            clipBehavior: Clip.antiAlias,
            insetPadding: const EdgeInsets.all(32),
            contentPadding: EdgeInsets.zero,
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            content: SizedBox(
              width: dialogWidth,
              height: dialogHeight,
              child: _PostDetailsPanel(
                post: post,
                showScrollIndicator: true,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Close'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (ResponsiveUtils.isDesktop(context)) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final height = MediaQuery.sizeOf(dialogContext).height;
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 1180,
                maxHeight: height * 0.88,
              ),
              child: _PostDetailsPanel(
                post: post,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          );
        },
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: _PostDetailsPanel(
            post: post,
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        );
      },
    );
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
                padding: ResponsiveUtils.pagePadding(
                  context,
                  top: ResponsiveUtils.hp(1.6),
                ),
                child: ResponsiveUtils.constrainWidth(
                  context: context,
                  maxWidth: ResponsiveUtils.isDesktop(context)
                      ? ResponsiveUtils.pageMaxWidth
                      : ResponsiveUtils.narrowPageMaxWidth,
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (ResponsiveUtils.isDesktop(context)) {
                            return ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: ResponsiveUtils.pagePadding(
                                context,
                                top: ResponsiveUtils.hp(2.2),
                                bottom: ResponsiveUtils.bottomScrollPadding(
                                  context,
                                ),
                              ),
                              children: [
                                ResponsiveUtils.constrainWidth(
                                  context: context,
                                  maxWidth: ResponsiveUtils.pageMaxWidth,
                                  child: _PostsDesktopGrid(
                                    posts: posts,
                                    canEdit: _canEditCurrentView,
                                    canDelete: _canDeleteCurrentView,
                                    onOpenDetails: _openPostDetails,
                                    onEdit: _openEditPost,
                                    onDelete: _confirmDeletePost,
                                  ),
                                ),
                              ],
                            );
                          }

                          return ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: ResponsiveUtils.pagePadding(
                              context,
                              top: ResponsiveUtils.hp(2.2),
                              bottom: ResponsiveUtils.bottomScrollPadding(
                                context,
                              ),
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
                                  return ResponsiveUtils.constrainWidth(
                                    context: context,
                                    maxWidth:
                                        ResponsiveUtils.narrowPageMaxWidth,
                                    child: _PostHistoryCard(
                                      post: post,
                                      canEdit: _canEditCurrentView,
                                      canDelete: _canDeleteCurrentView,
                                      isDeleting: isDeleting,
                                      onTap: () => _openPostDetails(post),
                                      onEdit: () => _openEditPost(post),
                                      onDelete: () => _confirmDeletePost(post),
                                    ),
                                  );
                                },
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
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${label.toUpperCase()} CONTENT',
          style: TextStyle(
            color: const Color(0xFFB33620),
            fontSize: isDesktop
                ? 12.0
                : ResponsiveUtils.sp(3.1).clamp(10, 12).toDouble(),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$label posts',
          style: TextStyle(
            color: const Color(0xFF071426),
            fontSize: isDesktop
                ? 34.0
                : ResponsiveUtils.sp(6.6).clamp(24, 30).toDouble(),
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
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Container(
      constraints: BoxConstraints(minHeight: isDesktop ? 54 : 0),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD6DCE4)),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: TextStyle(
          color: const Color(0xFF111827),
          fontSize: isDesktop ? 17 : 15,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.search_rounded,
            color: const Color(0xFF111827),
            size: isDesktop ? 25 : 24,
          ),
          hintText: 'Search posts, clients, or targets',
          hintStyle: TextStyle(
            color: const Color(0xFF929AA7),
            fontSize: isDesktop ? 16 : 15,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: isDesktop ? 17 : 15,
          ),
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
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Container(
      height: isDesktop ? 54 : 48,
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
        labelStyle: TextStyle(
          fontSize: isDesktop ? 14 : 12,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: isDesktop ? 14 : 12,
          fontWeight: FontWeight.w700,
        ),
        tabs: labels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}

class _PostsDesktopGrid extends StatelessWidget {
  final List<PostListItem> posts;
  final bool canEdit;
  final bool canDelete;
  final ValueChanged<PostListItem> onOpenDetails;
  final ValueChanged<PostListItem> onEdit;
  final ValueChanged<PostListItem> onDelete;

  const _PostsDesktopGrid({
    required this.posts,
    required this.canEdit,
    required this.canDelete,
    required this.onOpenDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const spacing = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1600 ? 3 : 2;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: posts.map((post) {
            return BlocBuilder<PostMutationBloc, PostMutationState>(
              builder: (context, mutationState) {
                final isDeleting =
                    mutationState is DeletePostLoading &&
                    mutationState.postId == post.id;
                return SizedBox(
                  width: cardWidth,
                  child: _PostHistoryCard(
                    post: post,
                    canEdit: canEdit,
                    canDelete: canDelete,
                    isDeleting: isDeleting,
                    onTap: () => onOpenDetails(post),
                    onEdit: () => onEdit(post),
                    onDelete: () => onDelete(post),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

class _PostHistoryCard extends StatelessWidget {
  final PostListItem post;
  final bool canEdit;
  final bool canDelete;
  final bool isDeleting;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PostHistoryCard({
    required this.post,
    required this.canEdit,
    required this.canDelete,
    required this.isDeleting,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            isDesktop ? 22 : 16,
            isDesktop ? 20 : 14,
            isDesktop ? 22 : 16,
            isDesktop ? 20 : 16,
          ),
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
                      style: TextStyle(
                        color: const Color(0xFF071426),
                        fontSize: isDesktop ? 24 : 21,
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
                post.createdByName.isEmpty
                    ? 'Unknown creator'
                    : post.createdByName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF252C36),
                  fontSize: isDesktop ? 15 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isDesktop ? 18 : 14),
              _MetaLine(
                icon: Icons.business_rounded,
                text: post.clientName.isEmpty
                    ? 'Unknown client'
                    : post.clientName,
              ),
              const SizedBox(height: 9),
              _MetaLine(
                icon: Icons.calendar_month_rounded,
                text: _formatPostDate(post.scheduledFor ?? post.createdAt),
              ),
              SizedBox(height: isDesktop ? 16 : 13),
              Divider(color: const Color(0xFFCCD2DA), height: 1),
              SizedBox(height: isDesktop ? 16 : 14),
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
                        size: 27,
                      ),
                    ),
                  if (canDelete)
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
                              size: 28,
                            ),
                    ),
                ],
              ),
            ],
          ),
        ),
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
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Row(
      children: [
        Icon(icon, size: isDesktop ? 21 : 17, color: const Color(0xFF5E6673)),
        SizedBox(width: isDesktop ? 10 : 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF202833),
              fontSize: isDesktop ? 16 : 14,
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
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final normalized = status.toLowerCase();
    final isGood = normalized == 'published' || normalized == 'approved';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 14 : 12,
        vertical: isDesktop ? 7 : 6,
      ),
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
          fontSize: isDesktop ? 13 : 12,
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
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final normalized = platform.toLowerCase();
    final color = normalized.contains('instagram')
        ? const Color(0xFFD5298D)
        : normalized.contains('facebook')
        ? const Color(0xFF1877F2)
        : const Color(0xFF7C3AED);
    return Tooltip(
      message: '${platform.isEmpty ? 'Target' : platform}: $status',
      child: Container(
        width: isDesktop ? 42 : 34,
        height: isDesktop ? 42 : 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Appcolors.kwhitecolor,
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Appcolors.kblackcolor.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: SocialPlatformIcon(
            platform: platform,
            size: isDesktop ? 25 : 21,
            fallbackColor: color,
          ),
        ),
      ),
    );
  }
}

class _PostDetailsPanel extends StatefulWidget {
  final PostListItem post;
  final VoidCallback onClose;
  final bool showScrollIndicator;

  const _PostDetailsPanel({
    required this.post,
    required this.onClose,
    this.showScrollIndicator = false,
  });

  @override
  State<_PostDetailsPanel> createState() => _PostDetailsPanelState();
}

class _PostDetailsPanelState extends State<_PostDetailsPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(isDesktop ? 22 : 24),
      child: Container(
        color: Appcolors.kwhitecolor,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 32 : 18,
                isDesktop ? 28 : 12,
                isDesktop ? 24 : 12,
                isDesktop ? 24 : 12,
              ),
              child: Column(
                children: [
                  if (!isDesktop) ...[
                    Container(
                      height: 4,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E5EC),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF071426),
                                fontSize: isDesktop ? 34 : 22,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _StatusPill(status: widget.post.displayStatus),
                                _PostDetailChip(
                                  icon: Icons.business_rounded,
                                  label: widget.post.clientName.isEmpty
                                      ? 'Unknown client'
                                      : widget.post.clientName,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: widget.onClose,
                        tooltip: 'Close details',
                        icon: Icon(
                          Icons.close_rounded,
                          size: isDesktop ? 30 : 24,
                        ),
                        color: const Color(0xFF5E6673),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: const Color(0xFFE3E8EF)),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: widget.showScrollIndicator,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(isDesktop ? 32 : 18),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _PostDetailsMedia(post: widget.post),
                            ),
                            const SizedBox(width: 30),
                            Expanded(
                              flex: 6,
                              child: _PostDetailsContent(post: widget.post),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _PostDetailsMedia(post: widget.post),
                            const SizedBox(height: 20),
                            _PostDetailsContent(post: widget.post),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostDetailsContent extends StatelessWidget {
  final PostListItem post;

  const _PostDetailsContent({required this.post});

  Future<void> _copyCaption(BuildContext context) async {
    final caption = post.caption.trim();
    if (caption.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: caption));
    if (!context.mounted) return;

    CustomSnackbar.show(
      context,
      message: 'Caption copied',
      type: SnackbarType.success,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final caption = post.caption.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PostDetailsSection(
          title: 'Caption',
          trailing: _CaptionCopyButton(
            enabled: caption.isNotEmpty,
            onPressed: () => _copyCaption(context),
          ),
          child: Text(
            caption.isEmpty ? 'No caption added' : post.caption,
            style: TextStyle(
              color: caption.isEmpty
                  ? const Color(0xFF929AA7)
                  : const Color(0xFF202833),
              fontSize: isDesktop ? 17 : 14.5,
              fontWeight: FontWeight.w600,
              height: 1.48,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _PostDetailsSection(
          title: 'Post Information',
          child: _PostDetailsInfoGrid(
            items: [
              _PostDetailInfoItem(
                icon: Icons.badge_rounded,
                label: 'Created by',
                value: post.createdByName.isEmpty
                    ? 'Unknown creator'
                    : post.createdByName,
              ),
              _PostDetailInfoItem(
                icon: Icons.check_circle_rounded,
                label: 'Approved by',
                value: post.approvedByName.isEmpty
                    ? 'Not approved yet'
                    : post.approvedByName,
              ),
              _PostDetailInfoItem(
                icon: Icons.category_rounded,
                label: 'Content type',
                value: post.contentType.isEmpty ? 'Post' : post.contentType,
              ),
              _PostDetailInfoItem(
                icon: Icons.perm_media_rounded,
                label: 'Media',
                value: _mediaSummary(post),
              ),
              _PostDetailInfoItem(
                icon: Icons.schedule_rounded,
                label: 'Scheduled',
                value: _formatPostDetailDate(post.scheduledFor),
              ),
              _PostDetailInfoItem(
                icon: Icons.publish_rounded,
                label: 'Published',
                value: _formatPostDetailDate(post.publishedAt),
              ),
              _PostDetailInfoItem(
                icon: Icons.event_rounded,
                label: 'Created',
                value: _formatPostDetailDate(post.createdAt),
              ),
              _PostDetailInfoItem(
                icon: Icons.numbers_rounded,
                label: 'Post ID',
                value: post.id == 0 ? 'Unavailable' : '#${post.id}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _PostDetailsSection(
          title: 'Targets',
          child: post.targets.isEmpty
              ? const Text(
                  'No targets available',
                  style: TextStyle(
                    color: Color(0xFF929AA7),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  children: post.targets
                      .map(
                        (target) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _PostTargetDetailTile(target: target),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  String _mediaSummary(PostListItem post) {
    final mediaKind = post.mediaKind.trim();
    final mediaSource = post.mediaSource.trim();
    final count = post.mediaItems.isNotEmpty ? post.mediaItems.length : 0;
    final parts = [
      if (mediaKind.isNotEmpty) mediaKind,
      if (mediaSource.isNotEmpty) mediaSource,
      if (count > 0) '$count item${count == 1 ? '' : 's'}',
    ];
    return parts.isEmpty ? 'No media' : parts.join(' • ');
  }
}

class _PostDetailsMedia extends StatelessWidget {
  final PostListItem post;

  const _PostDetailsMedia({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final media = _detailMediaItems(post);
    final height = isDesktop ? 420.0 : 240.0;

    return _PostDetailsSection(
      title: 'Media Preview',
      child: media.isEmpty
          ? Container(
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3E8EF)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported_rounded,
                    color: Color(0xFF929AA7),
                    size: isDesktop ? 52 : 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No media preview available',
                    style: TextStyle(
                      color: Color(0xFF929AA7),
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          : SizedBox(
              height: height,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: media.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: media.length == 1
                        ? (isDesktop
                              ? 520
                              : MediaQuery.sizeOf(context).width - 72)
                        : (isDesktop ? 380 : 250),
                    child: _PostDetailMediaCard(item: media[index]),
                  );
                },
              ),
            ),
    );
  }

  List<_PostDetailMediaItem> _detailMediaItems(PostListItem post) {
    if (post.mediaItems.isNotEmpty) {
      return post.mediaItems
          .map(
            (item) => _PostDetailMediaItem(
              name: item.driveFileName.isEmpty
                  ? item.mediaUrl.split('/').last
                  : item.driveFileName,
              mediaKind: item.mediaKind,
              mediaSource: item.mediaSource,
              mediaUrl: item.mediaUrl,
              driveFileUrl: item.driveFileUrl,
            ),
          )
          .toList();
    }

    if (post.mediaUrl.trim().isEmpty) return const [];
    return [
      _PostDetailMediaItem(
        name: post.mediaUrl.trim().split('/').last,
        mediaKind: post.mediaKind,
        mediaSource: post.mediaSource,
        mediaUrl: post.mediaUrl,
        driveFileUrl: '',
      ),
    ];
  }
}

class _PostDetailMediaCard extends StatelessWidget {
  final _PostDetailMediaItem item;

  const _PostDetailMediaCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final source = item.previewUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF17124B)),
            child: source.isEmpty
                ? const _PostDetailMediaFallback()
                : item.isVideo
                ? VideoThumbnailPreview(
                    source: source,
                    fallback: const _PostDetailMediaFallback(),
                    playBadgeSize: isDesktop ? 70 : 58,
                  )
                : item.isImage
                ? Image.network(
                    source,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                    errorBuilder: (_, _, _) => const _PostDetailMediaFallback(),
                  )
                : const _PostDetailMediaFallback(),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 14 : 12,
                vertical: isDesktop ? 12 : 10,
              ),
              decoration: BoxDecoration(
                color: Appcolors.kblackcolor.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.name.isEmpty ? 'Media item' : item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Appcolors.kwhitecolor,
                  fontSize: isDesktop ? 14 : 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostDetailMediaFallback extends StatelessWidget {
  const _PostDetailMediaFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.perm_media_rounded,
        color: Appcolors.kwhitecolor,
        size: 46,
      ),
    );
  }
}

class _PostDetailMediaItem {
  final String name;
  final String mediaKind;
  final String mediaSource;
  final String mediaUrl;
  final String driveFileUrl;

  const _PostDetailMediaItem({
    required this.name,
    required this.mediaKind,
    required this.mediaSource,
    required this.mediaUrl,
    required this.driveFileUrl,
  });

  bool get isVideo {
    final kind = mediaKind.toLowerCase();
    if (kind == 'video') return true;
    final lowerName = name.toLowerCase();
    final lowerUrl = mediaUrl.toLowerCase();
    return lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.m4v') ||
        lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.m4v');
  }

  bool get isImage {
    final kind = mediaKind.toLowerCase();
    if (kind == 'image') return true;
    final lowerName = name.toLowerCase();
    final lowerUrl = mediaUrl.toLowerCase();
    return lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.heic') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp') ||
        lowerUrl.endsWith('.heic');
  }

  String get previewUrl {
    final source = mediaUrl.trim().isNotEmpty
        ? mediaUrl.trim()
        : driveFileUrl.trim();
    if (source.isEmpty) return '';
    final parsedUrl = Uri.tryParse(source);
    if (parsedUrl != null && parsedUrl.hasScheme) return source;

    final normalizedUrl = source.startsWith('/') ? source.substring(1) : source;
    return Uri.parse(Endpoints.mediaBaseUrl).resolve(normalizedUrl).toString();
  }
}

class _CaptionCopyButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _CaptionCopyButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return TextButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(Icons.copy_rounded, size: isDesktop ? 18 : 16),
      label: const Text('Copy'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFB33620),
        disabledForegroundColor: const Color(0xFFB8C0CC),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 12 : 10,
          vertical: isDesktop ? 8 : 6,
        ),
        minimumSize: Size(isDesktop ? 80 : 72, isDesktop ? 38 : 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(
          fontSize: isDesktop ? 14 : 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PostDetailsSection extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _PostDetailsSection({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 20 : 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF071426),
                    fontSize: isDesktop ? 18 : 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          child,
        ],
      ),
    );
  }
}

class _PostDetailsInfoGrid extends StatelessWidget {
  final List<_PostDetailInfoItem> items;

  const _PostDetailsInfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = isDesktop && constraints.maxWidth > 560 ? 2 : 1;
        final gap = isDesktop ? 12.0 : 10.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: items
              .map(
                (item) => SizedBox(
                  width: width,
                  child: _PostDetailInfoTile(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _PostDetailInfoTile extends StatelessWidget {
  final _PostDetailInfoItem item;

  const _PostDetailInfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 15 : 12),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: isDesktop ? 22 : 18,
            color: const Color(0xFFB33620),
          ),
          SizedBox(width: isDesktop ? 12 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: const Color(0xFF929AA7),
                    fontSize: isDesktop ? 12 : 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: isDesktop ? 5 : 4),
                Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF202833),
                    fontSize: isDesktop ? 15 : 13,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostDetailInfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _PostDetailInfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class _PostTargetDetailTile extends StatelessWidget {
  final PostTarget target;

  const _PostTargetDetailTile({required this.target});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final platform = target.platform.isEmpty ? 'Target' : target.platform;
    final profile = target.profileName.isEmpty
        ? 'No profile name'
        : target.profileName;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 12),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Row(
        children: [
          SocialPlatformIcon(
            platform: target.platform,
            size: isDesktop ? 36 : 28,
            fallbackColor: const Color(0xFF7C3AED),
          ),
          SizedBox(width: isDesktop ? 14 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF071426),
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: isDesktop ? 5 : 4),
                Text(
                  profile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF5E6673),
                    fontSize: isDesktop ? 14 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (target.errorMessage.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    target.errorMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFC93119),
                      fontSize: isDesktop ? 13 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatusPill(
            status: target.status.isEmpty ? 'unknown' : target.status,
          ),
        ],
      ),
    );
  }
}

class _PostDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PostDetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 13 : 10,
        vertical: isDesktop ? 8 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF5E6673), size: isDesktop ? 18 : 15),
          SizedBox(width: isDesktop ? 8 : 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 430 : 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF202833),
                fontSize: isDesktop ? 14 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPostDetailDate(DateTime? value) {
  if (value == null) return 'Not available';
  final local = value.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final period = local.hour >= 12 ? 'pm' : 'am';
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day}/${local.month}/${local.year}, $hour12:$minute $period';
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
