import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated.'),
          backgroundColor: ThemeColors.success(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: ThemeColors.error(context),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
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
    return Scaffold(
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
            icon: Icons.person_outlined,
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
            borderRadius: 12,
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
          if (user.isAdmin) ...[
            const SizedBox(height: 24),
            _buildSectionLabel(context, 'Administration'),
            const SizedBox(height: 14),
            _buildAdministrationCard(context),
          ],
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
            icon: Icons.notifications_outlined,
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
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQs, contact us, feedback',
            onTap: () => _showComingSoon(context, 'Help & Support'),
          ),
        ],
      ),
    );
  }

  /// Merged settings section — admin-only clinic configuration entry.
  Widget _buildAdministrationCard(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: _SettingTile(
        icon: Icons.tune_outlined,
        title: 'System Configuration',
        subtitle: 'Audit, queue, inventory, OCR & auth settings',
        onTap: () => context.push(Routes.adminSettings),
      ),
    );
  }

  /// Logout entry, confirming before dispatching the sign-out event.
  Widget _buildLogoutButton(BuildContext context) {
    return NeuButton(
      text: 'Logout',
      variant: NeuButtonVariant.destructive,
      size: NeuButtonSize.large,
      icon: Icons.logout_rounded,
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
                          const AuthLogoutRequested(),
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingTile({
    required this.icon,
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
              borderRadius: 14,
              padding: const EdgeInsets.all(10),
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.16)
                  : AppColors.primaryTint,
              child: Icon(icon, color: ThemeColors.primary(context), size: 22),
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
            Icon(Icons.chevron_right, color: ThemeColors.textTertiary(context)),
          ],
        ),
      ),
    );
  }
}
