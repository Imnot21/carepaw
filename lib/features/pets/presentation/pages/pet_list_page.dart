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
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Page showing the list of user's pets with neumorphic design.
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
                  boxShadow: NeuShadow.color(context, AppColors.primary, blur: 24, opacity: 0.32),
                  child: const Icon(
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
                  color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your pets\' profiles and book appointments',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Go to Login',
                onPressed: () => context.push('/login'),
                variant: NeuButtonVariant.primary,
                icon: Icons.login_outlined,
                size: NeuButtonSize.large,
                expanded: true,
              ),
            ],
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
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('My Pets'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NeuIconButton(
              icon: Icons.add,
              onPressed: () => _navigateToAddPet(context),
              tooltip: 'Add Pet',
              size: 22,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: NeuTextField(
              controller: _searchController,
              hint: 'Search pets...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        context.read<PetBloc>().add(LoadPets(ownerId: widget.ownerId));
                      },
                      tooltip: 'Clear search',
                    )
                  : null,
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
                  return const Center(child: NeuCircularProgress());
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        return _PetCard(
                          pet: pet,
                          onTap: () => _navigateToPetDetail(context, pet),
                          onEdit: () => _navigateToEditPet(context, pet),
                          onDelete: () => _showDeleteConfirmation(context, pet),
                        );
                      },
                    ),
                  );
                }

                if (state is PetOperationSuccess) {
                  context.read<PetBloc>().add(LoadPets(ownerId: widget.ownerId));
                  return const Center(child: NeuCircularProgress());
                }

                return const _EmptyPetsView(onAddPet: null);
              },
            ),
          ),
        ],
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
          NeuButton(
            text: 'Delete',
            variant: NeuButtonVariant.destructive,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PetBloc>().add(DeletePet(petId: pet.id!));
            },
            icon: Icons.delete,
            size: NeuButtonSize.small,
          ),
        ],
      ),
    );
  }
}

/// Individual pet card with neumorphic design
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
      child: NeuCard(
        onTap: onTap,
        borderRadius: 20,
        borderColor: !pet.isActive
            ? AppColors.warning.withValues(alpha: 0.4)
            : null,
        borderWidth: !pet.isActive ? 2 : 0,
        child: Row(
          children: [
            // Pet avatar
            PetUtils.buildAvatar(
              species: pet.species,
              avatarUrl: pet.avatarUrl,
              radius: 40,
              iconSize: 40,
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
                            color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
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
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                        ),
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
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                          ),
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
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                          ),
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
              child: NeuContainer(
                borderRadius: 12,
                padding: const EdgeInsets.all(8),
                variant: NeuVariant.raised,
                child: Icon(Icons.more_vert, size: 22, color: AppColors.textSecondary),
              ),
            ),
          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: NeuContainer(
                borderRadius: 90,
                variant: NeuVariant.raised,
                color: AppColors.primary,
                boxShadow: NeuShadow.color(context, AppColors.primary, blur: 24, opacity: 0.32),
                child: const Icon(
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
                color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your first pet to get started with CarePaw.\nYou\'ll be able to book appointments, track health,\nand manage their medical records.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onAddPet != null)
              NeuButton(
                text: 'Add Your First Pet',
                onPressed: onAddPet,
                variant: NeuButtonVariant.primary,
                icon: Icons.add,
                size: NeuButtonSize.large,
                expanded: true,
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
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('All Pets'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NeuIconButton(
              icon: Icons.add,
              onPressed: () => _navigateToAddPet(context),
              tooltip: 'Add Pet',
              size: 22,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: NeuTextField(
              controller: _searchController,
              hint: 'Search pets...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        context.read<PetBloc>().add(const LoadAllPets());
                      },
                      tooltip: 'Clear search',
                    )
                  : null,
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
                  return const Center(child: NeuCircularProgress());
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
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        return _StaffPetCard(
                          pet: pet,
                          onTap: () => _navigateToPetDetail(context, pet),
                          onEdit: () => _navigateToEditPet(context, pet),
                          onDelete: () => _showDeleteConfirmation(context, pet),
                        );
                      },
                    ),
                  );
                }

                if (state is PetOperationSuccess) {
                  context.read<PetBloc>().add(const LoadAllPets());
                  return const Center(child: NeuCircularProgress());
                }

                return const _EmptyPetsView(onAddPet: null);
              },
            ),
          ),
        ],
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
          NeuButton(
            text: 'Delete',
            variant: NeuButtonVariant.destructive,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<PetBloc>().add(DeletePet(petId: pet.id!));
            },
            icon: Icons.delete,
            size: NeuButtonSize.small,
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
      child: NeuCard(
        onTap: onTap,
        borderRadius: 20,
        borderColor: !pet.isActive
            ? AppColors.warning.withValues(alpha: 0.4)
            : null,
        borderWidth: !pet.isActive ? 2 : 0,
        child: Row(
          children: [
            // Pet avatar
            PetUtils.buildAvatar(
              species: pet.species,
              avatarUrl: pet.avatarUrl,
              radius: 40,
              iconSize: 40,
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
                            color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
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
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                        ),
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
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                        ),
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
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                          ),
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
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                          ),
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
              child: NeuContainer(
                borderRadius: 12,
                padding: const EdgeInsets.all(8),
                variant: NeuVariant.raised,
                child: Icon(Icons.more_vert, size: 22, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}