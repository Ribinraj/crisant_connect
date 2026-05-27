import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/constants.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/features/notifications/blocs/notifications_bloc/notifications_bloc.dart';
import 'package:crisant_connect/features/notifications/models/notifications_response.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/crisant_app_bar.dart';
import 'package:crisant_connect/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScreenNotifications extends StatefulWidget {
  const ScreenNotifications({super.key});

  @override
  State<ScreenNotifications> createState() => _ScreenNotificationsState();
}

class _ScreenNotificationsState extends State<ScreenNotifications> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationsBloc>().add(FetchNotificationsRequested());
  }

  Future<void> _refreshNotifications() async {
    context.read<NotificationsBloc>().add(FetchNotificationsRequested());
  }

  void _markAsRead(AppNotification notification) {
    if (notification.isRead) return;

    context.read<NotificationsBloc>().add(
      MarkNotificationReadRequested(notificationId: notification.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        opacity: 0.35,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const CrisantAppBar(
                showBackButton: true,
                showNotifications: false,
                showProfile: false,
              ),
              Expanded(
                child: BlocConsumer<NotificationsBloc, NotificationsState>(
                  listener: (context, state) {
                    if (state is NotificationsFailure &&
                        state.notifications.isNotEmpty) {
                      CustomSnackbar.show(
                        context,
                        message: state.message,
                        type: SnackbarType.error,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is NotificationsLoading &&
                        state.notifications.isEmpty) {
                      return const _NotificationsLoading();
                    }

                    if (state is NotificationsFailure &&
                        state.notifications.isEmpty) {
                      return _NotificationsError(
                        message: state.message,
                        onRetry: _refreshNotifications,
                      );
                    }

                    if (state.notifications.isEmpty) {
                      return const _NotificationsEmpty();
                    }

                    return RefreshIndicator(
                      color: Appcolors.kprimarycolor,
                      onRefresh: _refreshNotifications,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveUtils.wp(4.6),
                          ResponsiveUtils.hp(1.8),
                          ResponsiveUtils.wp(4.6),
                          ResponsiveUtils.hp(4.5),
                        ),
                        itemCount: state.notifications.length + 1,
                        separatorBuilder: (_, index) => index == 0
                            ? SizedBox(height: ResponsiveUtils.hp(1.6))
                            : const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _NotificationsHeader(
                              unreadCount: state.unreadCount,
                            );
                          }

                          final notification = state.notifications[index - 1];
                          return _NotificationTile(
                            notification: notification,
                            isMarkingRead:
                                state.readingNotificationId == notification.id,
                            onTap: () => _markAsRead(notification),
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
}

class _NotificationsHeader extends StatelessWidget {
  final int unreadCount;

  const _NotificationsHeader({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  color: Appcolors.ktextdark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                unreadCount == 1
                    ? '1 unread notification'
                    : '$unreadCount unread notifications',
                style: TextStyle(
                  color: Appcolors.ktextlight.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Appcolors.kprimarycolor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: Appcolors.kprimarycolor,
          ),
        ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final bool isMarkingRead;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isMarkingRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadiusStyles.kradius15(),
        onTap: isUnread && !isMarkingRead ? onTap : null,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread
                ? Appcolors.kwhitecolor
                : Appcolors.kwhitecolor.withValues(alpha: 0.74),
            borderRadius: BorderRadiusStyles.kradius15(),
            border: Border.all(
              color: isUnread
                  ? Appcolors.kprimaryLightColor.withValues(alpha: 0.6)
                  : Appcolors.kprimaryLightColor.withValues(alpha: 0.26),
            ),
            boxShadow: [
              BoxShadow(
                color: Appcolors.kblackcolor.withValues(alpha: 0.025),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationIcon(type: notification.type, isUnread: isUnread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              color: Appcolors.ktextdark,
                              fontSize: 15.5,
                              fontWeight: isUnread
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            height: 9,
                            width: 9,
                            margin: const EdgeInsets.only(top: 5),
                            decoration: const BoxDecoration(
                              color: Appcolors.kprimarycolor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: Appcolors.ktextlight.withValues(alpha: 0.95),
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (notification.clientName.isNotEmpty)
                          _NotificationMetaChip(
                            icon: Icons.business_rounded,
                            label: notification.clientName,
                          ),
                        _NotificationMetaChip(
                          icon: Icons.access_time_rounded,
                          label: _formatCreatedAt(notification),
                        ),
                        if (notification.relatedPostId != null)
                          _NotificationMetaChip(
                            icon: Icons.article_rounded,
                            label: 'Post ${notification.relatedPostId}',
                          ),
                      ],
                    ),
                    if (isUnread) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: isMarkingRead ? null : onTap,
                          style: TextButton.styleFrom(
                            foregroundColor: Appcolors.kprimarycolor,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: isMarkingRead
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Appcolors.kprimarycolor,
                                  ),
                                )
                              : const Icon(Icons.done_rounded, size: 18),
                          label: const Text(
                            'Mark as read',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCreatedAt(AppNotification notification) {
    final dateTime = notification.createdAt;
    if (dateTime == null) return notification.createdAtText;

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year.toString();
    return '$day/$month/$year';
  }
}

class _NotificationIcon extends StatelessWidget {
  final String type;
  final bool isUnread;

  const _NotificationIcon({required this.type, required this.isUnread});

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'lead_received' => Icons.person_add_alt_1_rounded,
      'approved' => Icons.check_circle_rounded,
      _ => Icons.notifications_rounded,
    };

    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: isUnread
            ? Appcolors.kprimarycolor.withValues(alpha: 0.12)
            : Appcolors.ktextlight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: isUnread ? Appcolors.kprimarycolor : Appcolors.ktextlight,
      ),
    );
  }
}

class _NotificationMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _NotificationMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Appcolors.kbackgroundcolor.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Appcolors.ktextlight),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Appcolors.ktextlight,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsLoading extends StatelessWidget {
  const _NotificationsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Appcolors.kprimarycolor),
    );
  }
}

class _NotificationsEmpty extends StatelessWidget {
  const _NotificationsEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              color: Appcolors.kprimarycolor.withValues(alpha: 0.72),
              size: 46,
            ),
            const SizedBox(height: 12),
            const Text(
              'No notifications yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Appcolors.ktextdark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _NotificationsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Appcolors.kredcolor,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Appcolors.ktextdark,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
