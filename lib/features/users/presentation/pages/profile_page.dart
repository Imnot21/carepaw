import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart'
    as auth_events;
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/core/constants/app_constants.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';

/// Profile page - shows the authenticated user's info with name/phone editing.
///
/// The single `/profile` destination also carries the merged settings content:
/// app preferences, admin-only system configuration, and a logout button. Reads
/// from [AuthBloc] to get the current user and writes via [UserRepository].
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _editing = false;
  bool _saving = false;
  bool _changingPassword = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _nameController.text = authState.user.fullName;
      _phoneController.text = authState.user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _saving = true);
    try {
      final repo = getIt<UserRepository>();
      await repo.updateProfile(
        authState.user.id!,
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      // Refresh the session user so the header name updates immediately
      // instead of staying stale until the next login.
      context.read<AuthBloc>().add(const auth_events.AuthCheckRequested());
      if (!mounted) return;
      NeuToast.success(context, 'Profile updated.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      NeuToast.error(context, 'Could not update profile. Please try again.');
    }
  }

  void _cancelEdit() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _nameController.text = authState.user.fullName;
      _phoneController.text = authState.user.phone ?? '';
    }
    setState(() => _editing = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Only react to results of the change-password dialog, never to
        // unrelated auth traffic (login/logout/session checks).
        if (!_changingPassword) return;
        if (state is AuthPasswordChanged) {
          _changingPassword = false;
          NeuToast.success(context, 'Password changed. Please sign in again.');
        } else if (state is AuthError) {
          _changingPassword = false;
          NeuToast.error(
            context,
            'Password change failed: ${state.failure.message}',
          );
        }
      },
      child: Scaffold(
        backgroundColor: ThemeColors.background(context),
        appBar: AppBar(
          title: Text(
            'Profile',
            style: AppTextStyles.appBarTitle.copyWith(
              color: ThemeColors.textPrimary(context),
            ),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            if (authState is! AuthAuthenticated) {
              return const Center(
                child: NeuCircularProgress(size: 32, strokeWidth: 3),
              );
            }
            return _buildProfile(context, authState.user);
          },
        ),
        // Add bottom padding to prevent content from being hidden by navigation bar
        extendBody: true,
        bottomNavigationBar:
            const SizedBox.shrink(), // This ensures the scaffold has a bottom navigation bar space
      ),
    );
  }

  Widget _buildProfile(BuildContext context, User user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar — circular contour
          NeuAvatar(
            radius: 44,
            svgAsset: SvgIcons.person,
            backgroundColor: ThemeColors.primary(
              context,
            ).withValues(alpha: 0.14),
            foregroundColor: ThemeColors.primary(context),
          ),
          const SizedBox(height: 20),

          // Name
          Text(
            user.fullName,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: ThemeColors.textPrimary(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            user.email,
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          NeuContainer(
            borderRadius: NeuTokens.radiusSm,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            variant: NeuVariant.flat,
            child: Text(
              user.role.displayName,
              style: AppTextStyles.labelSmall.copyWith(
                color: ThemeColors.textSecondary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 36),

          if (_editing)
            _buildEditForm(context, user)
          else
            _buildInfoCard(context, user),

          const SizedBox(height: 32),
          _buildSectionLabel(context, 'Preferences'),
          const SizedBox(height: 14),
          _buildPreferencesCard(context),
          // Administration card HIDDEN in the paper build (settings/audit
          // stay in code, reachable only by direct route, not from tabs).
          const SizedBox(height: 32),
          _buildLogoutButton(context),
          // Add padding at the bottom to prevent logout button from being hidden by navigation
          const SizedBox(height: 84),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, User user) {
    return Column(
      children: [
        NeuCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Details',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ThemeColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 18),
              _infoRow(context, 'Full name', user.fullName),
              const SizedBox(height: 14),
              _infoRow(context, 'Phone', user.phone ?? 'Not set'),
              const SizedBox(height: 14),
              _infoRow(context, 'Role', user.role.displayName),
              const SizedBox(height: 14),
              _infoRow(
                context,
                'Status',
                user.isActive ? 'Active' : 'De-activated',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        NeuButton(
          text: 'Edit Profile',
          variant: NeuButtonVariant.primary,
          icon: Icons.edit_outlined,
          svgAsset: SvgIcons.edit,
          expanded: true,
          onPressed: () => setState(() => _editing = true),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: ThemeColors.textSecondary(context),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: ThemeColors.textPrimary(context),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(BuildContext context, User user) {
    return NeuCard(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Profile',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 20),
            NeuTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Your full name',
              keyboardType: TextInputType.name,
              validator: Validators.requiredWith([
                Validators.name,
              ], 'Full Name'),
            ),
            const SizedBox(height: 18),
            NeuTextField(
              controller: _phoneController,
              label: 'Phone',
              hint: '09XX XXX XXXX',
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              helper: 'Philippine mobile number (optional)',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: NeuButton(
                    text: 'Cancel',
                    variant: NeuButtonVariant.outline,
                    size: NeuButtonSize.medium,
                    onPressed: _cancelEdit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeuButton(
                    text: 'Save',
                    variant: NeuButtonVariant.primary,
                    size: NeuButtonSize.medium,
                    icon: Icons.check_rounded,
                    svgAsset: SvgIcons.check,
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.overline.copyWith(
          color: ThemeColors.textTertiary(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  /// Merged settings section — app preferences.
  Widget _buildPreferencesCard(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _SettingTile(
            svgAsset: SvgIcons.notifications,
            title: 'Notification Settings',
            subtitle: 'Manage alerts, categories & delivery',
            onTap: () => context.push(Routes.notifications),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 1,
              child: NeuContainer(
                padding: EdgeInsets.zero,
                borderRadius: 0.5,
                variant: NeuVariant.flat,
                boxShadow: NeuShadow.none,
                color: ThemeColors.border(context),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          _SettingTile(
            svgAsset: SvgIcons.lock,
            title: 'Change Password',
            subtitle: 'Update your sign-in password',
            onTap: () => _showChangePasswordDialog(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 1,
              child: NeuContainer(
                padding: EdgeInsets.zero,
                borderRadius: 0.5,
                variant: NeuVariant.flat,
                boxShadow: NeuShadow.none,
                color: ThemeColors.border(context),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
          _SettingTile(
            svgAsset: SvgIcons.help,
            title: 'Help & Support',
            subtitle: 'Clinic contact and app info',
            onTap: () => _showHelp(context),
          ),
        ],
      ),
    );
  }

  /// Logout entry, confirming before dispatching the sign-out event.
  Widget _buildLogoutButton(BuildContext context) {
    return NeuButton(
      text: 'Logout',
      variant: NeuButtonVariant.destructive,
      size: NeuButtonSize.medium,
      icon: Icons.logout_rounded,
      svgAsset: SvgIcons.logout,
      expanded: true,
      onPressed: () => _confirmLogout(context),
    );
  }

  /// Confirm then dispatch logout; the router redirects to /login on success.
  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: NeuCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Logout',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: ThemeColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to sign out of CarePaw?',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ThemeColors.textSecondary(context),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: NeuButton(
                      text: 'Cancel',
                      variant: NeuButtonVariant.outline,
                      size: NeuButtonSize.medium,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NeuButton(
                      text: 'Logout',
                      variant: NeuButtonVariant.destructive,
                      size: NeuButtonSize.medium,
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        context.read<AuthBloc>().add(
                          const auth_events.AuthLogoutRequested(),
                        );
                      },
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

  void _showHelp(BuildContext context) {
    NeuDialog.show(
      context: context,
      title: 'Help & Support',
      content: Text(
        'For bookings, records, or account help, please contact or visit '
        '${AppConstants.clinicName}, ${AppConstants.clinicLocation}.\n\n'
        '${AppConstants.appName} v${AppConstants.appVersion}',
      ),
      actions: [
        NeuButton(
          text: 'Got it',
          variant: NeuButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// Change-password dialog. Dispatches [AuthPasswordChanged]; the
  /// [BlocListener] above toasts the result. A successful change signs the
  /// session out (bloc emits a non-authenticated state), so the user signs
  /// back in with the new password.
  void _showChangePasswordDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    String? matchValidator(String? value) {
      if (value == null || value.isEmpty) return 'Please confirm the password';
      if (value != newController.text) return 'Passwords don\u2019t match';
      return null;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: NeuCard(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Change Password',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'You will be signed out after the change.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  NeuTextField(
                    controller: currentController,
                    label: 'Current password',
                    hint: 'Enter current password',
                    obscureText: true,
                    prefixIcon: ClayIconOrMaterial(
                      'lock_outline_rounded',
                      fallback: Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) =>
                        Validators.required(v, 'Current password'),
                  ),
                  const SizedBox(height: 16),
                  NeuTextField(
                    controller: newController,
                    label: 'New password',
                    hint: 'Create a password',
                    obscureText: true,
                    prefixIcon: ClayIconOrMaterial(
                      'lock_outline_rounded',
                      fallback: Icons.lock_outline_rounded,
                      size: 20,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: Validators.requiredWith([
                      Validators.password,
                    ], 'New password'),
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: newController,
                    builder: (context, value, _) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Min 8 chars, 1 uppercase, 1 lowercase, 1 number',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ThemeColors.textSecondary(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  NeuTextField(
                    controller: confirmController,
                    label: 'Confirm new password',
                    hint: 'Repeat the new password',
                    obscureText: true,
                    prefixIcon: ClayIconOrMaterial(
                      'lock_reset_rounded',
                      fallback: Icons.lock_reset_rounded,
                      size: 20,
                    ),
                    textInputAction: TextInputAction.done,
                    validator: matchValidator,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: NeuButton(
                          text: 'Cancel',
                          variant: NeuButtonVariant.outline,
                          size: NeuButtonSize.medium,
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeuButton(
                          text: 'Update',
                          variant: NeuButtonVariant.primary,
                          size: NeuButtonSize.medium,
                          icon: Icons.check_rounded,
                          svgAsset: SvgIcons.check,
                          onPressed: () {
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            Navigator.pop(dialogContext);
                            setState(() => _changingPassword = true);
                            context.read<AuthBloc>().add(
                              auth_events.AuthPasswordChanged(
                                currentPassword: currentController.text,
                                newPassword: newController.text,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).then((_) {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    });
  }
}

class _SettingTile extends StatelessWidget {
  final String? svgAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    this.svgAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            NeuContainer(
              borderRadius: NeuTokens.radiusSm,
              padding: const EdgeInsets.all(10),
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.16)
                  : AppColors.primaryTint,
              child: svgAsset != null
                  ? NeuSvgIcon(svgAsset!, size: 22)
                  : const SizedBox(width: 22, height: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.subtleOf(
                      Theme.of(context).brightness,
                    ),
                  ),
                ],
              ),
            ),
            NeuSvgIcon(SvgIcons.chevronRight, size: 20),
          ],
        ),
      ),
    );
  }
}
