import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/constants.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/features/dashboard/blocs/dashboard_bloc/dashboard_bloc.dart';
import 'package:crisant_connect/features/dashboard/models/dashboard_response.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/crisant_app_bar.dart';
import 'package:crisant_connect/widgets/social_platform_icon.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScreenDashboard extends StatefulWidget {
  const ScreenDashboard({super.key});

  @override
  State<ScreenDashboard> createState() => _ScreenDashboardState();
}

class _ScreenDashboardState extends State<ScreenDashboard> {
  late final String _month = _currentMonthKey();

  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(FetchDashboardRequested(month: _month));
  }

  static String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void _fetchDashboard() {
    context.read<DashboardBloc>().add(FetchDashboardRequested(month: _month));
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return AppBackground(
      opacity: 0.35,
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: Appcolors.kprimarycolor,
          onRefresh: () async => _fetchDashboard(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: CrisantAppBar()),
              SliverPadding(
                padding: ResponsiveUtils.pagePadding(
                  context,
                  top: ResponsiveUtils.hp(2),
                  bottom: ResponsiveUtils.bottomScrollPadding(context),
                ),
                sliver: SliverToBoxAdapter(
                  child: ResponsiveUtils.constrainWidth(
                    context: context,
                    child: BlocBuilder<DashboardBloc, DashboardState>(
                      builder: (context, state) {
                        if (state is DashboardLoading ||
                            state is DashboardInitial) {
                          return const _DashboardLoading();
                        }

                        if (state is DashboardFailure) {
                          return _DashboardError(
                            message: state.message,
                            onRetry: _fetchDashboard,
                          );
                        }

                        final dashboard = state is DashboardSuccess
                            ? state.dashboard
                            : null;
                        if (dashboard == null) {
                          return _DashboardError(
                            message: 'Dashboard data unavailable',
                            onRetry: _fetchDashboard,
                          );
                        }

                        return _DashboardBody(dashboard: dashboard);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardResponse dashboard;

  const _DashboardBody({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final titleSize = isDesktop
        ? 32.0
        : ResponsiveUtils.sp(5).clamp(18, 21).toDouble();
    final subtitleSize = isDesktop
        ? 16.0
        : ResponsiveUtils.sp(4).clamp(15, 19).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(0.8)),
        Text(
          "Here's what's happening with your content this month.",
          style: TextStyle(
            color: const Color(0xFF7A6C66),
            fontSize: subtitleSize,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
        SizedBox(height: isDesktop ? 28 : ResponsiveUtils.hp(3)),
        _StatsGrid(stats: dashboard.stats),
        SizedBox(height: isDesktop ? 28 : ResponsiveUtils.hp(3)),
        _PostingOverviewCard(
          items: dashboard.monthlyPostingOverview,
          month: dashboard.month,
        ),
        SizedBox(height: isDesktop ? 28 : ResponsiveUtils.hp(3)),
        if (ResponsiveUtils.isDesktop(context))
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PostingGapMonitor(gaps: dashboard.postingGapMonitor),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: _RecentPostsSection(posts: dashboard.recentPosts),
                ),
              ],
            ),
          )
        else ...[
          _PostingGapMonitor(gaps: dashboard.postingGapMonitor),
          SizedBox(height: ResponsiveUtils.hp(3)),
          _RecentPostsSection(posts: dashboard.recentPosts),
        ],
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final spacing = isDesktop
        ? 20.0
        : ResponsiveUtils.wp(4).clamp(12, 18).toDouble();
    final cards = [
      _StatCard(
        icon: Icons.groups_rounded,
        title: 'Number Of\nClients',
        value: stats.clients.toString(),
        iconColor: const Color(0xFFA63D08),
        iconBackground: const Color(0xFFFFF2E8),
      ),
      _StatCard(
        icon: Icons.account_circle_rounded,
        title: 'Connected\nProfiles',
        value: stats.connectedProfiles.toString(),
        iconColor: const Color(0xFF087D80),
        iconBackground: const Color(0xFFE3F7F6),
      ),
      _StatCard(
        icon: Icons.send_time_extension_rounded,
        title: 'Queued Posts',
        value: stats.queuedPosts.toString(),
        iconColor: const Color(0xFF58677B),
        iconBackground: const Color(0xFFF0F4F8),
      ),
      _StatCard(
        icon: Icons.pending_actions_rounded,
        title: 'Pending\nApprovals',
        value: stats.pendingApprovals.toString(),
        iconColor: const Color(0xFF58677B),
        iconBackground: const Color(0xFFF0F4F8),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ResponsiveUtils.gridColumns(
          constraints.maxWidth,
          tablet: constraints.maxWidth > 760 ? 4 : 2,
          desktop: 4,
        );
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final cardHeight = ResponsiveUtils.isMobile(context)
            ? (cardWidth < 165 ? 205.0 : cardWidth * 1.04)
            : isDesktop
            ? cardWidth.clamp(182.0, 216.0).toDouble()
            : cardWidth.clamp(150.0, 178.0).toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: ResponsiveUtils.hp(2.1).clamp(14, 20).toDouble(),
          children: cards
              .map(
                (card) =>
                    SizedBox(width: cardWidth, height: cardHeight, child: card),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final cardPadding = isDesktop
        ? 24.0
        : ResponsiveUtils.wp(5).clamp(16, 24).toDouble();
    final iconSize = isDesktop
        ? 54.0
        : ResponsiveUtils.wp(12).clamp(42, 48).toDouble();
    final compact = MediaQuery.sizeOf(context).width < 360;

    return Container(
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
        borderRadius: BorderRadiusStyles.kradius15(),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          cardPadding,
          cardPadding,
          cardPadding * 0.8,
          cardPadding * 0.82,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: iconSize,
              width: iconSize,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadiusStyles.kradius10(),
              ),
              child: Icon(icon, color: iconColor, size: iconSize * 0.52),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF33211D),
                fontSize: isDesktop
                    ? 16.0
                    : ResponsiveUtils.sp(compact ? 4 : 4.2).clamp(14, 18),
                fontWeight: FontWeight.w500,
                height: 1.22,
              ),
            ),
            SizedBox(height: compact ? 3 : 5),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF0C1116),
                fontSize: isDesktop
                    ? 26.0
                    : ResponsiveUtils.sp(5.2).clamp(17, 21),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostingOverviewCard extends StatefulWidget {
  final List<MonthlyPostingOverviewItem> items;
  final DashboardMonth month;

  const _PostingOverviewCard({required this.items, required this.month});

  @override
  State<_PostingOverviewCard> createState() => _PostingOverviewCardState();
}

class _PostingOverviewCardState extends State<_PostingOverviewCard> {
  final ScrollController _scrollController = ScrollController();
  bool _didScrollToRecentDays = false;

  @override
  void didUpdateWidget(covariant _PostingOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.month.key != widget.month.key) {
      _didScrollToRecentDays = false;
      _scrollToRecentDays();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToRecentDays() {
    final visibleItems = _visibleChartItems();
    if (_didScrollToRecentDays || visibleItems.length <= 7) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _didScrollToRecentDays = true;
    });
  }

  void _handleChartPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_scrollController.hasClients) return;

    final delta = event.scrollDelta.dx.abs() > event.scrollDelta.dy.abs()
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    if (delta == 0) return;

    final position = _scrollController.position;
    final nextOffset = (_scrollController.offset + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.jumpTo(nextOffset);
  }

  @override
  Widget build(BuildContext context) {
    _scrollToRecentDays();
    final visibleItems = _visibleChartItems();

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Posting Overview',
            style: TextStyle(
              color: const Color(0xFF0C1116),
              fontSize: ResponsiveUtils.isDesktop(context)
                  ? 24
                  : ResponsiveUtils.sp(5).clamp(17, 20),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(1.6).clamp(10, 16).toDouble()),
          if (visibleItems.isEmpty)
            const _EmptyPanelMessage(message: 'No posting activity this month')
          else
            SizedBox(
              height: ResponsiveUtils.isDesktop(context)
                  ? 320
                  : ResponsiveUtils.hp(28).clamp(205, 245).toDouble(),
              child: Listener(
                onPointerSignal: _handleChartPointerSignal,
                child: ScrollConfiguration(
                  behavior: const _HorizontalChartScrollBehavior(),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: ResponsiveUtils.isDesktop(context),
                    trackVisibility: ResponsiveUtils.isDesktop(context),
                    notificationPredicate: (notification) =>
                        notification.depth == 0,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveUtils.isDesktop(context) ? 22 : 0,
                          right: ResponsiveUtils.isDesktop(context) ? 8 : 0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in visibleItems) ...[
                              SizedBox(
                                width: ResponsiveUtils.isDesktop(context)
                                    ? 56
                                    : 44,
                                child: _DayBar(
                                  item: item,
                                  maxTotal: _maxPostingTotal(visibleItems),
                                ),
                              ),
                              SizedBox(
                                width: ResponsiveUtils.isDesktop(context)
                                    ? 10
                                    : 8,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<MonthlyPostingOverviewItem> _visibleChartItems() {
    final items = List<MonthlyPostingOverviewItem>.from(widget.items)
      ..sort((a, b) => _chartDate(a).compareTo(_chartDate(b)));
    final now = DateTime.now();
    final currentMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    if (widget.month.key != currentMonthKey) return items;

    final today = DateTime(now.year, now.month, now.day);
    return items.where((item) {
      final itemDate = _dateOnly(_chartDate(item));
      return !itemDate.isAfter(today);
    }).toList();
  }

  DateTime _chartDate(MonthlyPostingOverviewItem item) {
    if (item.date != null) return item.date!.toLocal();

    final monthParts = widget.month.key.split('-');
    final now = DateTime.now();
    final year = monthParts.isNotEmpty
        ? int.tryParse(monthParts.first) ?? now.year
        : now.year;
    final month = monthParts.length > 1
        ? int.tryParse(monthParts[1]) ?? now.month
        : now.month;
    final day = item.day > 0 ? item.day : 1;
    return DateTime(year, month, day);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  int _maxPostingTotal(List<MonthlyPostingOverviewItem> values) {
    var max = 0;
    for (final value in values) {
      if (value.total > max) max = value.total;
    }
    return max == 0 ? 1 : max;
  }
}

class _HorizontalChartScrollBehavior extends MaterialScrollBehavior {
  const _HorizontalChartScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };
}

class _DayBar extends StatelessWidget {
  final MonthlyPostingOverviewItem item;
  final int maxTotal;

  const _DayBar({required this.item, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final labelHeight = isDesktop ? 22.0 : 18.0;
        final labelGap = isDesktop ? 12.0 : 10.0;
        final valueHeight = isDesktop ? 28.0 : 24.0;
        const valueGap = 8.0;
        final maxBarHeight =
            constraints.maxHeight -
            labelHeight -
            labelGap -
            valueHeight -
            valueGap;
        final barHeight = item.total <= 0
            ? 8.0
            : (item.total / maxTotal * maxBarHeight).clamp(18.0, maxBarHeight);

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: valueHeight,
              child: Center(
                child: Text(
                  item.total.toString(),
                  style: TextStyle(
                    color: const Color(0xFF5E6673),
                    fontSize: isDesktop ? 13 : 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            SizedBox(height: valueGap),
            Tooltip(
              message: 'Instagram ${item.instagram}, Facebook ${item.facebook}',
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: item.total > 0
                      ? const Color(0xFFA84A0D)
                      : const Color(0xFFE9EEF2),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),
            SizedBox(height: labelGap),
            SizedBox(
              height: labelHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: const Color(0xFF202329),
                    fontSize: isDesktop ? 13 : 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PostingGapMonitor extends StatelessWidget {
  final List<PostingGapItem> gaps;

  const _PostingGapMonitor({required this.gaps});

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Posting Gap Monitor',
            style: TextStyle(
              color: const Color(0xFF0C1116),
              fontSize: ResponsiveUtils.isDesktop(context)
                  ? 24
                  : ResponsiveUtils.sp(5).clamp(17, 20),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(1.6).clamp(10, 16).toDouble()),
          if (gaps.isEmpty)
            const _EmptyPanelMessage(message: 'No posting gaps found')
          else
            Column(
              children: gaps.take(4).map((gap) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PostingGapTile(gap: gap),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PostingGapTile extends StatelessWidget {
  final PostingGapItem gap;

  const _PostingGapTile({required this.gap});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final toneColor = _toneColor(gap.severity.tone);
    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          Container(
            height: isDesktop ? 52 : 42,
            width: isDesktop ? 52 : 42,
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: toneColor,
              size: isDesktop ? 28 : 22,
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gap.clientName.isEmpty ? 'Unknown client' : gap.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gap.severity.detail.isNotEmpty
                      ? gap.severity.detail
                      : '${gap.gapDays} day gap',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF6E625E),
                    fontSize: isDesktop ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(
            label: gap.severity.label.isEmpty
                ? gap.severity.tone
                : gap.severity.label,
            color: toneColor,
          ),
        ],
      ),
    );
  }

  Color _toneColor(String tone) {
    switch (tone.toLowerCase()) {
      case 'healthy':
        return const Color(0xFF127A36);
      case 'warning':
        return const Color(0xFFC47A08);
      case 'critical':
        return const Color(0xFFD30000);
      default:
        return const Color(0xFF58677B);
    }
  }
}

class _RecentPostsHeader extends StatelessWidget {
  const _RecentPostsHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Recent Posts',
      style: TextStyle(
        color: const Color(0xFF0C1116),
        fontSize: ResponsiveUtils.isDesktop(context)
            ? 24
            : ResponsiveUtils.sp(5.2).clamp(18, 21),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _RecentPostsSection extends StatelessWidget {
  final List<DashboardRecentPost> posts;

  const _RecentPostsSection({required this.posts});

  @override
  Widget build(BuildContext context) {
    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RecentPostsHeader(),
          SizedBox(height: ResponsiveUtils.hp(1.6).clamp(10, 16).toDouble()),
          _RecentPostsList(posts: posts),
        ],
      ),
    );
  }
}

class _RecentPostsList extends StatelessWidget {
  final List<DashboardRecentPost> posts;

  const _RecentPostsList({required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyPanelMessage(message: 'No recent posts found');
    }

    return Column(
      children: posts
          .take(5)
          .map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _RecentPostTile(post: post),
            ),
          )
          .toList(),
    );
  }
}

class _RecentPostTile extends StatelessWidget {
  final DashboardRecentPost post;

  const _RecentPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final thumbSize = ResponsiveUtils.isMobile(context)
        ? ResponsiveUtils.wp(13).clamp(46, 58).toDouble()
        : isDesktop
        ? 60.0
        : 52.0;
    final compact = MediaQuery.sizeOf(context).width < 360;
    final platformColor = _platformColor(post.platform);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          Container(
            height: isDesktop ? 52 : 42,
            width: isDesktop ? 52 : 42,
            decoration: BoxDecoration(
              color: platformColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SocialPlatformIcon(
                platform: post.platform,
                size: thumbSize * 0.48,
                fallbackColor: platformColor,
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.wp(3.4).clamp(10, 18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title.isEmpty ? 'Untitled post' : post.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF1A2028),
                    fontSize: isDesktop
                        ? 16
                        : ResponsiveUtils.sp(4.2).clamp(14, 16),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _recentPostMeta(post),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF6E625E),
                    fontSize: isDesktop ? 14 : 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          _StatusPill(label: post.status, color: const Color(0xFF087D80)),
        ],
      ),
    );
  }

  String _recentPostMeta(DashboardRecentPost post) {
    final client = post.clientName.isEmpty ? 'Unknown client' : post.clientName;
    final date = _formatPostDate(post.scheduledFor);
    return '$client - $date';
  }

  String _formatPostDate(DateTime? value) {
    if (value == null) return 'No date';
    final local = value.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '${local.day}/${local.month}/${local.year}, $hour:$minute $period';
  }

  Color _platformColor(String platform) {
    final normalized = platform.toLowerCase();
    if (normalized.contains('instagram')) return const Color(0xFFD5298D);
    if (normalized.contains('facebook')) return const Color(0xFF1877F2);
    return const Color(0xFF3F5D62);
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final displayLabel = label.trim().isEmpty ? 'unknown' : label.trim();
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 12 : 10,
        vertical: isDesktop ? 8 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        displayLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: isDesktop ? 12.5 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  final Widget child;

  const _DashboardPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.wp(5.2).clamp(18, 26).toDouble(),
        ResponsiveUtils.hp(2.4),
        ResponsiveUtils.wp(4.2).clamp(16, 24).toDouble(),
        ResponsiveUtils.hp(2.5),
      ),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
        borderRadius: BorderRadiusStyles.kradius15(),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyPanelMessage extends StatelessWidget {
  final String message;

  const _EmptyPanelMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF5E6673),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.55,
      child: const Center(
        child: CircularProgressIndicator(color: Appcolors.kprimarycolor),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.55,
      child: Center(
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
      ),
    );
  }
}
