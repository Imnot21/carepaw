import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_bloc.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_event.dart';
import 'package:carepaw/features/medical_records/presentation/bloc/medical_record_state.dart';
import 'package:carepaw/features/medical_records/presentation/utils/medical_record_utils.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/errors/failures.dart';
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

/// Page showing the list of medical records for a pet with premium design.
class MedicalRecordListPage extends StatelessWidget {
  final Pet pet;

  const MedicalRecordListPage({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const _NotLoggedInView();
        }

        final user = authState.user;

        return BlocProvider(
          create: (context) => MedicalRecordBloc(
            medicalRecordRepository: context.read(),
          )..add(LoadMedicalRecords(pet.id!)),
          child: _MedicalRecordListView(pet: pet, currentUser: user),
        );
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
        title: const Text('Medical Records'),
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
                      Icons.medical_information_outlined,
                      size: 80,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Please log in to view medical records',
                  style: AppTextStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign in to access your pet\'s health history',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _MedicalRecordListView extends StatefulWidget {
  final Pet pet;
  final User currentUser;

  const _MedicalRecordListView({
    required this.pet,
    required this.currentUser,
  });

  @override
  State<_MedicalRecordListView> createState() => _MedicalRecordListViewState();
}

class _MedicalRecordListViewState extends State<_MedicalRecordListView> {
  MedicalRecordType? _selectedFilter;
  bool get _isVetOrStaff => widget.currentUser.role == UserRole.veterinarian || widget.currentUser.role == UserRole.staff || widget.currentUser.role == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    final speciesColor = widget.pet.species.accentColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, speciesColor),
      body: AnimatedGradientBackground(
        colors: [
          speciesColor.withValues(alpha: 0.05),
          AppColors.primary.withValues(alpha: 0.03),
        ],
        child: Column(
          children: [
            // Pet header
            _buildPetHeader(context, speciesColor),

            // Filter chips
            _buildFilterChips(context, speciesColor),

            // Records list
            Expanded(
              child: BlocBuilder<MedicalRecordBloc, MedicalRecordState>(
                builder: (context, state) {
                  if (state is MedicalRecordLoading) {
                    return const Center(child: CpLoader(size: 32));
                  } else if (state is MedicalRecordsLoaded) {
                    return _buildRecordsList(context, state.records, speciesColor);
                  } else if (state is MedicalRecordsByTypeLoaded) {
                    return _buildRecordsList(context, state.records, speciesColor);
                  } else if (state is MedicalRecordError) {
                    return _buildErrorState(context, state.failure);
                  } else if (state is MedicalRecordOperationSuccess) {
                    // Success state will be shown briefly then reload
                    return _buildEmptyState(context, speciesColor);
                  }
                  return _buildEmptyState(context, speciesColor);
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isVetOrStaff ? _buildFab(context, speciesColor) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Color speciesColor) {
    return AppBar(
      title: Text(
        '${widget.pet.name}\'s Records',
        style: AppTextStyles.titleLarge.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _showOptionsMenu(context),
        ),
      ],
    );
  }

  Widget _buildPetHeader(BuildContext context, Color speciesColor) {
    return FloatingAnimation(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Row(
          children: [
            // Pet avatar with PulsingGlow
            PulsingGlow(
              glowColor: speciesColor,
              maxRadius: 20,
              duration: const Duration(seconds: 3),
              child: PetUtils.buildAvatar(
                species: widget.pet.species,
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
                  Text(
                    widget.pet.name,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.pet.species.displayName}${widget.pet.breed != null ? ' • ${widget.pet.breed}' : ''}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (widget.pet.ageInYears != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${widget.pet.ageInYears} years old',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Record count badge
            BlocBuilder<MedicalRecordBloc, MedicalRecordState>(
              builder: (context, state) {
                int count = 0;
                if (state is MedicalRecordsLoaded) {
                  count = state.records.length;
                } else if (state is MedicalRecordsByTypeLoaded) {
                  count = state.records.length;
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        speciesColor.withValues(alpha: 0.2),
                        speciesColor.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: speciesColor.withValues(alpha: 0.3),
                    ),
                    boxShadow: PremiumShadows.glow(context, speciesColor, intensity: 0.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        size: 16,
                        color: speciesColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count Records',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: speciesColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, Color speciesColor) {
    final filters = [
      (MedicalRecordType.visit, 'Visits'),
      (MedicalRecordType.vaccination, 'Vaccinations'),
      (MedicalRecordType.surgery, 'Surgeries'),
      (MedicalRecordType.labResult, 'Lab Results'),
      (MedicalRecordType.prescription, 'Prescriptions'),
      (MedicalRecordType.allergy, 'Allergies'),
      (MedicalRecordType.note, 'Notes'),
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length + 1, // +1 for "All"
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // All filter
            final isSelected = _selectedFilter == null;
            return _FilterChip(
              label: 'All',
              isSelected: isSelected,
              onTap: () => setState(() => _selectedFilter = null),
              color: speciesColor,
            );
          }
          final (type, label) = filters[index - 1];
          final isSelected = _selectedFilter == type;
          return _FilterChip(
            label: label,
            isSelected: isSelected,
            onTap: () {
              setState(() => _selectedFilter = type);
              context.read<MedicalRecordBloc>().add(
                LoadMedicalRecordsByType(widget.pet.id!, type),
              );
            },
            color: speciesColor,
          );
        },
      ),
    );
  }

  Widget _buildRecordsList(
    BuildContext context,
    List<MedicalRecord> records,
    Color speciesColor,
  ) {
    if (records.isEmpty) {
      return _buildEmptyState(context, speciesColor);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = records[index];
        return FloatingAnimation(
          delay: Duration(milliseconds: 50 * (index + 1)),
          child: ScaleOnTap(
            onTap: () => _navigateToDetail(context, record),
            child: _MedicalRecordCard(
              record: record,
              speciesColor: speciesColor,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, Color speciesColor) {
    final filterText = _selectedFilter != null
        ? 'No ${_selectedFilter!.displayName.toLowerCase()} records yet'
        : 'No medical records yet';

    final isVetOrStaff = _isVetOrStaff;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    speciesColor.withValues(alpha: 0.2),
                    speciesColor.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(70),
                border: Border.all(
                  color: speciesColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.medical_information_outlined,
                size: 70,
                color: speciesColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              filterText,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isVetOrStaff
                  ? 'Add the first record to start tracking ${widget.pet.name}\'s health history'
                  : 'Medical records will appear here when added by your veterinarian',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isVetOrStaff)
              CpButton(
                text: 'Add Record',
                onPressed: () => _navigateToForm(context),
                icon: Icons.add_rounded,
                expanded: false,
                size: ButtonSize.large,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Failure failure) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: AppColors.gradientError,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load records',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              failure.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CpButton(
              text: 'Retry',
              onPressed: () {
                if (_selectedFilter != null) {
                  context.read<MedicalRecordBloc>().add(
                    LoadMedicalRecordsByType(widget.pet.id!, _selectedFilter!),
                  );
                } else {
                  context.read<MedicalRecordBloc>().add(
                    LoadMedicalRecords(widget.pet.id!),
                  );
                }
              },
              icon: Icons.refresh_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, Color speciesColor) {
    return FloatingAnimation(
      delay: const Duration(milliseconds: 300),
      child: PulsingGlow(
        glowColor: speciesColor,
        maxRadius: 24,
        duration: const Duration(seconds: 2),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToForm(context),
          backgroundColor: speciesColor,
          foregroundColor: Colors.white,
          elevation: 0,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Add Record',
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, MedicalRecord record) {
    context.push(
      '/medical-records/${record.id}',
      extra: {'record': record, 'pet': widget.pet},
    );
  }

  void _navigateToForm(BuildContext context) {
    final bloc = context.read<MedicalRecordBloc>();
    context.push(
      '/medical-records/new',
      extra: {'pet': widget.pet},
    ).then((_) {
      // Reload records after form closes
      if (!mounted) return;
      if (_selectedFilter != null) {
        bloc.add(
          LoadMedicalRecordsByType(widget.pet.id!, _selectedFilter!),
        );
      } else {
        bloc.add(LoadMedicalRecords(widget.pet.id!));
      }
    });
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Options',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.filter_list_rounded, color: AppColors.primary),
              title: const Text('Filter Records'),
              subtitle: Text(_selectedFilter?.displayName ?? 'All records'),
              onTap: () => context.pop(),
            ),
            ListTile(
              leading: Icon(Icons.refresh_rounded, color: AppColors.tertiary),
              title: const Text('Refresh'),
              onTap: () {
                context.pop();
                if (_selectedFilter != null) {
                  context.read<MedicalRecordBloc>().add(
                    LoadMedicalRecordsByType(widget.pet.id!, _selectedFilter!),
                  );
                } else {
                  context.read<MedicalRecordBloc>().add(
                    LoadMedicalRecords(widget.pet.id!),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.help_outline_rounded, color: AppColors.info),
              title: const Text('About Medical Records'),
              onTap: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                )
              : LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ],
                ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? PremiumShadows.glow(context, color, intensity: 0.3)
              : PremiumShadows.level1,
        ),
        child: Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Medical record card widget
class _MedicalRecordCard extends StatelessWidget {
  final MedicalRecord record;
  final Color speciesColor;

  const _MedicalRecordCard({
    required this.record,
    required this.speciesColor,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = _getTypeInfo(record.recordType);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      borderColor: typeInfo.color.withValues(alpha: 0.2),
      boxShadow: [
        ...PremiumShadows.level2,
        BoxShadow(
          color: typeInfo.color.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon with background
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  typeInfo.color.withValues(alpha: 0.2),
                  typeInfo.color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: typeInfo.color.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              typeInfo.icon,
              color: typeInfo.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Record details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeInfo.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        record.recordType.displayName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: typeInfo.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(record.recordedAt),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  record.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.description != null && record.description!.isNotEmpty)
                  ...[
                    const SizedBox(height: 4),
                    Text(
                      record.description!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                if (record.diagnosis != null && record.diagnosis!.isNotEmpty)
                  ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Diagnosis: ${record.diagnosis}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.infoDark,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                if (record.treatment != null && record.treatment!.isNotEmpty)
                  ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.tertiary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.healing_outlined,
                            size: 16,
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Treatment: ${record.treatment}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.tertiaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
          // Chevron
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(recordDate).inDays;

    if (diff == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff == 1) {
      return 'Yesterday';
    } else if (diff < 7) {
      return '${diff}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  TypeInfo _getTypeInfo(MedicalRecordType type) {
    return MedicalRecordUtils.getTypeInfo(type);
  }
}