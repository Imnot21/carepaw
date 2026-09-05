import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:carepaw/features/inventory/domain/entities/inventory.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:carepaw/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_text_field.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Inventory form page with premium design
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

  LinearGradient _getCategoryGradient(InventoryCategory category) {
    switch (category) {
      case InventoryCategory.medicine:
        return AppColors.gradientPrimary;
      case InventoryCategory.vaccine:
        return const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
        );
      case InventoryCategory.supply:
        return LinearGradient(
          colors: [AppColors.categorySupply, AppColors.categorySupplyDark],
        );
      case InventoryCategory.equipment:
        return LinearGradient(
          colors: [AppColors.categoryEquipment, AppColors.categoryEquipmentDark],
        );
      case InventoryCategory.food:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        );
    }
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
      body: AnimatedGradientBackground(
        colors: [
          _getCategoryColor(_selectedCategory).withValues(alpha: 0.08),
          AppColors.surface,
        ],
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _buildForm(),
          ],
        ),
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
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(_selectedCategory)
                        .withValues(alpha: 0.3),
                    _getCategoryColor(_selectedCategory)
                        .withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getCategoryColor(_selectedCategory)
                          .withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: _getCategoryGradient(_selectedCategory),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: PremiumShadows.glow(context, _getCategoryColor(_selectedCategory)),
                    ),
                    child: Icon(
                      _getCategoryIcon(_selectedCategory),
                      size: 32,
                      color: AppColors.textOnPrimary,
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
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEditing
                            ? 'Update inventory details'
                            : 'Add a new inventory item',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
              CpTextField(
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
                        CpTextField(
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
                        CpTextField(
                          controller: _minStockController,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.warning_amber_rounded),
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
                        CpTextField(
                          controller: _maxStockController,
                          hint: 'e.g., 1000',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.flag_rounded),
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
                        CpTextField(
                          controller: _unitCostController,
                          hint: 'e.g., 12.50',
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.attach_money_rounded),
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
                        CpTextField(
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
                        CpTextField(
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
              GlassContainer(
                padding: const EdgeInsets.all(16),
                borderRadius: 16,
                blur: 10,
                borderColor:
                    _getCategoryColor(_selectedCategory).withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: _getCategoryGradient(_selectedCategory),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(_selectedCategory),
                            size: 24,
                            color: AppColors.textOnPrimary,
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
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${_selectedCategory.displayName} • ${_unitController.text.isEmpty ? 'unit' : _unitController.text}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
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
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_maxStockController.text.isNotEmpty)
                              Text(
                                'Max: ${_maxStockController.text}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.info,
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
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      blur: 10,
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: InventoryCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? _getCategoryGradient(category)
                        : LinearGradient(
                            colors: [
                              AppColors.surfaceContainerHighest,
                              AppColors.surfaceContainerHighest,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : AppColors.border.withValues(alpha: 0.3),
                    ),
                    boxShadow: isSelected
                        ? PremiumShadows.glow(context, _getCategoryColor(category))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 20,
                        color: isSelected
                            ? AppColors.textOnPrimary
                            : _getCategoryColor(category),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.displayName,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.textOnPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
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
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.2),
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
              child: CpButton(
                text: _isEditing ? 'Cancel' : 'Back',
                variant: ButtonVariant.ghost,
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                expanded: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CpButton(
                text: _isLoading
                    ? 'Saving...'
                    : (_isEditing ? 'Update Item' : 'Create Item'),
                variant: ButtonVariant.primary,
                icon: _isEditing ? Icons.save_rounded : Icons.add_rounded,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _saveItem,
                expanded: true,
                gradient: _getCategoryGradient(_selectedCategory),
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
              backgroundColor: AppColors.success,
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
              backgroundColor: AppColors.error,
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