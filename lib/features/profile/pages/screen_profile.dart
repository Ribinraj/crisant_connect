import 'package:crisant_connect/core/colors.dart';
import 'package:crisant_connect/core/constants.dart';
import 'package:crisant_connect/core/local_storage.dart';
import 'package:crisant_connect/core/responsiveutils.dart';
import 'package:crisant_connect/core/routes/approutes.dart';
import 'package:crisant_connect/features/authentication/blocs/logout_bloc/logout_bloc.dart';
import 'package:crisant_connect/features/profile/blocs/profile_bloc/profile_bloc.dart';
import 'package:crisant_connect/features/profile/models/profile_response.dart';
import 'package:crisant_connect/widgets/app_background.dart';
import 'package:crisant_connect/widgets/crisant_app_bar.dart';
import 'package:crisant_connect/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ScreenProfile extends StatefulWidget {
  const ScreenProfile({super.key});

  @override
  State<ScreenProfile> createState() => _ScreenProfileState();
}

class _ScreenProfileState extends State<ScreenProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  ProfileUser? _lastUser;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(FetchProfileRequested());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _syncUser(ProfileUser user) {
    _lastUser = user;
    if (_nameController.text != user.fullName) {
      _nameController.text = user.fullName;
    }
    if (_mobileController.text != user.mobileNumber) {
      _mobileController.text = user.mobileNumber;
    }
  }

  void _submit(ProfileUser currentUser) {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    context.read<ProfileBloc>().add(
      UpdateProfileSubmitted(
        fullName: _nameController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        currentUser: currentUser,
      ),
    );
  }

  Future<void> _confirmLogout() async {
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

    if (shouldLogout != true || !mounted) return;

    final refreshToken = await LocalStorage.getRefreshToken();
    if (!mounted) return;

    if (refreshToken.isEmpty) {
      await LocalStorage.clearAll();
      if (!mounted) return;
      context.go(Approtes.login);
      return;
    }

    context.read<LogoutBloc>().add(LogoutRequested(refreshToken: refreshToken));
  }

  Future<void> _refreshProfile() async {
    context.read<ProfileBloc>().add(FetchProfileRequested());
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils().init(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) {
              _syncUser(state.user);
            }

            if (state is ProfileUpdateSuccess) {
              _syncUser(state.user);
              CustomSnackbar.show(
                context,
                message: state.message,
                type: SnackbarType.success,
              );
            }

            if (state is ProfileFailure && state.user != null) {
              CustomSnackbar.show(
                context,
                message: state.message,
                type: SnackbarType.error,
              );
            }
          },
        ),
        BlocListener<LogoutBloc, LogoutState>(
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
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          opacity: 0.35,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const CrisantAppBar(showProfile: false),
                Expanded(
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      final user = _userFromState(state) ?? _lastUser;

                      if (user == null &&
                          (state is ProfileLoading ||
                              state is ProfileInitial)) {
                        return const _ProfileLoading();
                      }

                      if (user == null && state is ProfileFailure) {
                        return _ProfileError(
                          message: state.message,
                          onRetry: _refreshProfile,
                        );
                      }

                      final profileUser = user ?? const ProfileUser.empty();
                      final isUpdating = state is ProfileUpdating;

                      return BlocBuilder<LogoutBloc, LogoutState>(
                        builder: (context, logoutState) {
                          final isLoggingOut = logoutState is LogoutLoading;

                          return RefreshIndicator(
                            color: Appcolors.kprimarycolor,
                            onRefresh: _refreshProfile,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: ResponsiveUtils.pagePadding(
                                context,
                                top: ResponsiveUtils.hp(1.8),
                                bottom: ResponsiveUtils.isMobile(context)
                                    ? ResponsiveUtils.hp(4.5)
                                    : 36,
                              ),
                              children: [
                                ResponsiveUtils.constrainWidth(
                                  context: context,
                                  maxWidth: ResponsiveUtils.isDesktop(context)
                                      ? double.infinity
                                      : ResponsiveUtils.narrowPageMaxWidth,
                                  child: ResponsiveUtils.isDesktop(context)
                                      ? _ProfileDesktopLayout(
                                          user: profileUser,
                                          formKey: _formKey,
                                          nameController: _nameController,
                                          mobileController: _mobileController,
                                          isUpdating: isUpdating,
                                          isLoggingOut: isLoggingOut,
                                          onSubmit: isUpdating || isLoggingOut
                                              ? null
                                              : () => _submit(profileUser),
                                          onLogout: isUpdating || isLoggingOut
                                              ? null
                                              : _confirmLogout,
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _ProfileHeader(user: profileUser),
                                            SizedBox(
                                              height: ResponsiveUtils.hp(2),
                                            ),
                                            _ProfileSummaryCard(
                                              user: profileUser,
                                            ),
                                            SizedBox(
                                              height: ResponsiveUtils.hp(2),
                                            ),
                                            _ProfileFormCard(
                                              formKey: _formKey,
                                              nameController: _nameController,
                                              mobileController:
                                                  _mobileController,
                                              isUpdating: isUpdating,
                                              onSubmit:
                                                  isUpdating || isLoggingOut
                                                  ? null
                                                  : () => _submit(profileUser),
                                            ),
                                            SizedBox(
                                              height: ResponsiveUtils.hp(2),
                                            ),
                                            _LogoutTile(
                                              isLoading: isLoggingOut,
                                              onTap: isUpdating || isLoggingOut
                                                  ? null
                                                  : _confirmLogout,
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ProfileUser? _userFromState(ProfileState state) {
    if (state is ProfileLoaded) return state.user;
    if (state is ProfileUpdating) return state.user;
    if (state is ProfileUpdateSuccess) return state.user;
    if (state is ProfileFailure) return state.user;
    return null;
  }
}

class _ProfileDesktopLayout extends StatelessWidget {
  final ProfileUser user;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final bool isUpdating;
  final bool isLoggingOut;
  final VoidCallback? onSubmit;
  final VoidCallback? onLogout;

  const _ProfileDesktopLayout({
    required this.user,
    required this.formKey,
    required this.nameController,
    required this.mobileController,
    required this.isUpdating,
    required this.isLoggingOut,
    required this.onSubmit,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(user: user),
        const SizedBox(height: 26),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: _ProfileDesktopAccountPanel(
                  user: user,
                  isLoggingOut: isLoggingOut,
                  onLogout: onLogout,
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                flex: 8,
                child: _ProfileFormCard(
                  formKey: formKey,
                  nameController: nameController,
                  mobileController: mobileController,
                  isUpdating: isUpdating,
                  onSubmit: onSubmit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileUser user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: Appcolors.ktextdark,
          tooltip: 'Back',
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  color: Appcolors.ktextdark,
                  fontSize: isDesktop ? 40 : 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                user.mobileNumber.isEmpty
                    ? 'Account details'
                    : user.mobileNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Appcolors.ktextlight,
                  fontSize: isDesktop ? 18 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileDesktopAccountPanel extends StatelessWidget {
  final ProfileUser user;
  final bool isLoggingOut;
  final VoidCallback? onLogout;

  const _ProfileDesktopAccountPanel({
    required this.user,
    required this.isLoggingOut,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user.fullName.trim().isEmpty
        ? 'Crisant User'
        : user.fullName.trim();
    final role = user.role.trim().isEmpty ? 'User' : user.role.trim();
    final initial = displayName.characters.first.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
        borderRadius: BorderRadiusStyles.kradius15(),
        border: Border.all(
          color: Appcolors.kprimaryLightColor.withValues(alpha: 0.38),
        ),
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
          Container(
            height: 112,
            width: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Appcolors.kprimaryLightColor.withValues(alpha: 0.42),
              border: Border.all(color: Appcolors.kprimarycolor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Appcolors.kprimarycolor,
                fontSize: 40,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Appcolors.ktextdark,
              fontSize: 31,
              fontWeight: FontWeight.w900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.mobileNumber.isEmpty ? 'Account details' : user.mobileNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Appcolors.ktextlight,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProfileChip(icon: Icons.badge_rounded, label: role),
              _ProfileChip(
                icon: Icons.verified_user_rounded,
                label: user.leadsAccess ? 'Leads access' : 'Standard',
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: 24),
          _LogoutTile(isLoading: isLoggingOut, onTap: onLogout),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final ProfileUser user;

  const _ProfileSummaryCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final avatarSize = isDesktop ? 82.0 : 68.0;
    final displayName = user.fullName.trim().isEmpty
        ? 'Crisant User'
        : user.fullName.trim();
    final role = user.role.trim().isEmpty ? 'User' : user.role.trim();
    final initial = displayName.characters.first.toUpperCase();

    return Container(
      padding: EdgeInsets.all(isDesktop ? 26 : 18),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
        borderRadius: BorderRadiusStyles.kradius15(),
        border: Border.all(
          color: Appcolors.kprimaryLightColor.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: avatarSize,
            width: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Appcolors.kprimaryLightColor.withValues(alpha: 0.42),
              border: Border.all(color: Appcolors.kprimarycolor, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: Appcolors.kprimarycolor,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Appcolors.ktextdark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ProfileChip(icon: Icons.badge_rounded, label: role),
                    _ProfileChip(
                      icon: Icons.verified_user_rounded,
                      label: user.leadsAccess ? 'Leads access' : 'Standard',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 13 : 10,
        vertical: isDesktop ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: Appcolors.kprimaryLightColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isDesktop ? 18 : 14, color: Appcolors.kprimarycolor),
          SizedBox(width: isDesktop ? 7 : 5),
          Text(
            label,
            style: TextStyle(
              color: Appcolors.ktextdark,
              fontSize: isDesktop ? 14 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final bool isUpdating;
  final VoidCallback? onSubmit;

  const _ProfileFormCard({
    required this.formKey,
    required this.nameController,
    required this.mobileController,
    required this.isUpdating,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 36 : 18),
      decoration: BoxDecoration(
        color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
        borderRadius: BorderRadiusStyles.kradius15(),
        border: Border.all(
          color: Appcolors.kprimaryLightColor.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: Appcolors.kblackcolor.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Personal Details',
              style: TextStyle(
                color: Appcolors.ktextdark,
                fontSize: isDesktop ? 28 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: isDesktop ? 28 : 16),
            _ProfileInput(
              controller: nameController,
              labelText: 'Full name',
              hintText: 'Enter full name',
              prefixIcon: Icons.person_rounded,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Enter full name';
                }
                return null;
              },
            ),
            SizedBox(height: isDesktop ? 22 : 14),
            _ProfileInput(
              controller: mobileController,
              labelText: 'Mobile number',
              hintText: 'Enter mobile number',
              prefixIcon: Icons.phone_rounded,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Enter mobile number';
                }
                return null;
              },
            ),
            SizedBox(height: isDesktop ? 30 : 18),
            SizedBox(
              height: isDesktop ? 64 : 52,
              child: ElevatedButton(
                onPressed: onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appcolors.kprimarycolor,
                  foregroundColor: Appcolors.kwhitecolor,
                  disabledBackgroundColor: Appcolors.kprimaryLightColor
                      .withValues(alpha: 0.62),
                  disabledForegroundColor: Appcolors.kwhitecolor.withValues(
                    alpha: 0.8,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isUpdating
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Appcolors.kwhitecolor,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 15,
                          fontWeight: FontWeight.w800,
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

class _ProfileInput extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;

  const _ProfileInput({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      style: TextStyle(
        color: Appcolors.ktextdark,
        fontSize: isDesktop ? 18 : 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Appcolors.kwhitecolor,
        prefixIcon: Icon(prefixIcon, size: isDesktop ? 26 : 22),
        prefixIconColor: Appcolors.kprimarycolor,
        labelText: labelText,
        hintText: hintText,
        labelStyle: const TextStyle(
          color: Appcolors.kprimarycolor,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: Appcolors.ktextlight.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 20 : 18,
          vertical: isDesktop ? 22 : 17,
        ),
        enabledBorder: _border(Appcolors.kprimaryLightColor, 0.46),
        focusedBorder: _border(Appcolors.kprimarycolor, 1),
        errorBorder: _border(Appcolors.kredcolor, 1),
        focusedErrorBorder: _border(Appcolors.kredcolor, 1),
      ),
    );
  }

  OutlineInputBorder _border(Color color, double alpha) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color.withValues(alpha: alpha), width: 1.4),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _LogoutTile({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Material(
      color: Appcolors.kwhitecolor.withValues(alpha: 0.94),
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
                    color: Appcolors.kredcolor.withValues(alpha: 0.1),
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
                      : Icon(
                          Icons.logout_rounded,
                          color: Appcolors.kredcolor,
                          size: isDesktop ? 30 : 24,
                        ),
                ),
                SizedBox(width: isDesktop ? 18 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Appcolors.ktextdark,
                          fontSize: isDesktop ? 19 : 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isLoading
                            ? 'Signing out...'
                            : 'Sign out from this device',
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

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Appcolors.kprimarycolor),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ProfileError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: ResponsiveUtils.pagePadding(
        context,
        mobileHorizontalPercent: 6,
        top: ResponsiveUtils.hp(12),
        bottom: ResponsiveUtils.hp(4),
      ),
      children: [
        ResponsiveUtils.constrainWidth(
          context: context,
          maxWidth: ResponsiveUtils.isDesktop(context)
              ? ResponsiveUtils.desktopReadableMaxWidth
              : ResponsiveUtils.narrowPageMaxWidth,
          child: Column(
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: Appcolors.kprimarycolor.withValues(alpha: 0.8),
                size: 58,
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Appcolors.ktextdark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(
                  backgroundColor: Appcolors.kprimarycolor,
                  foregroundColor: Appcolors.kwhitecolor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
