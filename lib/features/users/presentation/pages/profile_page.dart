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
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
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
          return _buildProfile(context, authState.user, isDark);
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, User user, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ThemeColors.primary(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.person_outlined,
              size: 40,
              color: ThemeColors.primary(context),
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            user.fullName,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          NeuContainer(
            borderRadius: 10,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            variant: NeuVariant.flat,
            child: Text(
              user.role.displayName,
              style: AppTextStyles.labelSmall.copyWith(
                color: ThemeColors.primary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 28),

          if (_editing)
            _buildEditForm(context, user)
          else
            _buildInfoCard(context, user, isDark),

          const SizedBox(height: 28),
          _buildSectionLabel(context, 'Preferences'),
          const SizedBox(height: 12),
          _buildPreferencesCard(context),
          if (user.isAdmin) ...[
            const SizedBox(height: 20),
            _buildSectionLabel(context, 'Administration'),
            const SizedBox(height: 12),
            _buildAdministrationCard(context),
          ],
          const SizedBox(height: 28),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, User user, bool isDark) {
    return Column(
      children: [
        NeuCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile Details',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _infoRow(context, 'Full name', user.fullName),
              const SizedBox(height: 12),
              _infoRow(context, 'Phone', user.phone ?? 'Not set'),
              const SizedBox(height: 12),
              _infoRow(context, 'Role', user.role.displayName),
              const SizedBox(height: 12),
              _infoRow(
                context,
                'Status',
                user.isActive ? 'Active' : 'De-activated',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
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
        Text(label, style: AppTextStyles.bodyMedium),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: ThemeColors.textSecondary(context),
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
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit Profile',
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            NeuTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Your full name',
              keyboardType: TextInputType.name,
              validator: Validators.requiredWith([
                Validators.name,
              ], 'Full Name'),
            ),
            const SizedBox(height: 16),
            NeuTextField(
              controller: _phoneController,
              label: 'Phone',
              hint: '09XX XXX XXXX',
              keyboardType: TextInputType.phone,
              helper: 'Philippine mobile number (optional)',
            ),
            const SizedBox(height: 20),
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
    return Text(
      title,
      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
    );
  }

  /// Merged settings section — app preferences.
  Widget _buildPreferencesCard(BuildContext context) {
    return NeuCard(
      borderRadius: 20,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notification Settings',
            subtitle: 'Manage alerts, categories & delivery',
            onTap: () => context.push(Routes.notifications),
          ),
          const Divider(height: 1, indent: 56),
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
      borderRadius: 20,
      padding: EdgeInsets.zero,
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out of CarePaw?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: ThemeColors.textSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: ThemeColors.error(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
    return ListTile(
      leading: NeuContainer(
        borderRadius: 12,
        padding: const EdgeInsets.all(8),
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.16)
            : AppColors.primaryTint,
        child: Icon(icon, color: ThemeColors.primary(context), size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: ThemeColors.textTertiary(context),
      ),
      onTap: onTap,
    );
  }
}
