import 'package:crisant_connect/core/appconstants.dart';
import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/core/routes/approutes.dart';
import 'package:crisant_connect/features/notifications/blocs/notifications_bloc/notifications_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CrisantAppBar extends StatefulWidget {
  final bool showProfile;
  final bool showNotifications;
  final bool showBackButton;

  const CrisantAppBar({
    super.key,
    this.showProfile = true,
    this.showNotifications = true,
    this.showBackButton = false,
  });

  @override
  State<CrisantAppBar> createState() => _CrisantAppBarState();
}

class _CrisantAppBarState extends State<CrisantAppBar> {
  bool _hasNotificationsBloc = false;
  bool _requestedUnreadCount = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncNotificationsBloc();
  }

  @override
  void didUpdateWidget(covariant CrisantAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showNotifications != widget.showNotifications) {
      _requestedUnreadCount = false;
      _syncNotificationsBloc();
    }
  }

  void _syncNotificationsBloc() {
    if (!widget.showNotifications) return;

    try {
      final notificationsBloc = context.read<NotificationsBloc>();
      _hasNotificationsBloc = true;
      if (!_requestedUnreadCount) {
        notificationsBloc.add(FetchUnreadCountRequested());
        _requestedUnreadCount = true;
      }
    } catch (_) {
      _hasNotificationsBloc = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ResponsiveUtils.wp(4.6),
        ResponsiveUtils.hp(1.8),
        ResponsiveUtils.wp(4.6),
        ResponsiveUtils.hp(1.5),
      ),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.showBackButton) ...[
            IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.go(Approtes.dashboard);
              },
              icon: const Icon(Icons.arrow_back_rounded),
              color: const Color(0xFF66758A),
              tooltip: 'Back',
            ),
            SizedBox(width: ResponsiveUtils.wp(1)),
          ],
          Image.asset(
            Appconstants.applogo,
            height: ResponsiveUtils.wp(7.5).clamp(28, 34),
            width: ResponsiveUtils.wp(8.5).clamp(32, 40),
          ),
          SizedBox(width: ResponsiveUtils.wp(2.3)),
          Text(
            'Crisant',
            style: TextStyle(
              color: const Color(0xFFD65A16),
              fontSize: ResponsiveUtils.sp(5.5).clamp(20, 24),
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (widget.showNotifications)
            _hasNotificationsBloc
                ? BlocBuilder<NotificationsBloc, NotificationsState>(
                    buildWhen: (previous, current) =>
                        previous.unreadCount != current.unreadCount,
                    builder: (context, state) {
                      return _NotificationButton(
                        unreadCount: state.unreadCount,
                        onTap: () => context.push(Approtes.notifications),
                      );
                    },
                  )
                : _NotificationButton(unreadCount: 0, onTap: () {}),
          if (widget.showProfile) ...[
            SizedBox(width: ResponsiveUtils.wp(1.4)),
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.push(Approtes.profile),
                child: Container(
                  height: ResponsiveUtils.wp(8).clamp(38, 44),
                  width: ResponsiveUtils.wp(8).clamp(38, 44),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Appcolors.kprimarycolor,
                      width: 2,
                    ),
                    color: Appcolors.kprimaryLightColor.withValues(alpha: 0.45),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Appcolors.kprimarycolor,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const _NotificationButton({required this.unreadCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final badgeText = unreadCount > 99 ? '99+' : unreadCount.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.notifications_rounded),
          color: const Color(0xFF66758A),
          tooltip: 'Notifications',
        ),
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Appcolors.kredcolor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Appcolors.kwhitecolor, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Appcolors.kwhitecolor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
