import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/constants.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/features/dashboard/blocs/dashboard_bloc/dashboard_bloc.dart';
import 'package:crisant_connect/features/dashboard/models/dashboard_response.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/crisant_app_bar.dart';
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
                padding: EdgeInsets.fromLTRB(
                  ResponsiveUtils.wp(4.6),
                  ResponsiveUtils.hp(2),
                  ResponsiveUtils.wp(4.6),
                  ResponsiveUtils.hp(15),
                ),
                sliver: SliverToBoxAdapter(
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
    final titleSize = ResponsiveUtils.sp(5).clamp(18, 21).toDouble();
    final subtitleSize = ResponsiveUtils.sp(4).clamp(15, 19).toDouble();

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
        SizedBox(height: ResponsiveUtils.hp(3)),
        _StatsGrid(stats: dashboard.stats),
        SizedBox(height: ResponsiveUtils.hp(3)),
        _PostingOverviewCard(items: dashboard.monthlyPostingOverview),
        SizedBox(height: ResponsiveUtils.hp(3)),
        _PostingGapMonitor(gaps: dashboard.postingGapMonitor),
        SizedBox(height: ResponsiveUtils.hp(3)),
        const _RecentPostsHeader(),
        SizedBox(height: ResponsiveUtils.hp(1.8)),
        _RecentPostsList(posts: dashboard.recentPosts),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final spacing = ResponsiveUtils.wp(4).clamp(12, 18).toDouble();
    final cardWidth = (width - ResponsiveUtils.wp(9.2) - spacing) / 2;
    final cardHeight = cardWidth < 165 ? 205.0 : cardWidth * 1.04;
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
        highlighted: true,
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
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color iconBackground;
  final bool highlighted;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.iconBackground,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = ResponsiveUtils.wp(5).clamp(16, 24).toDouble();
    final iconSize = ResponsiveUtils.wp(12).clamp(42, 48).toDouble();
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
      child: Stack(
        children: [
          if (highlighted)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF087D80),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
            ),
          Padding(
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
                    fontSize: ResponsiveUtils.sp(
                      compact ? 4 : 4.2,
                    ).clamp(14, 18),
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
                    fontSize: ResponsiveUtils.sp(5.2).clamp(17, 21),
                    fontWeight: FontWeight.w900,
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

class _PostingOverviewCard extends StatefulWidget {
  final List<MonthlyPostingOverviewItem> items;

  const _PostingOverviewCard({required this.items});

  @override
  State<_PostingOverviewCard> createState() => _PostingOverviewCardState();
}

class _PostingOverviewCardState extends State<_PostingOverviewCard> {
  final ScrollController _scrollController = ScrollController();
  bool _didScrollToRecentDays = false;

  @override
  void didUpdateWidget(covariant _PostingOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
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
    if (_didScrollToRecentDays || widget.items.length <= 7) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      _didScrollToRecentDays = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    _scrollToRecentDays();

    return _DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Posting Overview',
            style: TextStyle(
              color: const Color(0xFF0C1116),
              fontSize: ResponsiveUtils.sp(5).clamp(17, 20),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: ResponsiveUtils.hp(1.6).clamp(10, 16).toDouble()),
          if (widget.items.isEmpty)
            const _EmptyPanelMessage(message: 'No posting activity this month')
          else
            SizedBox(
              height: ResponsiveUtils.hp(28).clamp(205, 245),
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final item in widget.items) ...[
                      SizedBox(
                        width: 44,
                        child: _DayBar(
                          item: item,
                          maxTotal: _maxPostingTotal(widget.items),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _maxPostingTotal(List<MonthlyPostingOverviewItem> values) {
    var max = 0;
    for (final value in values) {
      if (value.total > max) max = value.total;
    }
    return max == 0 ? 1 : max;
  }
}

class _DayBar extends StatelessWidget {
  final MonthlyPostingOverviewItem item;
  final int maxTotal;

  const _DayBar({required this.item, required this.maxTotal});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const labelHeight = 18.0;
        const labelGap = 10.0;
        const valueHeight = 24.0;
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
                  style: const TextStyle(
                    color: Color(0xFF5E6673),
                    fontSize: 11,
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
            const SizedBox(height: labelGap),
            SizedBox(
              height: labelHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: Color(0xFF202329),
                    fontSize: 11,
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
              fontSize: ResponsiveUtils.sp(5).clamp(17, 20),
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
    final toneColor = _toneColor(gap.severity.tone);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: toneColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.schedule_rounded, color: toneColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gap.clientName.isEmpty ? 'Unknown client' : gap.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 14,
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
                  style: const TextStyle(
                    color: Color(0xFF6E625E),
                    fontSize: 12,
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
        fontSize: ResponsiveUtils.sp(5.2).clamp(18, 21),
        fontWeight: FontWeight.w800,
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
      return const _DashboardPanel(
        child: _EmptyPanelMessage(message: 'No recent posts found'),
      );
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
    final thumbSize = ResponsiveUtils.wp(13).clamp(46, 58).toDouble();
    final compact = MediaQuery.sizeOf(context).width < 360;
    final platformColor = _platformColor(post.platform);

    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.wp(4).clamp(14, 18).toDouble()),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.96),
        borderRadius: BorderRadiusStyles.kradius15(),
      ),
      child: Row(
        children: [
          Container(
            height: thumbSize,
            width: thumbSize,
            decoration: BoxDecoration(
              color: platformColor,
              borderRadius: BorderRadiusStyles.kradius10(),
            ),
            child: Icon(
              _platformIcon(post.platform),
              color: Appcolors.kwhitecolor,
              size: thumbSize * 0.52,
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
                    fontSize: ResponsiveUtils.sp(4.4).clamp(15, 18),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: ResponsiveUtils.hp(0.4)),
                Text(
                  _recentPostMeta(post),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF6E625E),
                    fontSize: ResponsiveUtils.sp(4.2).clamp(14, 18),
                    fontWeight: FontWeight.w400,
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

  IconData _platformIcon(String platform) {
    final normalized = platform.toLowerCase();
    if (normalized.contains('facebook')) return Icons.facebook_rounded;
    if (normalized.contains('instagram')) return Icons.camera_alt_rounded;
    return Icons.public_rounded;
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final displayLabel = label.trim().isEmpty ? 'unknown' : label.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
          fontSize: 11,
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
        ResponsiveUtils.wp(5.2),
        ResponsiveUtils.hp(2.4),
        ResponsiveUtils.wp(4.2),
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
