import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:carepaw/features/inventory/presentation/pages/inventory_form_page.dart';
import 'package:carepaw/features/inventory/presentation/pages/inventory_detail_page.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/utils/formatters.dart';

/// Inventory list page with neumorphic design.
class InventoryListPage extends StatefulWidget {
  const InventoryListPage({super.key});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
  final _searchController = TextEditingController();
  InventoryCategory? _selectedCategory;
  String _searchQuery = '';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

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
          backgroundColor: _isDark
              ? AppColors.backgroundDark
              : AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildFilterSection(),
              _buildInventoryList(),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Item'),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
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
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
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
                color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your clinic supplies',
              style: AppTextStyles.bodySmall.copyWith(
                color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: NeuIconButton(
            icon: Icons.filter_list_rounded,
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: NeuCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeuTextField(
                controller: _searchController,
                hint: 'Search inventory...',
                prefixIcon: const Icon(Icons.search_rounded),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildCategoryChip(null, 'All'),
                    ),
                    ...InventoryCategory.values.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(cat, cat.displayName),
                        )),
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
    return NeuChip(
      label: label,
      selected: isSelected,
      onTap: () => _onCategoryChanged(category),
      selectedColor: AppColors.primary,
    );
  }

  Widget _buildInventoryList() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: NeuSkeletonList(),
          );
        }

        if (state is InventoryError) {
          return SliverFillRemaining(
            child: _NeuEmptyState(
              icon: Icons.error_outline_rounded,
              iconColor: ThemeColors.error(context),
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
            child: _NeuEmptyState(
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
    final statusColor = isOutOfStock
        ? ThemeColors.error(context)
        : isLowStock
            ? ThemeColors.warning(context)
            : _getCategoryColor(item.category);

    return NeuCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      onTap: () => _navigateToDetail(item),
      child: Row(
        children: [
          // Category icon
          SizedBox(
            width: 56,
            height: 56,
            child: NeuContainer(
              borderRadius: 14,
              variant: NeuVariant.raised,
              color: _getCategoryColor(item.category),
              boxShadow: isLowStock || isOutOfStock
                  ? NeuShadow.color(context, statusColor, blur: 16, opacity: 0.35)
                  : NeuShadow.color(context, _getCategoryColor(item.category), blur: 12, opacity: 0.28),
              child: Icon(
                _getCategoryIcon(item.category),
                size: 28,
                color: AppColors.textOnPrimary,
              ),
            ),
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
                          color: _isDark
                              ? AppColors.textPrimaryOnDark
                              : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOutOfStock)
                      _buildStatusBadge('Out of Stock', ThemeColors.error(context))
                    else if (isLowStock)
                      _buildStatusBadge('Low Stock', ThemeColors.warning(context))
                    else if (item.isAtMax)
                      _buildStatusBadge('Full', ThemeColors.success(context)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category.displayName} • ${item.unit}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: _isDark
                        ? AppColors.textSecondaryOnDark
                        : AppColors.textSecondary,
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
                                  color: _isDark
                                      ? AppColors.textSecondaryOnDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                formatNumber(item.currentStock),
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isOutOfStock
                                      ? ThemeColors.error(context)
                                      : isLowStock
                                          ? ThemeColors.warning(context)
                                          : (_isDark
                                              ? AppColors.textPrimaryOnDark
                                              : AppColors.textPrimary),
                                ),
                              ),
                              Text(
                                ' ${item.unit}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: _isDark
                                      ? AppColors.textSecondaryOnDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          if (item.maxStock != null) ...[
                            const SizedBox(height: 6),
                            NeuProgress(
                              value: (stockPercentage / 100).clamp(0.0, 1.0),
                              height: 6,
                              color: statusColor,
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
                              ? (_isDark ? AppColors.errorOnDark : AppColors.error)
                              : isLowStock
                                  ? (_isDark ? AppColors.warningOnDark : AppColors.warning)
                                  : ThemeColors.primary(context),
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
            color: _isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
            size: 24,
          ),
        ],
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

  Color _getCategoryColor(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.medicine:
        return AppColors.categoryMedicine;
      case InventoryCategory.vaccine:
        return AppColors.categoryVaccine;
      case InventoryCategory.supply:
        return AppColors.categorySupply;
      case InventoryCategory.equipment:
        return AppColors.categoryEquipment;
      case InventoryCategory.food:
        return AppColors.categoryFood;
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
      if (!mounted) return;
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
      if (!mounted) return;
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
      builder: (context) => NeuContainer(
        margin: const EdgeInsets.all(20),
        borderRadius: 24,
        variant: NeuVariant.raised,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Filter Inventory',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ...InventoryCategory.values.map((cat) => ListTile(
                  leading: Icon(_getCategoryIcon(cat),
                      color: _getCategoryColor(cat)),
                  title: Text(
                    cat.displayName,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _isDark
                          ? AppColors.textPrimaryOnDark
                          : AppColors.textPrimary,
                    ),
                  ),
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
              leading: Icon(Icons.clear_all_rounded,
                  color: _isDark
                      ? AppColors.textSecondaryOnDark
                      : AppColors.textSecondary),
              title: Text(
                'Clear Filters',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: _isDark
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
              ),
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
    );
  }
}

/// Not logged in view
class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: NeuContainer(
                  borderRadius: 80,
                  variant: NeuVariant.raised,
                  color: AppColors.primary,
                  boxShadow: NeuShadow.color(context, AppColors.primary, blur: 24, opacity: 0.35),
                  child: const Icon(
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
                  color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to access inventory management',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Log In',
                onPressed: () => context.go('/login'),
                icon: Icons.login_rounded,
                size: NeuButtonSize.medium,
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: NeuContainer(
                  borderRadius: 80,
                  variant: NeuVariant.raised,
                  color: AppColors.error,
                  boxShadow: NeuShadow.color(context, AppColors.error, blur: 24, opacity: 0.35),
                  child: const Icon(
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
                  color: ThemeColors.error(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Only veterinarians and clinic staff can manage inventory.\n\nThis feature is for clinic operations only.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Go Back',
                onPressed: () => context.pop(),
                icon: Icons.arrow_back_rounded,
                variant: NeuButtonVariant.secondary,
                size: NeuButtonSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Neumorphic empty state.
class _NeuEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const _NeuEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? ThemeColors.primary(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: NeuContainer(
                borderRadius: 60,
                variant: NeuVariant.raised,
                color: color.withValues(alpha: 0.14),
                boxShadow: NeuShadow.color(context, color, blur: 20, opacity: 0.18),
                child: Icon(icon, size: 56, color: color),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              NeuButton(
                text: actionLabel!,
                onPressed: onAction,
                variant: NeuButtonVariant.primary,
                icon: Icons.add_rounded,
                size: NeuButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}