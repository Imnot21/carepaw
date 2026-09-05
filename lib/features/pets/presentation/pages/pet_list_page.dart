import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/presentation/pages/pet_form_page.dart';
import 'package:carepaw/features/pets/presentation/pages/pet_detail_page.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_loader.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';

/// Page showing the list of user's pets with premium design.
class PetListPage extends StatelessWidget {
  const PetListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }

        final user = authState.user;
        final isVetOrStaff = user.role == UserRole.veterinarian ||
                             user.role == UserRole.staff ||
                             user.role == UserRole.admin;

        if (isVetOrStaff) {
          // Vet/Staff/Admin see all pets
          return BlocProvider(
            create: (context) => PetBloc(
              petRepository: context.read<PetRepository>(),
            )..add(const LoadAllPets()),
            child: const _StaffPetListView(),
          );
        } else {
          // Pet owners see only their pets
          final ownerId = user.id!;
          return BlocProvider(
            create: (context) => PetBloc(
              petRepository: context.read<PetRepository>(),
            )..add(LoadPets(ownerId: ownerId)),
            child: _PetListView(ownerId: ownerId),
          );
        }
      },
    );
  }
}

class _NotLoggedInView extends StatelessWidget {
  const _NotLoggedInView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Pets'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: AnimatedGradientBackground(
        colors: [
          AppColors.primary.withValues(alpha: 0.06),
          AppColors.tertiary.withValues(alpha: 0.04),
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
                      Icons.pets_outlined,
                      size: 80,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Please log in to view your pets',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to manage your pets\' profiles and book appointments',
                  style: AppTextStyles.bodyLarge.subtle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                CpButton(
                  text: 'Go to Login',
                  onPressed: () => context.push('/login'),
                  variant: ButtonVariant.primary,
                  icon: Icons.login_outlined,
                  size: ButtonSize.large,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetListView extends StatefulWidget {
  final int ownerId;

  const _PetListView({required this.ownerId});

  @override
  State<_PetListView> createState() => _PetListViewState();
}

class _PetListViewState extends State<_PetListView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('My Pets'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CpIconButton(
              icon: Icons.add,
              onPressed: () => _navigateToAddPet(context),
              tooltip: 'Add Pet',
              size: 24,
            ),
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        colors: [
          AppColors.primary.withValues(alpha: 0.04),
          AppColors.tertiary.withValues(alpha: 0.02),
        ],
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _SearchField(
                initialValue: _searchQuery,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  if (value.isEmpty) {
                    context.read<PetBloc>().add(LoadPets(ownerId: widget.ownerId));
                  } else {
                    context.read<PetBloc>().add(
                      SearchPets(ownerId: widget.ownerId, query: value),
                    );
                  }
                },
                onClear: () {
                  setState(() => _searchQuery = '');
                  context.read<PetBloc>().add(LoadPets(ownerId: widget.ownerId));
                },
              ),
            ),

            // Pets list
            Expanded(
              child: BlocConsumer<PetBloc, PetState>(
                listener: (context, state) {
                  if (state is PetError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.failure.message),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  } else if (state is PetOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is PetLoading) {
                    return const Center(child: CpLoader());
                  }

                  if (state is PetsLoaded) {
                    final pets = state.pets;

                    if (pets.isEmpty) {
                      return _EmptyPetsView(onAddPet: () => _navigateToAddPet(context));
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<PetBloc>().add(LoadPets(ownerId: widget.ownerId));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          return FloatingAnimation(
                            delay: Duration(milliseconds: 50 * index),
                            child: _PetCard(
                              pet: pet,
                              onTap: () => _navigateToPetDetail(context, pet),
                              onEdit: () => _navigateToEditPet(context, pet),
                              onDelete: () => _showDeleteConfirmation(context, pet),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  if (state is PetOperationSuccess) {
                    context.read<PetBloc>().add(LoadPets(ownerId: widget.ownerId));
                    return const Center(child: CpLoader());
                  }

                  return const _EmptyPetsView(onAddPet: null);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddPet(BuildContext context) {
    final petBloc = context.read<PetBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetFormPage(ownerId: widget.ownerId),
      ),
    ).then((_) {
      if (mounted) {
        petBloc.add(LoadPets(ownerId: widget.ownerId));
      }
    });
  }

  void _navigateToPetDetail(BuildContext context, Pet pet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetDetailPage(pet: pet),
      ),
    );
  }

  void _navigateToEditPet(BuildContext context, Pet pet) {
    final petBloc = context.read<PetBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetFormPage(ownerId: widget.ownerId, pet: pet),
      ),
    ).then((_) {
      if (mounted) {
        petBloc.add(LoadPets(ownerId: widget.ownerId));
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${pet.name}?'),
        content: Text(
          'Are you sure you want to delete ${pet.name}? '
          'This action can be undone by restoring the pet.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CpButton(
            text: 'Delete',
            variant: ButtonVariant.destructive,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PetBloc>().add(DeletePet(petId: pet.id!));
            },
            icon: Icons.delete,
            size: ButtonSize.medium,
          ),
        ],
      ),
    );
  }
}

