import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:carepaw/features/inventory/presentation/pages/inventory_form_page.dart';
import 'package:carepaw/features/inventory/presentation/pages/inventory_detail_page.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_text_field.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/core/widgets/common/cp_empty_state.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Inventory list page with premium design
class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final _searchController = TextEditingController();
  InventoryCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(const LoadInventoryItems());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    if (query.isEmpty) {
      context.read<InventoryBloc>().add(const LoadInventoryItems());
    } else {
      context.read<InventoryBloc>().add(SearchInventoryItems(query));
    }
  }

  void _onCategoryChanged(InventoryCategory? category) {
    setState(() => _selectedCategory = category);
    if (category == null) {
      context.read<InventoryBloc>().add(const LoadInventoryItems());
    } else {
      context.read<InventoryBloc>().add(LoadInventoryItemsByCategory(category));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }

        // Check if user is vet, staff, or admin - only these roles can manage inventory
        final user = authState.user;
        final isVetOrStaff = user.role == UserRole.veterinarian ||
                            user.role == UserRole.staff ||
                            user.role == UserRole.admin;

        if (!isVetOrStaff) {
          return const _AccessDeniedView();
        }

        return Scaffold(
          body: AnimatedGradientBackground(
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.secondary.withValues(alpha: 0.06),
              AppColors.surface,
            ],
            child: CustomScrollView(
              slivers: [
                _buildAppBar(),
                _buildFilterSection(),
                _buildInventoryList(),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Inventory',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your clinic supplies',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.9),
                AppColors.surface.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.filter_list_rounded),
          onPressed: _showFilterDialog,
          tooltip: 'Filter',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          blur: 15,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CpTextField(
                controller: _searchController,
                hint: 'Search inventory...',
                prefixIcon: const Icon(Icons.search_rounded),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildCategoryChip(null, 'All'),
                    ...InventoryCategory.values.map((cat) =>
                        _buildCategoryChip(cat, cat.displayName)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(InventoryCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onCategoryChanged(category),
        backgroundColor: AppColors.surfaceContainerHighest,
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CpLoader(size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Loading inventory...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is InventoryError) {
          return SliverFillRemaining(
            child: CpEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Error Loading Inventory',
              message: state.failure.message,
              actionLabel: 'Retry',
              onAction: () =>
                  context.read<InventoryBloc>().add(const LoadInventoryItems()),
            ),
          );
        }

        List<InventoryItem> items = [];
        if (state is InventoryItemsLoaded) {
          items = state.items;
        } else if (state is InventoryItemsByCategoryLoaded) {
          items = state.items;
        } else if (state is InventorySearchResultsLoaded) {
          items = state.items;
        } else if (state is LowStockItemsLoaded) {
          items = state.items;
        }

        if (items.isEmpty) {
          return SliverFillRemaining(
            child: CpEmptyState(
              icon: Icons.inventory_2_outlined,
              title: _searchQuery.isNotEmpty
                  ? 'No Results Found'
                  : _selectedCategory != null
                      ? 'No Items in This Category'
                      : 'No Inventory Items',
              message: _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : _selectedCategory != null
                      ? 'Add items to the ${_selectedCategory!.displayName.toLowerCase()} category'
                      : 'Start by adding your first inventory item',
              actionLabel: 'Add Item',
              onAction: _navigateToForm,
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildInventoryCard(item, index);
            },
          ),
        );
      },
    );
  }

  Widget _buildInventoryCard(InventoryItem item, int index) {
    final isLowStock = item.isLowStock;
    final isOutOfStock = item.isOutOfStock;
    final stockPercentage = item.stockPercentage ?? 0;

    return FloatingAnimation(
      delay: Duration(milliseconds: 50 * (index % 10)),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        blur: 10,
        borderColor: isOutOfStock
            ? AppColors.error.withValues(alpha: 0.3)
            : isLowStock
                ? AppColors.warning.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToDetail(item),
          child: Row(
            children: [
              // Category icon with pulsing glow for low stock
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _getCategoryGradient(item.category),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: isLowStock || isOutOfStock
                          ? PremiumShadows.glow(context, isOutOfStock ? AppColors.error : AppColors.warning)
                          : null,
                    ),
                    child: Icon(
                      _getCategoryIcon(item.category),
                      size: 28,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  if (isOutOfStock)
                    PulsingGlow(
                      glowColor: AppColors.error,
                      maxRadius: 32,
                      duration: const Duration(seconds: 2),
                      child: Container(),
                    )
                  else if (isLowStock)
                    PulsingGlow(
                      glowColor: AppColors.warning,
                      maxRadius: 32,
                      duration: const Duration(seconds: 3),
                      child: Container(),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOutOfStock)
                          _buildStatusBadge('Out of Stock', AppColors.error)
                        else if (isLowStock)
                          _buildStatusBadge('Low Stock', AppColors.warning)
                        else if (item.isAtMax)
                          _buildStatusBadge('Full', AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.category.displayName} • ${item.unit}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Stock indicator
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Stock: ',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    formatNumber(item.currentStock),
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isOutOfStock
                                          ? AppColors.error
                                          : isLowStock
                                              ? AppColors.warning
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    ' ${item.unit}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.maxStock != null) ...[
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: stockPercentage / 100,
                                  backgroundColor:
                                      AppColors.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isOutOfStock
                                        ? AppColors.error
                                        : isLowStock
                                            ? AppColors.warning
                                            : AppColors.primary,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  minHeight: 6,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (item.maxStock != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            '${stockPercentage.toInt()}%',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isOutOfStock
                                  ? AppColors.error
                                  : isLowStock
                                      ? AppColors.warning
                                      : AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  LinearGradient _getCategoryGradient(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.medicine:
        return AppColors.gradientPrimary;
      case InventoryCategory.vaccine:
        return const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        );
      case InventoryCategory.supply:
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        );
      case InventoryCategory.equipment:
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
        );
      case InventoryCategory.food:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
    }
  }

  IconData _getCategoryIcon(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.medicine:
        return Icons.medication_rounded;
      case InventoryCategory.vaccine:
        return Icons.vaccines_rounded;
      case InventoryCategory.supply:
        return Icons.inventory_rounded;
      case InventoryCategory.equipment:
        return Icons.precision_manufacturing_rounded;
      case InventoryCategory.food:
        return Icons.restaurant_rounded;
    }
  }

  void _navigateToForm([InventoryItem? item]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryFormPage(item: item),
      ),
    ).then((_) {
      if (_searchQuery.isEmpty && _selectedCategory == null) {
        context.read<InventoryBloc>().add(const LoadInventoryItems());
      }
    });
  }

  void _navigateToDetail(InventoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InventoryDetailPage(item: item),
      ),
    ).then((_) {
      if (_searchQuery.isEmpty && _selectedCategory == null) {
        context.read<InventoryBloc>().add(const LoadInventoryItems());
      }
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        margin: const EdgeInsets.all(20),
        borderRadius: 24,
        blur: 20,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter Inventory',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ...InventoryCategory.values.map((cat) => ListTile(
                    leading: Icon(_getCategoryIcon(cat),
                        color: _getCategoryColor(cat)),
                    title: Text(cat.displayName),
                    trailing: _selectedCategory == cat
                        ? Icon(Icons.check_circle_rounded,
                            color: _getCategoryColor(cat))
                        : null,
                    onTap: () {
                      _onCategoryChanged(cat);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.clear_all_rounded,
                    color: AppColors.textSecondary),
                title: const Text('Clear Filters'),
                onTap: () {
                  _onCategoryChanged(null);
                  _searchController.clear();
                  _onSearchChanged('');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.medicine:
        return AppColors.primary;
      case InventoryCategory.vaccine:
        return const Color(0xFF06B6D4);
      case InventoryCategory.supply:
        return const Color(0xFF8B5CF6);
      case InventoryCategory.equipment:
        return const Color(0xFF6366F1);
      case InventoryCategory.food:
        return const Color(0xFFF59E0B);
    }
  }
}

