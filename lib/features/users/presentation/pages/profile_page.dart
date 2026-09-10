import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
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
/// Used for both the common `/profile` and `/settings` routes. Reads from
/// [AuthBloc] to get the current user and writes via [UserRepository].
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
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profile updated.'),
        backgroundColor: ThemeColors.success(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Update failed: $e'),
        backgroundColor: ThemeColors.error(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
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
            return const Center(child: NeuCircularProgress(size: 32, strokeWidth: 3));
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
            style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: AppTextStyles.bodyMedium.subtleOf(Theme.of(context).brightness),
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
              Text('Profile Details', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _infoRow(context, 'Full name', user.fullName),
              const SizedBox(height: 12),
              _infoRow(context, 'Phone', user.phone ?? 'Not set'),
              const SizedBox(height: 12),
              _infoRow(context, 'Role', user.role.displayName),
              const SizedBox(height: 12),
              _infoRow(context, 'Status', user.isActive ? 'Active' : 'De-activated'),
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
            Text('Edit Profile', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            NeuTextField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Your full name',
              keyboardType: TextInputType.name,
              validator: Validators.requiredWith([Validators.name], 'Full Name'),
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
}