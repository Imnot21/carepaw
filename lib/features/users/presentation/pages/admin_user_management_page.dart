import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/core/widgets/common/cp_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_event.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_state.dart';

/// Admin user management page - create staff/veterinarian accounts and manage
/// existing staff & veterinarians (roles, activation).
///
/// Wired into both the admin bottom-nav "Users" tab and the `/admin/users`
/// route. Uses [UserManagementBloc] for all data operations.
class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.staff;
  List<User> _users = const [];

  @override
  void initState() {
    super.initState();
    // Load the staff/vet list once the bloc is available (after first frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<UserManagementBloc>().add(const UserManagementLoadRequested());
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCreatePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<UserManagementBloc>().add(
        UserManagementCreateRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          role: _selectedRole,
        ),
      );
      // Clear the form so the next account can be created without editing.
      _fullNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserManagementBloc(),
      child: BlocListener<UserManagementBloc, UserManagementState>(
        listener: (context, state) {
          if (state is UserManagementLoaded) {
            _users = state.users;
          } else if (state is UserManagementActionSuccess) {
            _showSnack(state.message, success: true);
          } else if (state is UserManagementError) {
            _showSnack(state.failure.message);
          }
        },
        child: BlocBuilder<UserManagementBloc, UserManagementState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('User Management'),
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Colors.transparent,
              ),
              body: AnimatedGradientBackground(
                colors: [
                  AppColors.primary.withValues(alpha: 0.07),
                  AppColors.secondary.withValues(alpha: 0.04),
                  AppColors.tertiary.withValues(alpha: 0.05),
                ],
                child: SafeArea(
                  top: false,
                  child: state is UserManagementLoading && _users.isEmpty
                      ? const Center(
                          child: CpLoader(size: 32, strokeWidth: 3),
                        )
                      : _buildContent(context, state),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserManagementState state) {
    final isLoading = state is UserManagementLoading;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading && _users.isNotEmpty) ...[
            const Center(child: CpLoader(size: 20, strokeWidth: 2)),
            const SizedBox(height: 12),
          ],

          // ---------- Create Account ----------
          Text(
            'Create Account',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Add staff, veterinarians, or pet owners. Each account signs in with these credentials.',
            style: AppTextStyles.bodySmall.subtle,
          ),
          const SizedBox(height: 12),

          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            blur: 14,
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.82),
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.glassBorderDark
                : AppColors.glassBorderLight,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CpTextFieldName(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'John Doe',
                    validator: Validators.requiredWith([Validators.name], 'Full Name'),
                  ),
                  const SizedBox(height: 16),
                  CpTextFieldEmail(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    validator: Validators.requiredWith([Validators.email], 'Email'),
                  ),
                  const SizedBox(height: 16),
                  CpTextFieldPhone(
                    controller: _phoneController,
                    label: 'Phone (Optional)',
                    hint: '09XX XXX XXXX',
                    helper: 'Philippine mobile number (optional)',
                  ),
                  const SizedBox(height: 16),
                  CpTextFieldPassword(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Set a starting password',
                    helper: 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number',
                    validator: Validators.requiredWith([Validators.password], 'Password'),
                  ),
                  const SizedBox(height: 16),
                  CpTextFieldPassword(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Confirm the password',
                    validator: (value) {
                      final requiredError = Validators.required(value, 'Confirm Password');
                      if (requiredError != null) return requiredError;
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onCreatePressed(),
                  ),
                  const SizedBox(height: 16),

                  // Role selector (admin is provisioned in the Firebase console)
                  Text(
                    'Role',
                    style: AppTextStyles.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: UserRole.values
                        .where((r) => r != UserRole.admin)
                        .map((role) => _RoleChip(
                              role: role,
                              selected: _selectedRole == role,
                              onTap: () => setState(() => _selectedRole = role),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  CpButton(
                    text: 'Create Account',
                    onPressed: isLoading ? null : _onCreatePressed,
                    isLoading: isLoading,
                    expanded: true,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.large,
                    icon: Icons.person_add_outlined,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ---------- Existing Staff & Veterinarians ----------
          Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Staff & Veterinarians',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_users.length} account(s)',
            style: AppTextStyles.bodySmall.subtle,
          ),
          const SizedBox(height: 12),

          if (_users.isEmpty)
            GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(20),
              blur: 10,
              borderColor: AppColors.glassBorderLight,
              child: Column(
                children: [
                  Icon(Icons.people_outlined, color: AppColors.textSecondary, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'No staff or veterinarian accounts yet.',
                    style: AppTextStyles.bodyMedium.subtle,
                  ),
                ],
              ),
            )
          else
            ..._users.map((user) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UserManagementCard(
                    user: user,
                    onRoleChanged: (role) {
                      if (user.id != null) {
                        context.read<UserManagementBloc>().add(
                          UserManagementChangeRoleRequested(
                            userId: user.id!,
                            newRole: role,
                          ),
                        );
                      }
                    },
                    onToggleActive: (active) {
                      if (user.id != null) {
                        context.read<UserManagementBloc>().add(
                          UserManagementToggleActiveRequested(
                            userId: user.id!,
                            isActive: active,
                          ),
                        );
                      }
                    },
                  ),
                )),
        ],
      ),
    );
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// A selectable role chip used in the create-account form.
class _RoleChip extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  Color get _color => switch (role) {
        UserRole.staff => AppColors.secondary,
        UserRole.veterinarian => AppColors.tertiary,
        UserRole.petOwner => AppColors.info,
        UserRole.admin => AppColors.primary,
      };

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _color : AppColors.glassBorderLight,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(role == UserRole.petOwner ? Icons.person_outline : Icons.medical_services_outlined,
                color: selected ? _color : AppColors.textSecondary, size: 18),
            const SizedBox(width: 6),
            Text(
              role.displayName,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? _color : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card listing one staff / veterinarian with role + activation controls.
class _UserManagementCard extends StatelessWidget {
  final User user;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<bool> onToggleActive;

  const _UserManagementCard({
    required this.user,
    required this.onRoleChanged,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final role = user.role;
    final primary = user.isActive ? roleColor(role) : AppColors.textSecondary;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      blur: 12,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: primary.withValues(alpha: 0.3),
      borderWidth: 1.2,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: roleColor(role).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              role == UserRole.veterinarian ? Icons.medical_services_outlined : Icons.person_outline,
              color: roleColor(role),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: AppTextStyles.bodySmall.subtle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  user.isActive ? 'Active' : 'De-activated',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: user.isActive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Role dropdown
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              DropdownButton<UserRole>(
                value: user.role,
                underline: const SizedBox.shrink(),
                style: AppTextStyles.labelMedium.copyWith(color: roleColor(role)),
                borderRadius: BorderRadius.circular(12),
                items: [UserRole.staff, UserRole.veterinarian, UserRole.petOwner]
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r.displayName),
                        ))
                    .toList(),
                onChanged: user.isActive
                    ? (role) {
                        if (role != null && role != user.role) onRoleChanged(role);
                      }
                    : null,
              ),
              // Activation switch
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: user.isActive,
                  activeTrackColor: AppColors.success,
                  onChanged: (v) => onToggleActive(v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Role accent color shared by the page widgets.
Color roleColor(UserRole role) => switch (role) {
      UserRole.staff => AppColors.secondary,
      UserRole.veterinarian => AppColors.tertiary,
      UserRole.petOwner => AppColors.info,
      UserRole.admin => AppColors.primary,
    };