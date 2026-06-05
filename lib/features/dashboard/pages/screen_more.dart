import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/local_storage.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/core/routes/approutes.dart';
import 'package:crisant_connect/features/authentication/blocs/logout_bloc/logout_bloc.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ScreenMore extends StatelessWidget {
  const ScreenMore({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Appcolors.kredcolor),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true || !context.mounted) return;

    final refreshToken = await LocalStorage.getRefreshToken();
    if (!context.mounted) return;

    if (refreshToken.isEmpty) {
      await LocalStorage.clearAll();
      if (!context.mounted) return;
      context.go(Approtes.login);
      return;
    }

    context.read<LogoutBloc>().add(LogoutRequested(refreshToken: refreshToken));
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return BlocConsumer<LogoutBloc, LogoutState>(
      listener: (context, state) async {
        if (state is LogoutSuccess) {
          await LocalStorage.clearAll();
          if (!context.mounted) return;
          context.go(Approtes.login);
        }

        if (state is LogoutFailure) {
          CustomSnackbar.show(
            context,
            message: state.message,
            type: SnackbarType.error,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is LogoutLoading;

        return AppBackground(
          opacity: 0.35,
          child: SafeArea(
            child: Padding(
              padding: ResponsiveUtils.pagePadding(
                context,
                mobileHorizontalPercent: 6,
                top: ResponsiveUtils.hp(3).clamp(18, 30).toDouble(),
                bottom: ResponsiveUtils.bottomScrollPadding(context),
              ),
              child: ResponsiveUtils.constrainWidth(
                context: context,
                maxWidth: ResponsiveUtils.isDesktop(context)
                    ? ResponsiveUtils.desktopReadableMaxWidth
                    : ResponsiveUtils.narrowPageMaxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'More',
                      style: TextStyle(
                        color: Appcolors.ktextdark,
                        fontSize: ResponsiveUtils.isDesktop(context)
                            ? 32.0
                            : ResponsiveUtils.sp(7).clamp(26, 30).toDouble(),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _MoreActionTile(
                      icon: Icons.logout_rounded,
                      title: 'Logout',
                      subtitle: 'Sign out from this device',
                      iconColor: Appcolors.kredcolor,
                      isLoading: isLoading,
                      onTap: isLoading ? null : () => _confirmLogout(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MoreActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const _MoreActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Material(
      color: Appcolors.kwhitecolor.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Opacity(
          opacity: onTap == null ? 0.72 : 1,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 22 : 16,
              vertical: isDesktop ? 18 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Appcolors.kprimaryLightColor.withValues(alpha: 0.38),
              ),
            ),
            child: Row(
              children: [
                Container(
                  height: isDesktop ? 56 : 44,
                  width: isDesktop ? 56 : 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Appcolors.kredcolor,
                          ),
                        )
                      : Icon(icon, color: iconColor, size: isDesktop ? 30 : 24),
                ),
                SizedBox(width: isDesktop ? 18 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Appcolors.ktextdark,
                          fontSize: isDesktop ? 19 : 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isLoading ? 'Signing out...' : subtitle,
                        style: TextStyle(
                          color: Appcolors.ktextlight,
                          fontSize: isDesktop ? 15 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Appcolors.ktextlight,
                  size: isDesktop ? 30 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
