import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/constants/app_constants.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_bloc.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_event.dart';
import 'package:carepaw/features/users/presentation/bloc/user_management_state.dart';

/// Admin user management page - create staff/veterinarian accounts and manage
/// existing staff and veterinarians (roles, activation).
///
/// Bloc is provided by the route in `AppRouter` so it is created once per
/// navigation and lives as long as this page is on the stack.
class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _searchController = TextEditingController();

  UserRole _selectedRole = UserRole.staff;
  String _searchQuery = '';
  UserRole? _roleFilter;
  int _visibleCount = AppConstants.defaultPageSize;
  Timer? _searchDebounce;

  static const _debounceMs = AppConstants.searchDebounceMs;
  // _users is derived from Bloc state, never stored.

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _searchController.dispose();
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
      _fullNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    }
  }

  /// Confirm and dispatch a permanent account deletion.
  ///
  /// Deleting revokes the target's Firebase Auth credential (freeing the
  /// email so it can be re-created) and removes their Firestore document.
  /// Because this is irreversible, we require an explicit confirmation that
  /// names the account before dispatching the delete event.
  Future<void> _confirmDelete(BuildContext context, User user) async {
    // Capture theme values and the bloc before the async gap; the dialog
    // builder runs after `await showDialog` returns, and the post-gap dispatch
    // uses the captured bloc, so nothing here reads across the gap.
    final deleteColor = Theme.of(context).colorScheme.error;
    final bloc = context.read<UserManagementBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete account?'),
          content: Text(
            'This permanently deletes ${user.fullName} (${user.email}). '
            'Their sign-in is revoked and the email is freed to be re-created. '
            'Pets, appointments, and medical records are left intact. '
            'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: deleteColor),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete permanently'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final id = user.id;
    if (id == null) return;
    bloc.add(
      UserManagementDeleteRequested(userId: id),
    );
  }

  void _onSearchChanged(String raw) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: _debounceMs), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = raw.trim().toLowerCase();
        _visibleCount = AppConstants.defaultPageSize;
      });
    });
  }

  List<User> _filteredUsers(List<User> users) {
    var out = users;
    if (_roleFilter != null) {
      out = out.where((u) => u.role == _roleFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      out = out.where((u) =>
        u.fullName.toLowerCase().contains(_searchQuery) ||
        u.email.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BlocListener<UserManagementBloc, UserManagementState>(
      listener: (context, state) {
        if (state is UserManagementActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ThemeColors.success(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else if (state is UserManagementError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: ThemeColors.error(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          final allUsers = switch (state) {
            UserManagementLoaded(:final users) => users,
            UserManagementMutating(:final users) => users,
            _ => const <User>[],
          };
          final isInitialLoading = state is UserManagementLoading && allUsers.isEmpty;
          final isMutating = state is UserManagementMutating;

          return Scaffold(
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
            appBar: AppBar(
              title: const Text('User Management'),
              centerTitle: true,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: SafeArea(
              top: false,
              child: isInitialLoading
                  ? const Center(child: NeuCircularProgress(size: 32, strokeWidth: 3))
                  : _buildContent(context, state, allUsers, isMutating),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, UserManagementState state, List<User> allUsers, bool isMutating) {
    final isLoading = state is UserManagementLoading || state is UserManagementMutating;
    final filtered = _filteredUsers(allUsers);
    final visible = filtered.take(_visibleCount).toList();
    final hasMore = filtered.length > visible.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoading && allUsers.isNotEmpty) ...[
            const Center(child: NeuCircularProgress(size: 20, strokeWidth: 2)),
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
            style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
          ),
          const SizedBox(height: 12),

          NeuCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NeuTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    hint: 'John Doe',
                    keyboardType: TextInputType.name,
                    validator: Validators.requiredWith([Validators.name], 'Full Name'),
                  ),
                  const SizedBox(height: 16),
                  NeuTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.requiredWith([Validators.email], 'Email'),
                  ),
                  const SizedBox(height: 16),
                  NeuTextField(
                    controller: _phoneController,
                    label: 'Phone (Optional)',
                    hint: '09XX XXX XXXX',
                    keyboardType: TextInputType.phone,
                    helper: 'Philippine mobile number (optional)',
                  ),
                  const SizedBox(height: 16),
                  NeuTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Set a starting password',
                    obscureText: true,
                    helper: 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number',
                    validator: Validators.requiredWith([Validators.password], 'Password'),
                  ),
                  const SizedBox(height: 16),
                  NeuTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Confirm the password',
                    obscureText: true,
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

                  Text('Role', style: AppTextStyles.labelLarge),
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

                  NeuButton(
                    text: 'Create Account',
                    onPressed: (isLoading || isMutating) ? null : _onCreatePressed,
                    isLoading: isLoading || isMutating,
                    expanded: true,
                    variant: NeuButtonVariant.primary,
                    size: NeuButtonSize.medium,
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
              Icon(Icons.badge_outlined, color: ThemeColors.textSecondary(context), size: 20),
              const SizedBox(width: 8),
              Text(
                'Staff & Veterinarians',
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (allUsers.isNotEmpty)
                NeuContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  variant: NeuVariant.flat,
                  child: Text(
                    '${filtered.length} of ${allUsers.length}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: ThemeColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          NeuTextField(
            controller: _searchController,
            hint: 'Search by name or email',
            prefixIcon: const Icon(Icons.search_outlined, size: 18),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _visibleCount = AppConstants.defaultPageSize;
                      });
                    },
                    tooltip: 'Clear',
                  )
                : null,
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                NeuChip(
                  label: 'All roles',
                  selected: _roleFilter == null,
                  onTap: () => setState(() {
                    _roleFilter = null;
                    _visibleCount = AppConstants.defaultPageSize;
                  }),
                  selectedColor: ThemeColors.primary(context),
                ),
                const SizedBox(width: 8),
                for (final role in const [UserRole.staff, UserRole.veterinarian, UserRole.petOwner])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: NeuChip(
                      label: role.displayName,
                      selected: _roleFilter == role,
                      onTap: () => setState(() {
                        _roleFilter = _roleFilter == role ? null : role;
                        _visibleCount = AppConstants.defaultPageSize;
                      }),
                      selectedColor: roleColor(context, role),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (allUsers.isEmpty)
            NeuCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.people_outlined, color: ThemeColors.textSecondary(context), size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'No staff or veterinarian accounts yet.',
                    style: AppTextStyles.bodyMedium.subtleOf(Theme.of(context).brightness),
                  ),
                ],
              ),
            )
          else if (filtered.isEmpty)
            NeuCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.search_off_outlined, color: ThemeColors.textSecondary(context), size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'No matches for "${_searchController.text.trim()}"${_roleFilter == null ? '' : ' in ${_roleFilter!.displayName}'}',
                    style: AppTextStyles.bodyMedium.subtleOf(Theme.of(context).brightness),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  NeuButton(
                    text: 'Clear filters',
                    variant: NeuButtonVariant.outline,
                    size: NeuButtonSize.small,
                    onPressed: () {
                      _searchDebounce?.cancel();
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _roleFilter = null;
                        _visibleCount = AppConstants.defaultPageSize;
                      });
                    },
                  ),
                ],
              ),
            )
          else ...[
            ...visible.map((user) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _UserManagementCard(
                    user: user,
                    busy: isLoading || isMutating,
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
                    onDelete: () {
                      if (user.id != null) _confirmDelete(context, user);
                    },
                  ),
                )),
            if (hasMore) ...[
              const SizedBox(height: 4),
              NeuButton(
                text: 'Load more (${filtered.length - visible.length} remaining)',
                variant: NeuButtonVariant.outline,
                size: NeuButtonSize.small,
                icon: Icons.expand_more_rounded,
                onPressed: () => setState(() {
                  _visibleCount = (_visibleCount + AppConstants.defaultPageSize)
                      .clamp(0, filtered.length);
                }),
              ),
            ],
          ],
        ],
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

  Color _color(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (role) {
      UserRole.staff => ThemeColors.textSecondary(context),
      UserRole.veterinarian => AppColors.tertiary,
      UserRole.petOwner => isDark ? AppColors.infoDark : AppColors.info,
      UserRole.admin => ThemeColors.primary(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    return NeuChip(
      label: role.displayName,
      icon: role == UserRole.petOwner ? Icons.person_outline : Icons.medical_services_outlined,
      selected: selected,
      onTap: onTap,
      selectedColor: _color(context),
    );
  }
}

/// A card listing one staff / veterinarian with role + activation controls.
class _UserManagementCard extends StatelessWidget {
  final User user;
  final bool busy;
  final ValueChanged<UserRole> onRoleChanged;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;

  const _UserManagementCard({
    required this.user,
    this.busy = false,
    required this.onRoleChanged,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final role = user.role;
    final primary = user.isActive ? roleColor(context, role) : ThemeColors.textSecondary(context);

    return NeuCard(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      borderColor: primary.withValues(alpha: 0.3),
      borderWidth: 1.2,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: roleColor(context, role).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              role == UserRole.veterinarian ? Icons.medical_services_outlined : Icons.person_outline,
              color: roleColor(context, role),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
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
                  style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  user.isActive ? 'Active' : 'De-activated',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: user.isActive ? ThemeColors.success(context) : ThemeColors.error(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Permanent delete (admin). Requires the explicit confirm
                  // dialog wired in the page; disabled while a mutation runs.
                  IconButton(
                    tooltip: 'Delete account',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: ThemeColors.error(context),
                      size: 20,
                    ),
                    onPressed: busy ? null : onDelete,
                  ),
                  DropdownButton<UserRole>(
                    value: user.role,
                    underline: const SizedBox.shrink(),
                    style: AppTextStyles.labelMedium.copyWith(color: roleColor(context, role)),
                    borderRadius: BorderRadius.circular(12),
                    items: [UserRole.staff, UserRole.veterinarian, UserRole.petOwner]
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r.displayName),
                            ))
                        .toList(),
                    onChanged: (!user.isActive || busy)
                        ? null
                        : (role) {
                            if (role != null && role != user.role) onRoleChanged(role);
                          },
                  ),
                ],
              ),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: user.isActive,
                  activeTrackColor: ThemeColors.success(context),
                  onChanged: busy ? null : (v) => onToggleActive(v),
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
Color roleColor(BuildContext context, UserRole role) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return switch (role) {
    UserRole.staff => ThemeColors.textSecondary(context),
    UserRole.veterinarian => AppColors.tertiary,
    UserRole.petOwner => isDark ? AppColors.infoDark : AppColors.info,
    UserRole.admin => ThemeColors.primary(context),
  };
}
