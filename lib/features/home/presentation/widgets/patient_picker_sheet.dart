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
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';

/// Shows the patient picker for the records entry point.
///
/// Records exist per pet, so the operator picks the patient first; the sheet
/// resolves to the chosen pet's id, or `null` when dismissed.
Future<int?> showPatientPicker(BuildContext context) {
  final authState = context.read<AuthBloc>().state;
  if (authState is! AuthAuthenticated || authState.user.id == null) {
    return Future<int?>.value();
  }
  final ownerId = authState.user.id!;
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider(
      create: (_) =>
          PetBloc(petRepository: getIt<PetRepository>())
            ..add(LoadPets(ownerId: ownerId)),
      child: _PatientPickerSheet(ownerId: ownerId),
    ),
  );
}

class _PatientPickerSheet extends StatefulWidget {
  final int ownerId;

  const _PatientPickerSheet({required this.ownerId});

  @override
  State<_PatientPickerSheet> createState() => _PatientPickerSheetState();
}

class _PatientPickerSheetState extends State<_PatientPickerSheet> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
        borderRadius: 24,
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
              hint: 'Search patients...',
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
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: BlocBuilder<PetBloc, PetState>(
                builder: (context, state) {
                  if (state is PetsLoaded) {
                    final pets = state.pets;
                    if (pets.isEmpty) {
                      return _PickerMessage(
                        title: _searchQuery.isEmpty
                            ? 'No patients yet'
                            : 'No matches',
                        detail: _searchQuery.isEmpty
                            ? 'Patients you add will appear here.'
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
                              onPressed: () => context.read<PetBloc>().add(
                                LoadPets(ownerId: widget.ownerId),
                              ),
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
  final VoidCallback onTap;

  const _PatientRow({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final breed = pet.breed;
    final subtitle = breed == null || breed.isEmpty
        ? PetUtils.formatSpecies(pet.species)
        : '${PetUtils.formatSpecies(pet.species)} • $breed';

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