/// Not logged in view
class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        colors: [
          AppColors.primary.withValues(alpha: 0.08),
          AppColors.secondary.withValues(alpha: 0.06),
          AppColors.surface,
        ],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PulsingGlow(
                  glowColor: AppColors.primary,
                  maxRadius: 40,
                  duration: const Duration(seconds: 3),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(80),
                      boxShadow: PremiumShadows.primary,
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 80,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Please log in to manage inventory',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to access inventory management',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CpButton(
                  text: 'Log In',
                  onPressed: () => context.go('/login'),
                  icon: Icons.login_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Access denied view for pet owners
class _AccessDeniedView extends StatelessWidget {
  const _AccessDeniedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedGradientBackground(
        colors: [
          AppColors.error.withValues(alpha: 0.06),
          AppColors.warning.withValues(alpha: 0.04),
          AppColors.surface,
        ],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PulsingGlow(
                  glowColor: AppColors.error,
                  maxRadius: 40,
                  duration: const Duration(seconds: 3),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientError,
                      borderRadius: BorderRadius.circular(80),
                      boxShadow: PremiumShadows.glow(context, AppColors.error, intensity: 0.3),
                    ),
                    child: Icon(
                      Icons.block_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Access Denied',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Only veterinarians and clinic staff can manage inventory.\n\nThis feature is for clinic operations only.',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CpButton(
                  text: 'Go Back',
                  onPressed: () => context.pop(),
                  icon: Icons.arrow_back_rounded,
                  variant: ButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}