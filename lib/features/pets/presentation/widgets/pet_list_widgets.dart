import 'package:flutter/material.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_badge.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';

class PetNotLoggedInView extends StatelessWidget {
  const PetNotLoggedInView({super.key});

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
                  color: ThemeColors.primary(context),
                  boxShadow: NeuShadow.color(
                    context,
                    ThemeColors.primary(context),
                    blur: 24,
                    opacity: 0.32,
                  ),
                  child: const NeuSvgIcon(SvgIcons.paw, size: 80),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Please log in to view your pets',
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textPrimaryOnDark
                      : AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage your pets\' profiles and book appointments',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryOnDark
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Go to Login',
                onPressed: () => context.push('/login'),
                variant: NeuButtonVariant.primary,
                icon: Icons.login_outlined,
                svgAsset: SvgIcons.login,
                size: NeuButtonSize.medium,
                expanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetListView extends StatefulWidget {
  final int ownerId;

  const PetListView({super.key, required this.ownerId});

  @override
  State<PetListView> createState() => _PetListViewState();
}

class _PetListViewState extends State<PetListView> {
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
              svgAsset: SvgIcons.add,
              onPressed: () => _navigateToAddPet(context),
              tooltip: 'Add Pet',
              size: 22,
              plain: true,
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
              prefixIcon: ClayIconOrMaterial(
                'search_rounded',
                fallback: Icons.search_rounded,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? NeuIconButton(
                      icon: Icons.clear_rounded,
                      svgAsset: SvgIcons.close,
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        context.read<PetBloc>().add(
                          LoadPets(ownerId: widget.ownerId),
                        );
                      },
                      tooltip: 'Clear search',
                    )
                  : null,
              onChanged: (value) {
                setState(() => _searchQuery = value);
                if (value.isEmpty) {
                  context.read<PetBloc>().add(
                    LoadPets(ownerId: widget.ownerId),
                  );
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
                  NeuToast.error(context, state.failure.message);
                } else if (state is PetOperationSuccess) {
                  NeuToast.success(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is PetLoading) {
                  return const NeuSkeletonList();
                }

                if (state is PetsLoaded) {
                  final pets = state.pets;

                  if (pets.isEmpty) {
                    return _EmptyPetsView(
                      onAddPet: () => _navigateToAddPet(context),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<PetBloc>().add(
                        LoadPets(ownerId: widget.ownerId),
                      );
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
                  context.read<PetBloc>().add(
                    LoadPets(ownerId: widget.ownerId),
                  );
                  return const NeuSkeletonList();
                }

                return _EmptyPetsView(
                  onAddPet: () => _navigateToAddPet(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToAddPet(BuildContext context) {
    final petBloc = context.read<PetBloc>();
    // Use the router route so PetFormPage is wrapped in a BlocProvider<PetBloc>.
    // Pushing PetFormPage directly here would build it without a PetBloc in
    // scope and crash with ProviderNotFoundException.
    context.push(Routes.petAdd).then((_) {
      if (mounted) {
        petBloc.add(LoadPets(ownerId: widget.ownerId));
      }
    });
  }

  void _navigateToPetDetail(BuildContext context, Pet pet) {
    final petId = pet.id;
    if (petId == null) return;
    // Router route (fetch-by-id + deep-linkable) instead of a raw
    // MaterialPageRoute, so back-stack and tab highlight stay consistent.
    context.push('/pets/$petId');
  }

  void _navigateToEditPet(BuildContext context, Pet pet) {
    final petBloc = context.read<PetBloc>();
    // Router route wraps PetFormPage in a BlocProvider<PetBloc>; the edit
    // route loads the pet by ID and pre-fills the form.
    context.push(Routes.petEdit.replaceAll(':id', '${pet.id}')).then((_) {
      if (mounted) {
        petBloc.add(LoadPets(ownerId: widget.ownerId));
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, Pet pet) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Delete ${pet.name}?',
      message:
          'Are you sure you want to delete ${pet.name}? This action can be undone by restoring the pet.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.destructive,
      onConfirm: () => context.read<PetBloc>().add(DeletePet(petId: pet.id!)),
    );
  }
}

/// Individual pet card with the CarePaw surface system
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
    final speciesSvg = PetUtils.getSpeciesSvg(pet.species);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: NeuTokens.tightGap),
      child: NeuCard(
        onTap: onTap,
        showBorder: !pet.isActive,
        borderColor: !pet.isActive ? ThemeColors.warning(context) : null,
        borderWidth: !pet.isActive ? 2 : 0,
        child: Row(
          children: [
            PetUtils.buildAvatar(
              species: pet.species,
              avatarUrl: pet.avatarUrl,
              radius: 36,
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
                            color: isDark
                                ? AppColors.textPrimaryOnDark
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!pet.isActive)
                        const NeuStatusBadge(
                          label: 'Inactive',
                          tone: NeuStatusTone.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Species and breed
                  Row(
                    children: [
                      NeuSvgIcon(speciesSvg, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        PetUtils.formatSpecies(pet.species) +
                            (pet.breed != null ? ' • ${pet.breed}' : ''),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryOnDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Age and weight row
                  Row(
                    children: [
                      if (pet.birthDate != null) ...[
                        const NeuSvgIcon(SvgIcons.cake, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          PetUtils.calculateAge(pet.birthDate!),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryOnDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (pet.birthDate != null && pet.weightKg != null) ...[
                        const SizedBox(width: 16),
                      ],
                      if (pet.weightKg != null) ...[
                        const NeuSvgIcon(SvgIcons.weightScale, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${pet.weightKg!.toStringAsFixed(1)} kg',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryOnDark
                                : AppColors.textSecondary,
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
                        const NeuSvgIcon(SvgIcons.microchip, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Microchipped',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ThemeColors.success(context),
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
                PopupMenuItem(
                  value: 'edit',
                  child: const Row(
                    children: [
                      NeuSvgIcon(SvgIcons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const NeuSvgIcon(SvgIcons.delete, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(color: ThemeColors.error(context)),
                      ),
                    ],
                  ),
                ),
              ],
              child: NeuContainer(
                borderRadius: NeuTokens.radiusSm,
                padding: const EdgeInsets.all(NeuTokens.spaceXs),
                variant: NeuVariant.raised,
                child: const NeuSvgIcon(SvgIcons.more, size: 22),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NeuTokens.pagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              variant: NeuVariant.inset,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(NeuTokens.spaceLg + 12),
              child: const NeuSvgIcon(SvgIcons.paw, size: 56),
            ),
            const SizedBox(height: 28),
            Text(
              'No pets yet',
              style: AppTextStyles.headlineMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: NeuTokens.spaceXs),
            Text(
              // Without an add action this is the clinic's list, which
              // fills as pet owners add their pets in the app.
              onAddPet == null
                  ? 'Patients appear here once pet owners\nadd their pets in the app.'
                  : 'Add your first pet to get started with CarePaw.\nYou\u2019ll be able to book appointments, track health,\nand manage their medical records.',
              style: AppTextStyles.bodyLarge
                  .subtleOf(Theme.of(context).brightness)
                  .copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (onAddPet != null)
              NeuButton(
                text: 'Add Your First Pet',
                onPressed: onAddPet,
                variant: NeuButtonVariant.primary,
                icon: Icons.add,
                svgAsset: SvgIcons.add,
                size: NeuButtonSize.medium,
                expanded: true,
              ),
          ],
        ),
      ),
    );
  }
}

/// Staff pet list view - for vets/staff/admins to see all pets
class StaffPetListView extends StatefulWidget {
  const StaffPetListView({super.key});

  @override
  State<StaffPetListView> createState() => _StaffPetListViewState();
}

class _StaffPetListViewState extends State<StaffPetListView> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  /// Owner names by user id, so pets that share a name can be told apart
  /// (the client's main complaint in Chapter 1).
  Map<int, String> _ownerNames = const {};

  @override
  void initState() {
    super.initState();
    _loadOwnerNames();
  }

  Future<void> _loadOwnerNames() async {
    try {
      final repo = getIt<UserRepository>();
      final results = await Future.wait([
        repo.findByRole(UserRole.petOwner),
        repo.findByRole(UserRole.ownerAdmin),
      ]);
      if (!mounted) return;
      setState(() {
        _ownerNames = {
          for (final user in results.expand((users) => users))
            if (user.id != null) user.id!: user.fullName,
        };
      });
    } catch (e) {
      // The list still works without owner names; search falls back to pets.
      debugPrint('[staff_pet_list] owner names unavailable: $e');
    }
  }

  /// Search matches the pet's name, its owner's name, breed or markings.
  bool _matches(Pet pet) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final owner = _ownerNames[pet.ownerId] ?? '';
    return pet.name.toLowerCase().contains(query) ||
        owner.toLowerCase().contains(query) ||
        (pet.breed ?? '').toLowerCase().contains(query) ||
        (pet.markings ?? '').toLowerCase().contains(query);
  }

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
        // No Add Pet here: Chapter 1 (Pet Profile Management) has pet owners
        // create their pets; the clinic views and searches them.
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: NeuTextField(
              controller: _searchController,
              hint: 'Search pet or owner name...',
              prefixIcon: ClayIconOrMaterial(
                'search_rounded',
                fallback: Icons.search_rounded,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? NeuIconButton(
                      icon: Icons.clear_rounded,
                      svgAsset: SvgIcons.close,
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      tooltip: 'Clear search',
                    )
                  : null,
              // Filtered locally over the loaded list so owner names match.
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Pets list
          Expanded(
            child: BlocConsumer<PetBloc, PetState>(
              listener: (context, state) {
                if (state is PetError) {
                  NeuToast.error(context, state.failure.message);
                } else if (state is PetOperationSuccess) {
                  NeuToast.success(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is PetLoading) {
                  return const NeuSkeletonList();
                }

                if (state is PetsLoaded) {
                  final pets = state.pets.where(_matches).toList();

                  if (state.pets.isEmpty) {
                    return const _EmptyPetsView();
                  }

                  if (pets.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No pet or owner matches "${_searchQuery.trim()}".',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: ThemeColors.textSecondary(context),
                          ),
                        ),
                      ),
                    );
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
                          ownerName: _ownerNames[pet.ownerId],
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
                  return const NeuSkeletonList();
                }

                return const _EmptyPetsView();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPetDetail(BuildContext context, Pet pet) {
    final petId = pet.id;
    if (petId == null) return;
    // Router route (fetch-by-id + deep-linkable) instead of a raw
    // MaterialPageRoute, so back-stack and tab highlight stay consistent.
    context.push('/pets/$petId');
  }

  void _navigateToEditPet(BuildContext context, Pet pet) {
    final petBloc = context.read<PetBloc>();
    context.push(Routes.petEdit.replaceAll(':id', '${pet.id}')).then((_) {
      if (mounted) {
        petBloc.add(const LoadAllPets());
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, Pet pet) {
    NeuConfirmDialog.show(
      context: context,
      title: 'Delete ${pet.name}?',
      message:
          'Are you sure you want to delete ${pet.name}? This action can be undone by restoring the pet.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.destructive,
      onConfirm: () => context.read<PetBloc>().add(DeletePet(petId: pet.id!)),
    );
  }
}

/// Staff pet card with owner info
class _StaffPetCard extends StatelessWidget {
  final Pet pet;

  /// The owner's full name, or null while names load or when unknown.
  final String? ownerName;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffPetCard({
    required this.pet,
    this.ownerName,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final speciesSvg = PetUtils.getSpeciesSvg(pet.species);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeuCard(
        onTap: onTap,
        borderRadius: NeuTokens.radiusMd,
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
                            color: isDark
                                ? AppColors.textPrimaryOnDark
                                : AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!pet.isActive)
                        const NeuStatusBadge(
                          label: 'Inactive',
                          tone: NeuStatusTone.warning,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Species and breed
                  Row(
                    children: [
                      NeuSvgIcon(speciesSvg, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        PetUtils.formatSpecies(pet.species) +
                            (pet.breed != null ? ' • ${pet.breed}' : ''),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryOnDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Owner name, so same-name pets can be told apart
                  Row(
                    children: [
                      const NeuSvgIcon(SvgIcons.person, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ownerName != null && ownerName!.isNotEmpty
                              ? 'Owner: $ownerName'
                              : 'Owner: unknown',
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryOnDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Age and weight row
                  Row(
                    children: [
                      if (pet.birthDate != null) ...[
                        const NeuSvgIcon(SvgIcons.cake, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          PetUtils.calculateAge(pet.birthDate!),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryOnDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (pet.birthDate != null && pet.weightKg != null) ...[
                        const SizedBox(width: 16),
                      ],
                      if (pet.weightKg != null) ...[
                        const NeuSvgIcon(SvgIcons.weightScale, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${pet.weightKg!.toStringAsFixed(1)} kg',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryOnDark
                                : AppColors.textSecondary,
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
                        const NeuSvgIcon(SvgIcons.microchip, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Microchipped',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: ThemeColors.success(context),
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
                      NeuSvgIcon(SvgIcons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const NeuSvgIcon(SvgIcons.delete, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(color: ThemeColors.error(context)),
                      ),
                    ],
                  ),
                ),
              ],
              child: NeuContainer(
                borderRadius: NeuTokens.radiusSm,
                padding: const EdgeInsets.all(NeuTokens.spaceXs),
                variant: NeuVariant.raised,
                child: const NeuSvgIcon(SvgIcons.more, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
