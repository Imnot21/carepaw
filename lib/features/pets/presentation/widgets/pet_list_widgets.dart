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
import 'package:carepaw/core/widgets/neomorphism/neu_state.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';

class PetNotLoggedInView extends StatelessWidget {
  const PetNotLoggedInView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: NeuEmptyState(
        icon: Icons.pets_rounded,
        svgAsset: SvgIcons.paw,
        title: 'Please log in to view your pets',
        message: "Sign in to manage your pets' profiles and book appointments.",
        actionLabel: 'Go to Login',
        onAction: () => context.push('/login'),
      ),
    );
  }
}

/// Centres a page body and caps its width on wide screens.
class _PetPageBody extends StatelessWidget {
  final Widget child;
  const _PetPageBody({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: NeuTokens.maxContentWidth),
        child: child,
      ),
    );
  }
}

const _listPadding = EdgeInsets.fromLTRB(
  NeuTokens.pagePadding,
  0,
  NeuTokens.pagePadding,
  NeuTokens.sectionGap,
);

/// Waits for the bloc to settle so pull-to-refresh shows its spinner.
Future<void> _refreshPets(BuildContext context, PetEvent event) async {
  final bloc = context.read<PetBloc>()..add(event);
  await bloc.stream
      .firstWhere((s) => s is PetsLoaded || s is PetError)
      .timeout(const Duration(seconds: 15), onTimeout: () => bloc.state);
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

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
    context.read<PetBloc>().add(LoadPets(ownerId: widget.ownerId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: AppBar(
        title: const Text('My pets'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: NeuTokens.spaceXs),
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
      body: _PetPageBody(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NeuTokens.pagePadding,
                NeuTokens.spaceXs,
                NeuTokens.pagePadding,
                NeuTokens.spaceMd,
              ),
              child: NeuTextField(
                controller: _searchController,
                hint: 'Search by name',
                prefixIcon: ClayIconOrMaterial(
                  'search_rounded',
                  fallback: Icons.search_rounded,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? NeuIconButton(
                        icon: Icons.clear_rounded,
                        svgAsset: SvgIcons.close,
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                      )
                    : null,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  if (value.trim().isEmpty) {
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
                  if (state is PetOperationSuccess) {
                    NeuToast.success(context, state.message);
                    // Reload from the listener, not from build.
                    context.read<PetBloc>().add(
                      LoadPets(ownerId: widget.ownerId),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is PetError) {
                    return NeuErrorState(
                      title: 'Could not load pets',
                      message: state.failure.message,
                      onRetry: () => context.read<PetBloc>().add(
                        LoadPets(ownerId: widget.ownerId),
                      ),
                    );
                  }

                  if (state is PetsLoaded) {
                    final pets = state.pets;

                    if (pets.isEmpty) {
                      if (_searchQuery.trim().isNotEmpty) {
                        return NeuEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No pets found',
                          message: 'No pet matches "${_searchQuery.trim()}".',
                          actionLabel: 'Clear search',
                          onAction: _clearSearch,
                        );
                      }
                      return NeuEmptyState(
                        icon: Icons.pets_rounded,
                        svgAsset: SvgIcons.paw,
                        title: 'No pets yet',
                        message:
                            'Add your first pet to book appointments, track health and keep medical records in one place.',
                        actionLabel: 'Add Pet',
                        onAction: () => _navigateToAddPet(context),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => _refreshPets(
                        context,
                        LoadPets(ownerId: widget.ownerId),
                      ),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: _listPadding,
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          return _PetCard(
                            pet: pet,
                            onTap: () => _navigateToPetDetail(context, pet),
                            onEdit: () => _navigateToEditPet(context, pet),
                            onDelete: () =>
                                _showDeleteConfirmation(context, pet),
                          );
                        },
                      ),
                    );
                  }

                  // Initial, loading and operation-success states.
                  return const NeuSkeletonList(padding: _listPadding);
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
    final petBloc = context.read<PetBloc>();
    // Router route (fetch-by-id + deep-linkable) instead of a raw
    // MaterialPageRoute, so back-stack and tab highlight stay consistent.
    // Reload on return: the detail page can change weight or active status.
    context.push('/pets/$petId').then((_) {
      if (mounted) {
        petBloc.add(LoadPets(ownerId: widget.ownerId));
      }
    });
  }

  void _navigateToEditPet(BuildContext context, Pet pet) {
    final petId = pet.id;
    if (petId == null) return;
    final petBloc = context.read<PetBloc>();
    // Router route wraps PetFormPage in a BlocProvider<PetBloc>; the edit
    // route loads the pet by ID and pre-fills the form.
    context.push(Routes.petEdit.replaceAll(':id', '$petId')).then((_) {
      if (mounted) {
        petBloc.add(LoadPets(ownerId: widget.ownerId));
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, Pet pet) {
    final petId = pet.id;
    if (petId == null) return;
    NeuConfirmDialog.show(
      context: context,
      title: 'Delete ${pet.name}?',
      message:
          'Are you sure you want to delete ${pet.name}? This action can be undone by restoring the pet.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmVariant: NeuButtonVariant.destructive,
      onConfirm: () => context.read<PetBloc>().add(DeletePet(petId: petId)),
    );
  }
}

/// Pet card shared by the owner list and the clinic list.
///
/// The clinic list passes [ownerName] and no edit/delete callbacks: the clinic
/// views and searches pets, owners manage them.
class _PetCard extends StatelessWidget {
  final Pet pet;

  /// Staff list only: shown so same-name pets can be told apart.
  final bool showOwner;
  final String? ownerName;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _PetCard({
    required this.pet,
    this.showOwner = false,
    this.ownerName,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final speciesSvg = PetUtils.getSpeciesSvg(pet.species);
    final secondary = AppTextStyles.bodyMedium.copyWith(
      color: ThemeColors.textSecondary(context),
    );
    final speciesBreed =
        PetUtils.formatSpecies(pet.species) +
        (pet.breed != null ? ' • ${pet.breed}' : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: NeuTokens.tightGap),
      child: NeuCard(
        onTap: onTap,
        child: Row(
          children: [
            PetUtils.buildAvatar(
              species: pet.species,
              avatarUrl: pet.avatarUrl,
              radius: 36,
            ),
            const SizedBox(width: NeuTokens.spaceMd),

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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: ThemeColors.textPrimary(context),
                          ),
                        ),
                      ),
                      if (!pet.isActive) ...[
                        const SizedBox(width: NeuTokens.spaceXs),
                        const NeuStatusBadge(
                          label: 'Inactive',
                          tone: NeuStatusTone.warning,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Species and breed
                  Row(
                    children: [
                      NeuSvgIcon(speciesSvg, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          speciesBreed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondary,
                        ),
                      ),
                    ],
                  ),
                  if (showOwner) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const NeuSvgIcon(SvgIcons.person, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            ownerName != null && ownerName!.isNotEmpty
                                ? 'Owner: $ownerName'
                                : 'Owner: unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: ThemeColors.textSecondary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (pet.birthDate != null || pet.weightKg != null) ...[
                    const SizedBox(height: 4),
                    // Age and weight wrap instead of overflowing.
                    Wrap(
                      spacing: NeuTokens.spaceMd,
                      runSpacing: 2,
                      children: [
                        if (pet.birthDate != null)
                          _CardFact(
                            svgAsset: SvgIcons.cake,
                            text: PetUtils.calculateAge(pet.birthDate!),
                            style: secondary,
                          ),
                        if (pet.weightKg != null)
                          _CardFact(
                            svgAsset: SvgIcons.weightScale,
                            text: '${pet.weightKg!.toStringAsFixed(1)} kg',
                            style: secondary,
                          ),
                      ],
                    ),
                  ],
                  // Microchip indicator
                  if (pet.microchipId != null) ...[
                    const SizedBox(height: 4),
                    _CardFact(
                      svgAsset: SvgIcons.microchip,
                      text: 'Microchipped',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ThemeColors.success(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (onEdit != null && onDelete != null) ...[
              const SizedBox(width: NeuTokens.spaceXs),
              _PetActionMenu(onEdit: onEdit!, onDelete: onDelete!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small icon + text fact on a pet card.
class _CardFact extends StatelessWidget {
  final String svgAsset;
  final String text;
  final TextStyle style;

  const _CardFact({
    required this.svgAsset,
    required this.text,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeuSvgIcon(svgAsset, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _PetActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PetActionMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Pet actions',
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              NeuSvgIcon(SvgIcons.edit, size: 20),
              SizedBox(width: NeuTokens.spaceXs),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const NeuSvgIcon(SvgIcons.delete, size: 20),
              const SizedBox(width: NeuTokens.spaceXs),
              Text(
                'Delete',
                style: TextStyle(color: ThemeColors.error(context)),
              ),
            ],
          ),
        ),
      ],
      child: const SizedBox(
        width: NeuTokens.minTapTarget,
        height: NeuTokens.minTapTarget,
        child: Center(
          child: NeuContainer(
            borderRadius: NeuTokens.radiusSm,
            padding: EdgeInsets.all(NeuTokens.spaceXs),
            variant: NeuVariant.raised,
            child: NeuSvgIcon(SvgIcons.more, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Staff pet list view - the clinic's read-only list of every pet.
///
/// No Add Pet and no edit/delete: pet owners create and manage their pets
/// (Chapter 1, Pet Profile Management); the clinic views and searches them.
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

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      appBar: AppBar(
        title: const Text('Patients'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _PetPageBody(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NeuTokens.pagePadding,
                NeuTokens.spaceXs,
                NeuTokens.pagePadding,
                NeuTokens.spaceMd,
              ),
              child: NeuTextField(
                controller: _searchController,
                hint: 'Search by pet or owner',
                prefixIcon: ClayIconOrMaterial(
                  'search_rounded',
                  fallback: Icons.search_rounded,
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? NeuIconButton(
                        icon: Icons.clear_rounded,
                        svgAsset: SvgIcons.close,
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                      )
                    : null,
                // Filtered locally over the loaded list so owner names match.
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),

            // Pets list
            Expanded(
              child: BlocBuilder<PetBloc, PetState>(
                builder: (context, state) {
                  if (state is PetError) {
                    return NeuErrorState(
                      title: 'Could not load patients',
                      message: state.failure.message,
                      onRetry: () =>
                          context.read<PetBloc>().add(const LoadAllPets()),
                    );
                  }

                  if (state is PetsLoaded) {
                    if (state.pets.isEmpty) {
                      return const NeuEmptyState(
                        icon: Icons.pets_rounded,
                        svgAsset: SvgIcons.paw,
                        title: 'No pets yet',
                        message:
                            'Patients appear here once pet owners add their pets in the app.',
                      );
                    }

                    final pets = state.pets.where(_matches).toList();

                    if (pets.isEmpty) {
                      return NeuEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No patients found',
                        message:
                            'No pet or owner matches "${_searchQuery.trim()}".',
                        actionLabel: 'Clear search',
                        onAction: _clearSearch,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          _refreshPets(context, const LoadAllPets()),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: _listPadding,
                        itemCount: pets.length,
                        itemBuilder: (context, index) {
                          final pet = pets[index];
                          return _PetCard(
                            pet: pet,
                            showOwner: true,
                            ownerName: _ownerNames[pet.ownerId],
                            onTap: () => _navigateToPetDetail(context, pet),
                          );
                        },
                      ),
                    );
                  }

                  // Initial and loading states.
                  return const NeuSkeletonList(padding: _listPadding);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPetDetail(BuildContext context, Pet pet) {
    final petId = pet.id;
    if (petId == null) return;
    final petBloc = context.read<PetBloc>();
    // Router route (fetch-by-id + deep-linkable) instead of a raw
    // MaterialPageRoute, so back-stack and tab highlight stay consistent.
    context.push('/pets/$petId').then((_) {
      if (mounted) {
        petBloc.add(const LoadAllPets());
      }
    });
  }
}