/// Search field widget with premium styling
class _SearchField extends StatelessWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.initialValue,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      blur: 15,
      gradient: LinearGradient(
        colors: [
          isDark ? AppColors.surfaceDark.withValues(alpha: 0.7) : AppColors.surface.withValues(alpha: 0.7),
          isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : AppColors.surface.withValues(alpha: 0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
      child: TextField(
        controller: TextEditingController.fromValue(
          TextEditingValue(
            text: initialValue,
            selection: TextSelection.collapsed(offset: initialValue.length),
          ),
        ),
        decoration: InputDecoration(
          hintText: 'Search pets...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 24),
          suffixIcon: initialValue.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: onClear,
                  tooltip: 'Clear search',
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintStyle: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textHint,
          ),
        ),
        style: AppTextStyles.bodyLarge,
        onChanged: onChanged,
      ),
    );
  }
}

/// Individual pet card with premium design
class _PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PetCard({
    required this.pet,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final speciesIcon = PetUtils.getSpeciesIcon(pet.species);
    final speciesColor = PetUtils.getSpeciesColor(pet.species);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleOnTap(
        onTap: onTap,
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          blur: 15,
          gradient: LinearGradient(
            colors: [
              isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : AppColors.surface.withValues(alpha: 0.8),
              isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : AppColors.surface.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: !pet.isActive
              ? AppColors.warning.withValues(alpha: 0.4)
              : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
          borderWidth: !pet.isActive ? 2 : 1,
          child: Row(
            children: [
              // Pet avatar with glow
              PulsingGlow(
                glowColor: speciesColor,
                maxRadius: 16,
                duration: const Duration(seconds: 4),
                child: PetUtils.buildAvatar(
                  species: pet.species,
                  avatarUrl: pet.avatarUrl,
                  radius: 40,
                  iconSize: 40,
                ),
              ),
              const SizedBox(width: 16),

              // Pet info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.name,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!pet.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Inactive',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Species and breed
                    Row(
                      children: [
                        Icon(
                          speciesIcon,
                          size: 16,
                          color: speciesColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          PetUtils.formatSpecies(pet.species) +
                              (pet.breed != null ? ' • ${pet.breed}' : ''),
                          style: AppTextStyles.bodyMedium.subtle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Age and weight row
                    Row(
                      children: [
                        if (pet.birthDate != null) ...[
                          Icon(
                            Icons.cake_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            PetUtils.calculateAge(pet.birthDate!),
                            style: AppTextStyles.bodyMedium.subtle,
                          ),
                        ],
                        if (pet.birthDate != null && pet.weightKg != null) ...[
                          const SizedBox(width: 16),
                        ],
                        if (pet.weightKg != null) ...[
                          Icon(
                            Icons.monitor_weight_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${pet.weightKg!.toStringAsFixed(1)} kg',
                            style: AppTextStyles.bodyMedium.subtle,
                          ),
                        ],
                      ],
                    ),
                    // Microchip indicator
                    if (pet.microchipId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.nfc_outlined,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Microchipped',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action menu - simplified
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                child: GlassContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(8),
                  blur: 10,
                  child: Icon(Icons.more_vert, size: 22, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty pets view - friendly and inviting
class _EmptyPetsView extends StatelessWidget {
  final VoidCallback? onAddPet;

  const _EmptyPetsView({this.onAddPet});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulsingGlow(
              glowColor: AppColors.primary,
              maxRadius: 40,
              duration: const Duration(seconds: 3),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(90),
                  boxShadow: PremiumShadows.primary,
                ),
                child: Icon(
                  Icons.pets_outlined,
                  size: 90,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No Pets Yet',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first pet to get started with CarePaw.\nYou\'ll be able to book appointments, track health,\nand manage their medical records.',
              style: AppTextStyles.bodyLarge.subtle.copyWith(
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onAddPet != null)
              CpButton(
                text: 'Add Your First Pet',
                onPressed: onAddPet,
                variant: ButtonVariant.primary,
                icon: Icons.add,
                size: ButtonSize.large,
              ),
          ],
        ),
      ),
    );
  }
}

/// Staff pet list view - for vets/staff/admins to see all pets
class _StaffPetListView extends StatefulWidget {
  const _StaffPetListView();

  @override
  State<_StaffPetListView> createState() => _StaffPetListViewState();
}

class _StaffPetListViewState extends State<_StaffPetListView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('All Pets'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CpIconButton(
              icon: Icons.add,
              onPressed: () => _navigateToAddPet(context),
              tooltip: 'Add Pet',
              size: 24,
            ),
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        colors: [
          AppColors.primary.withValues(alpha: 0.04),
          AppColors.tertiary.withValues(alpha: 0.02),
        ],
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _SearchField(
                initialValue: _searchQuery,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  if (value.isEmpty) {
                    context.read<PetBloc>().add(const LoadAllPets());
                  } else {
                    context.read<PetBloc>().add(
                      SearchAllPets(query: value),
                    );
                  }
                },
                onClear: () {
                  setState(() => _searchQuery = '');
                  context.read<PetBloc>().add(const LoadAllPets());
                },
              ),
            ),

            // Pets list
            Expanded(
              child: BlocConsumer<PetBloc, PetState>(
                listener: (context, state) {
                  if (state is PetError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.failure.message),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  } else if (state is PetOperationSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is PetLoading) {
                    return const Center(child: CpLoader());
                  }

                  if (state is PetsLoaded) {
                    final pets = state.pets;

                    if (pets.isEmpty) {
                      return _EmptyPetsView(onAddPet: () => _navigateToAddPet(context));
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        context.read<PetBloc>().add(const LoadAllPets());
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          return FloatingAnimation(
                            delay: Duration(milliseconds: 50 * index),
                            child: _StaffPetCard(
                              pet: pet,
                              onTap: () => _navigateToPetDetail(context, pet),
                              onEdit: () => _navigateToEditPet(context, pet),
                              onDelete: () => _showDeleteConfirmation(context, pet),
                            ),
                          );
                        },
                      ),
                    );
                  }

                  if (state is PetOperationSuccess) {
                    context.read<PetBloc>().add(const LoadAllPets());
                    return const Center(child: CpLoader());
                  }

                  return const _EmptyPetsView(onAddPet: null);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddPet(BuildContext context) {
    final petBloc = context.read<PetBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetFormPage(ownerId: 0), // Will be set in form for staff
      ),
    ).then((_) {
      if (mounted) {
        petBloc.add(const LoadAllPets());
      }
    });
  }

  void _navigateToPetDetail(BuildContext context, Pet pet) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetDetailPage(pet: pet),
      ),
    );
  }

  void _navigateToEditPet(BuildContext context, Pet pet) {
    final petBloc = context.read<PetBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetFormPage(ownerId: pet.ownerId, pet: pet),
      ),
    ).then((_) {
      if (mounted) {
        petBloc.add(const LoadAllPets());
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${pet.name}?'),
        content: Text(
          'Are you sure you want to delete ${pet.name}? '
          'This action can be undone by restoring the pet.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          CpButton(
            text: 'Delete',
            variant: ButtonVariant.destructive,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PetBloc>().add(DeletePet(petId: pet.id!));
            },
            icon: Icons.delete,
            size: ButtonSize.medium,
          ),
        ],
      ),
    );
  }
}

