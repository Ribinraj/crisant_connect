import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/constants.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/crisant_app_bar.dart';
import 'package:flutter/material.dart';

class ScreenDashboard extends StatelessWidget {
  const ScreenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return AppBackground(
      opacity: 0.35,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: CrisantAppBar()),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                ResponsiveUtils.wp(4.6),
                ResponsiveUtils.hp(2),
                ResponsiveUtils.wp(4.6),
                ResponsiveUtils.hp(15),
              ),
              sliver: const SliverToBoxAdapter(child: _DashboardBody()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveUtils.sp(5).clamp(18, 21).toDouble();
    final subtitleSize = ResponsiveUtils.sp(4).clamp(15, 19).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good Afternoon Ribin!',
          style: TextStyle(
            color: const Color(0xFF111827),
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(0.8)),
        Text(
          "Here's what's happening with your content today.",
          style: TextStyle(
            color: const Color(0xFF7A6C66),
            fontSize: subtitleSize,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
        SizedBox(height: ResponsiveUtils.hp(3)),
        const _StatsGrid(),
        SizedBox(height: ResponsiveUtils.hp(3)),
        const _PostingOverviewCard(),
        SizedBox(height: ResponsiveUtils.hp(3)),
        const _RecentPostsHeader(),
        SizedBox(height: ResponsiveUtils.hp(1.8)),
        const _RecentPostsList(),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final spacing = ResponsiveUtils.wp(4).clamp(12, 18).toDouble();
    final cardWidth = (width - ResponsiveUtils.wp(9.2) - spacing) / 2;
    final cardHeight = cardWidth < 165 ? 205.0 : cardWidth * 1.04;

    return Wrap(
      spacing: spacing,
      runSpacing: ResponsiveUtils.hp(2.1).clamp(14, 20).toDouble(),
      children:
          const [
                _StatCard(
                  icon: Icons.groups_rounded,
                  title: 'Number Of\nClients',
                  value: '36',
                  iconColor: Color(0xFFA63D08),
                  iconBackground: Color(0xFFFFF2E8),
                ),
                _StatCard(
                  icon: Icons.account_circle_rounded,
                  title: 'Connected\nProfiles',
                  value: '80',
                  iconColor: Color(0xFF087D80),
                  iconBackground: Color(0xFFE3F7F6),
                  highlighted: true,
                ),
                _StatCard(
                  icon: Icons.send_time_extension_rounded,
                  title: 'Queued Posts',
                  value: '0',
                  iconColor: Color(0xFF58677B),
                  iconBackground: Color(0xFFF0F4F8),
                ),
                _StatCard(
                  icon: Icons.pending_actions_rounded,
                  title: 'Pending\nApprovals',
                  value: '0',
                  iconColor: Color(0xFF58677B),
                  iconBackground: Color(0xFFF0F4F8),
                ),
              ]
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

class _PostingOverviewCard extends StatelessWidget {
  const _PostingOverviewCard();

  @override
  Widget build(BuildContext context) {
    final bars = <_BarData>[
      _BarData('JAN', 86),
      _BarData('FEB', 140),
      _BarData('MAR', 182, selected: true),
      _BarData('APR', 118),
      _BarData('MAY', 150),
      _BarData('JUN', 96),
      _BarData('JUL', 130),
    ];

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly Posting Overview',
                  style: TextStyle(
                    color: const Color(0xFF0C1116),
                    fontSize: ResponsiveUtils.sp(5).clamp(17, 20),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_vert_rounded),
                color: Appcolors.ktextdark,
                tooltip: 'More',
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.hp(1.6).clamp(10, 16).toDouble()),
          SizedBox(
            height: ResponsiveUtils.hp(28).clamp(205, 245),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final bar in bars) ...[
                  Expanded(child: _MonthBar(data: bar)),
                  if (bar != bars.last)
                    SizedBox(width: ResponsiveUtils.wp(2).clamp(6, 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  final _BarData data;

  const _MonthBar({required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const labelHeight = 18.0;
        const labelGap = 10.0;
        final tooltipHeight = data.selected ? 28.0 : 0.0;
        final tooltipGap = data.selected ? 8.0 : 0.0;
        final reservedHeight =
            labelHeight + labelGap + tooltipHeight + tooltipGap;
        final maxBarHeight = (constraints.maxHeight - reservedHeight).clamp(
          88.0,
          double.infinity,
        );
        final scaledHeight = (data.height / 182) * maxBarHeight;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (data.selected) ...[
              SizedBox(
                height: tooltipHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF151A1F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        '124',
                        style: TextStyle(
                          color: Appcolors.kwhitecolor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: tooltipGap),
            ],
            Container(
              height: scaledHeight.clamp(48, maxBarHeight),
              decoration: BoxDecoration(
                color: data.selected
                    ? const Color(0xFFA84A0D)
                    : const Color(0xFFE9EEF2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: labelGap),
            SizedBox(
              height: labelHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  data.label,
                  style: TextStyle(
                    color: data.selected
                        ? const Color(0xFFA84A0D)
                        : const Color(0xFF202329),
                    fontSize: ResponsiveUtils.sp(3.2).clamp(10, 12),
                    fontWeight: data.selected
                        ? FontWeight.w800
                        : FontWeight.w700,
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

class _RecentPostsHeader extends StatelessWidget {
  const _RecentPostsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Recent Posts',
            style: TextStyle(
              color: const Color(0xFF0C1116),
              fontSize: ResponsiveUtils.sp(5.2).clamp(18, 21),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'View All',
            style: TextStyle(
              color: const Color(0xFFA84A0D),
              fontSize: ResponsiveUtils.sp(4.4).clamp(15, 18),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentPostsList extends StatelessWidget {
  const _RecentPostsList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _RecentPostTile(
          title: 'New Summer Collec ...',
          date: 'Today, 10:30 AM',
          icon: Icons.auto_awesome_rounded,
          thumbnailColor: Color(0xFF17124B),
        ),
        SizedBox(height: 14),
        _RecentPostTile(
          title: 'Weekly Team Updat...',
          date: 'Yesterday, 4:15 PM',
          icon: Icons.campaign_rounded,
          thumbnailColor: Color(0xFF8F806D),
        ),
        SizedBox(height: 14),
        _RecentPostTile(
          title: 'Growth Analytics 20...',
          date: '22 Mar, 11:00 AM',
          icon: Icons.trending_up_rounded,
          thumbnailColor: Color(0xFF3F5D62),
        ),
      ],
    );
  }
}

class _RecentPostTile extends StatelessWidget {
  final String title;
  final String date;
  final IconData icon;
  final Color thumbnailColor;

  const _RecentPostTile({
    required this.title,
    required this.date,
    required this.icon,
    required this.thumbnailColor,
  });

  @override
  Widget build(BuildContext context) {
    final thumbSize = ResponsiveUtils.wp(13).clamp(46, 58).toDouble();
    final compact = MediaQuery.sizeOf(context).width < 360;

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
              color: thumbnailColor,
              borderRadius: BorderRadiusStyles.kradius10(),
            ),
            child: Icon(
              icon,
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
                  title,
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
                  date,
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
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 9 : 14,
              vertical: compact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE4F4F2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Published',
              style: TextStyle(
                color: const Color(0xFF087D80),
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarData {
  final String label;
  final double height;
  final bool selected;

  const _BarData(this.label, this.height, {this.selected = false});
}
