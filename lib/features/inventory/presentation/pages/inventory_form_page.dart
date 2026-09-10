import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Inventory form page with neumorphic design.
class InventoryFormPage extends StatefulWidget {
  final InventoryItem? item;

  const InventoryFormPage({super.key, this.item});

  @override
  State<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _supplierController = TextEditingController();
  final _locationController = TextEditingController();
  InventoryCategory _selectedCategory = InventoryCategory.medicine;
  bool _isLoading = false;

  bool get _isEditing => widget.item != null;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFields(widget.item!);
    }
  }

  void _populateFields(InventoryItem item) {
    _nameController.text = item.name;
    _selectedCategory = item.category;
    _unitController.text = item.unit;
    _minStockController.text = item.minStock.toString();
    _maxStockController.text = item.maxStock?.toString() ?? '';
    _unitCostController.text = item.unitCost?.toString() ?? '';
    _supplierController.text = item.supplier ?? '';
    _locationController.text = item.location ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _unitCostController.dispose();
    _supplierController.dispose();
    _locationController.dispose();
    super.dispose();
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
        return const Color(0xFF6366F1);
      case InventoryCategory.food:
        return const Color(0xFFF59E0B);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark ? AppColors.backgroundDark : AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          _buildForm(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: NeuIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: NeuContainer(
                    borderRadius: 16,
                    variant: NeuVariant.raised,
                    color: _getCategoryColor(_selectedCategory),
                    boxShadow: NeuShadow.color(
                        context, _getCategoryColor(_selectedCategory),
                        blur: 16, opacity: 0.3),
                    child: Icon(
                      _getCategoryIcon(_selectedCategory),
                      size: 32,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isEditing ? 'Edit Item' : 'New Item',
                      style: AppTextStyles.headlineSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _isDark
                            ? AppColors.textPrimaryOnDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEditing
                          ? 'Update inventory details'
                          : 'Add a new inventory item',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _isDark
                            ? AppColors.textSecondaryOnDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category selector
              _buildSectionTitle('Category'),
              const SizedBox(height: 12),
              _buildCategorySelector(),
              const SizedBox(height: 24),

              // Name
              _buildSectionTitle('Item Name'),
              const SizedBox(height: 12),
              NeuTextField(
                controller: _nameController,
                hint: 'Enter item name',
                prefixIcon: const Icon(Icons.inventory_2_rounded),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Item name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Unit & Min Stock
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Unit'),
                        const SizedBox(height: 12),
                        NeuTextField(
                          controller: _unitController,
                          hint: 'e.g., tablets, ml, units',
                          prefixIcon: const Icon(Icons.straighten_rounded),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Unit is required';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Min Stock'),
                        const SizedBox(height: 12),
                        NeuTextField(
                          controller: _minStockController,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.warning_amber_rounded),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Required';
                            }
                            final num = double.tryParse(value);
                            if (num == null || num < 0) {
                              return 'Invalid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Max Stock & Unit Cost
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Max Stock (optional)'),
                        const SizedBox(height: 12),
                        NeuTextField(
                          controller: _maxStockController,
                          hint: 'e.g., 1000',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.flag_rounded),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final num = double.tryParse(value);
                              if (num == null || num < 0) {
                                return 'Invalid number';
                              }
                              final min = double.tryParse(_minStockController.text);
                              if (min != null && num < min) {
                                return 'Must be ≥ min stock';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Unit Cost (optional)'),
                        const SizedBox(height: 12),
                        NeuTextField(
                          controller: _unitCostController,
                          hint: 'e.g., 12.50',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.attach_money_rounded),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final num = double.tryParse(value);
                              if (num == null || num < 0) {
                                return 'Invalid amount';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Supplier & Location
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Supplier (optional)'),
                        const SizedBox(height: 12),
                        NeuTextField(
                          controller: _supplierController,
                          hint: 'Supplier name',
                          prefixIcon: const Icon(Icons.local_shipping_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Location (optional)'),
                        const SizedBox(height: 12),
                        NeuTextField(
                          controller: _locationController,
                          hint: 'Storage location',
                          prefixIcon: const Icon(Icons.location_on_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Preview card
              NeuContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                variant: NeuVariant.raised,
                borderColor:
                    _getCategoryColor(_selectedCategory).withValues(alpha: 0.2),
                borderWidth: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isDark
                            ? AppColors.textSecondaryOnDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: NeuContainer(
                            borderRadius: 12,
                            variant: NeuVariant.raised,
                            color: _getCategoryColor(_selectedCategory),
                            boxShadow: NeuShadow.color(
                                context, _getCategoryColor(_selectedCategory),
                                blur: 12, opacity: 0.28),
                            child: Icon(
                              _getCategoryIcon(_selectedCategory),
                              size: 24,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.isEmpty
                                    ? 'Item Name'
                                    : _nameController.text,
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _isDark
                                      ? AppColors.textPrimaryOnDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${_selectedCategory.displayName} • ${_unitController.text.isEmpty ? 'unit' : _unitController.text}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: _isDark
                                      ? AppColors.textSecondaryOnDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Min: ${_minStockController.text.isEmpty ? '0' : _minStockController.text}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: ThemeColors.warning(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_maxStockController.text.isNotEmpty)
                              Text(
                                'Max: ${_maxStockController.text}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.infoDark
                                      : AppColors.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.labelLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return NeuContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      variant: NeuVariant.raised,
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: InventoryCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return NeuChip(
                label: category.displayName,
                icon: _getCategoryIcon(category),
                selected: isSelected,
                selectedColor: _getCategoryColor(category),
                onTap: () => setState(() => _selectedCategory = category),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: _isDark ? AppColors.surfaceDarkMode : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: _isDark ? AppColors.borderDark : AppColors.border,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: NeuButton(
                text: _isEditing ? 'Cancel' : 'Back',
                variant: NeuButtonVariant.ghost,
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                expanded: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: NeuButton(
                text: _isLoading
                    ? 'Saving...'
                    : (_isEditing ? 'Update Item' : 'Create Item'),
                variant: NeuButtonVariant.primary,
                icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _saveItem,
                expanded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveItem() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final unit = _unitController.text.trim();
    final minStock = double.parse(_minStockController.text);
    final maxStock = _maxStockController.text.isEmpty
        ? null
        : double.parse(_maxStockController.text);
    final unitCost = _unitCostController.text.isEmpty
        ? null
        : double.parse(_unitCostController.text);
    final supplier = _supplierController.text.trim().isEmpty
        ? null
        : _supplierController.text.trim();
    final location = _locationController.text.trim().isEmpty
        ? null
        : _locationController.text.trim();

    if (_isEditing) {
      context.read<InventoryBloc>().add(UpdateInventoryItem(
            id: widget.item!.id!,
            name: name,
            category: _selectedCategory,
            unit: unit,
            minStock: minStock,
            maxStock: maxStock,
            unitCost: unitCost,
            supplier: supplier,
            location: location,
          ));
    } else {
      context.read<InventoryBloc>().add(CreateInventoryItem(
            name: name,
            category: _selectedCategory,
            unit: unit,
            minStock: minStock,
            maxStock: maxStock,
            unitCost: unitCost,
            supplier: supplier,
            location: location,
          ));
    }

    // Listen for success/error
    _listenForResult();
  }

  void _listenForResult() {
    final bloc = context.read<InventoryBloc>();
    late StreamSubscription subscription;
    subscription = bloc.stream.listen((state) {
      if (state is InventoryOperationSuccess) {
        subscription.cancel();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: ThemeColors.success(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context, true);
        }
      } else if (state is InventoryError) {
        subscription.cancel();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: ThemeColors.error(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    });
  }
}