/// Staff pet card with owner info
class _StaffPetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffPetCard({
    required this.pet,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final speciesIcon = PetUtils.getSpeciesIcon(pet.species);
    final speciesColor = PetUtils.getSpeciesColor(pet.species);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ScaleOnTap(
        onTap: onTap,
        child: GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(16),
          blur: 15,
          gradient: LinearGradient(
            colors: [
              isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : AppColors.surface.withValues(alpha: 0.8),
              isDark ? AppColors.surfaceDark.withValues(alpha: 0.6) : AppColors.surface.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: !pet.isActive
              ? AppColors.warning.withValues(alpha: 0.4)
              : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
          borderWidth: !pet.isActive ? 2 : 1,
          child: Row(
            children: [
              // Pet avatar with glow
              PulsingGlow(
                glowColor: speciesColor,
                maxRadius: 16,
                duration: const Duration(seconds: 4),
                child: PetUtils.buildAvatar(
                  species: pet.species,
                  avatarUrl: pet.avatarUrl,
                  radius: 40,
                  iconSize: 40,
                ),
              ),
              const SizedBox(width: 16),

              // Pet info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pet.name,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!pet.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Inactive',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Species and breed
                    Row(
                      children: [
                        Icon(
                          speciesIcon,
                          size: 16,
                          color: speciesColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          PetUtils.formatSpecies(pet.species) +
                              (pet.breed != null ? ' • ${pet.breed}' : ''),
                          style: AppTextStyles.bodyMedium.subtle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Owner ID
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Owner ID: ${pet.ownerId}',
                          style: AppTextStyles.bodySmall.subtle,
                        ),
                      ],
                    ),
                    // Age and weight row
                    Row(
                      children: [
                        if (pet.birthDate != null) ...[
                          Icon(
                            Icons.cake_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            PetUtils.calculateAge(pet.birthDate!),
                            style: AppTextStyles.bodyMedium.subtle,
                          ),
                        ],
                        if (pet.birthDate != null && pet.weightKg != null) ...[
                          const SizedBox(width: 16),
                        ],
                        if (pet.weightKg != null) ...[
                          Icon(
                            Icons.monitor_weight_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${pet.weightKg!.toStringAsFixed(1)} kg',
                            style: AppTextStyles.bodyMedium.subtle,
                          ),
                        ],
                      ],
                    ),
                    // Microchip indicator
                    if (pet.microchipId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.nfc_outlined,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Microchipped',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
                child: GlassContainer(
                  borderRadius: 12,
                  padding: const EdgeInsets.all(8),
                  blur: 10,
                  child: Icon(Icons.more_vert, size: 22, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}