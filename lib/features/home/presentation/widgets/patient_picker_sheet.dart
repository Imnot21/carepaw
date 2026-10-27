import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/di/dependency_injection.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_progress.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/users/domain/repositories/user_repository.dart';

/// Shows the patient picker for the records entry point.
///
/// Records exist per pet, so the operator picks the patient first; the sheet
/// resolves to the chosen pet's id, or `null` when dismissed.
Future<int?> showPatientPicker(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  if (authState is! AuthAuthenticated || authState.user.id == null) {
    return Future<int?>.value();
  }
  final user = authState.user;
  final ownerId = user.id!;
  // The clinic operator reads every patient's records, so the picker lists
  // all patients; pet owners only pick from their own pets.
  final seesAllPatients = user.isOwnerAdmin;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider(
      create: (_) => PetBloc(petRepository: getIt<PetRepository>())
        ..add(
          seesAllPatients ? const LoadAllPets() : LoadPets(ownerId: ownerId),
        ),
      child: _PatientPickerSheet(
        ownerId: ownerId,
        seesAllPatients: seesAllPatients,
      ),
    ),
  );
}

class _PatientPickerSheet extends StatefulWidget {
  final int ownerId;

  /// When true (clinic operator) the sheet lists every patient rather than
  /// only the signed-in user's pets.
  final bool seesAllPatients;

  const _PatientPickerSheet({
    required this.ownerId,
    required this.seesAllPatients,
  });

  @override
  State<_PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends State<_PatientPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  /// Owner names by user id, so pets that share a name can be told apart.
  /// Only loaded for the clinic operator, who sees every owner's pets.
  Map<int, String> _ownerNames = const {};

  @override
  void initState() {
    super.initState();
    if (widget.seesAllPatients) _loadOwnerNames();
  }

  Future<void> _loadOwnerNames() async {
    try {
      final owners = await getIt<UserRepository>().findByRole(
        UserRole.petOwner,
      );
      if (!mounted) return;
      setState(() {
        _ownerNames = {
          for (final owner in owners)
            if (owner.id != null) owner.id!: owner.fullName,
        };
      });
    } catch (e) {
      // The list still works without owner names; search falls back to pets.
      debugPrint('[patient_picker] owner names unavailable: $e');
    }
  }

  /// Operator search matches the pet's name, its owner's name, or markings.
  bool _matches(Pet pet) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    final owner = _ownerNames[pet.ownerId] ?? '';
    final markings = pet.markings ?? '';
    return pet.name.toLowerCase().contains(query) ||
        owner.toLowerCase().contains(query) ||
        markings.toLowerCase().contains(query);
  }

  void _reloadPatients() {
    context.read<PetBloc>().add(
      widget.seesAllPatients
          ? const LoadAllPets()
          : LoadPets(ownerId: widget.ownerId),
    );
  }

  void _searchPatients(String query) {
    context.read<PetBloc>().add(
      widget.seesAllPatients
          ? SearchAllPets(query: query)
          : SearchPets(ownerId: widget.ownerId, query: query),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: NeuContainer(
        margin: const EdgeInsets.all(20),
        borderRadius: NeuTokens.radiusMd,
        variant: NeuVariant.raised,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'View patient records',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a patient to open their records.',
              style: AppTextStyles.bodySmall.subtleOf(
                Theme.of(context).brightness,
              ),
            ),
            const SizedBox(height: 20),
            NeuTextField(
              controller: _searchController,
              hint: widget.seesAllPatients
                  ? 'Search pet or owner name...'
                  : 'Search patients...',
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
                        _reloadPatients();
                      },
                      tooltip: 'Clear search',
                    )
                  : null,
              onChanged: (value) {
                setState(() => _searchQuery = value);
                // The operator list is filtered locally so owner names match.
                if (widget.seesAllPatients) return;
                if (value.isEmpty) {
                  _reloadPatients();
                } else {
                  _searchPatients(value);
                }
              },
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: BlocBuilder<PetBloc, PetState>(
                builder: (context, state) {
                  if (state is PetsLoaded) {
                    final pets = widget.seesAllPatients
                        ? state.pets.where(_matches).toList()
                        : state.pets;
                    if (pets.isEmpty) {
                      return _PickerMessage(
                        title: _searchQuery.isEmpty
                            ? 'No patients yet'
                            : 'No matches',
                        detail: _searchQuery.isEmpty
                            ? 'Patients you add will appear here.'
                            : widget.seesAllPatients
                            ? 'Try a pet name or an owner name.'
                            : 'Try a different name.',
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        return _PatientRow(
                          pet: pet,
                          ownerName: _ownerNames[pet.ownerId],
                          onTap: () => Navigator.of(context).pop(pet.id),
                        );
                      },
                    );
                  }

                  if (state is PetError) {
                    return SizedBox(
                      height: 160,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.failure.message,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.subtleOf(
                                Theme.of(context).brightness,
                              ),
                            ),
                            const SizedBox(height: NeuTokens.spaceSm),
                            NeuButton(
                              text: 'Try Again',
                              variant: NeuButtonVariant.secondary,
                              onPressed: _reloadPatients,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return const SizedBox(
                    height: 160,
                    child: Center(child: NeuCircularProgress()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerMessage extends StatelessWidget {
  final String title;
  final String detail;

  const _PickerMessage({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: NeuTokens.spaceXs),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.subtleOf(
                Theme.of(context).brightness,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientRow extends StatelessWidget {
  final Pet pet;

  /// Shown under the pet so same-name patients are distinguishable.
  final String? ownerName;
  final VoidCallback onTap;

  const _PatientRow({required this.pet, this.ownerName, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final breed = pet.breed;
    final subtitle = breed == null || breed.isEmpty
        ? PetUtils.formatSpecies(pet.species)
        : '${PetUtils.formatSpecies(pet.species)} • $breed';
    final owner = ownerName;
    final ownerLine = owner == null || owner.isEmpty ? null : 'Owner: $owner';

    return Padding(
      padding: const EdgeInsets.only(bottom: NeuTokens.tightGap),
      child: NeuCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          horizontal: NeuTokens.spaceMd,
          vertical: NeuTokens.spaceSm,
        ),
        child: Row(
          children: [
            PetUtils.buildAvatar(
              species: pet.species,
              avatarUrl: pet.avatarUrl,
              radius: 24,
            ),
            const SizedBox(width: NeuTokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ThemeColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.subtleOf(
                      Theme.of(context).brightness,
                    ),
                  ),
                  if (ownerLine != null)
                    Text(
                      ownerLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.subtleOf(
                        Theme.of(context).brightness,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: NeuTokens.spaceXs),
            const NeuSvgIcon(SvgIcons.chevronRight, size: 24),
          ],
        ),
      ),
    );
  }
}
