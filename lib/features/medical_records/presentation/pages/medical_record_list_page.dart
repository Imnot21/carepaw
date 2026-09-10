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
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_chip.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_skeleton.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Page showing the list of medical records for a pet with neumorphic design.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Medical Records'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NeuContainer(
                borderRadius: 80,
                variant: NeuVariant.raised,
                color: AppColors.primary,
                boxShadow: NeuShadow.color(context, AppColors.primary, blur: 18, opacity: 0.32),
                child: const SizedBox(
                  width: 160,
                  height: 160,
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
                  color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to access your pet\'s health history',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              NeuButton(
                text: 'Log In',
                onPressed: () => context.go('/login'),
                icon: Icons.login_rounded,
                variant: NeuButtonVariant.primary,
                size: NeuButtonSize.medium,
              ),
            ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Pet header
          _buildPetHeader(context, speciesColor, isDark),

          // Filter chips
          _buildFilterChips(context, speciesColor),

          // Records list
          Expanded(
            child: BlocBuilder<MedicalRecordBloc, MedicalRecordState>(
              builder: (context, state) {
                if (state is MedicalRecordLoading) {
                  return const NeuSkeletonList();
                } else if (state is MedicalRecordsLoaded) {
                  return _buildRecordsList(context, state.records, speciesColor);
                } else if (state is MedicalRecordsByTypeLoaded) {
                  return _buildRecordsList(context, state.records, speciesColor);
                } else if (state is MedicalRecordError) {
                  return _buildErrorState(context, state.failure);
                } else if (state is MedicalRecordOperationSuccess) {
                  // Success state will be shown briefly then reload
                  return _buildEmptyState(context, speciesColor, isDark);
                }
                return _buildEmptyState(context, speciesColor, isDark);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isVetOrStaff ? _buildFab(context, speciesColor) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(
        '${widget.pet.name}\'s Records',
        style: AppTextStyles.titleLarge.copyWith(
          color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: NeuIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        onPressed: () => context.pop(),
        tooltip: 'Back',
      ),
      actions: [
        NeuIconButton(
          icon: Icons.more_vert_rounded,
          onPressed: () => _showOptionsMenu(context),
          tooltip: 'Options',
        ),
      ],
    );
  }

  Widget _buildPetHeader(BuildContext context, Color speciesColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        children: [
          // Pet avatar
          PetUtils.buildAvatar(
            species: widget.pet.species,
            radius: 40,
            iconSize: 40,
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
                    color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.pet.species.displayName}${widget.pet.breed != null ? ' • ${widget.pet.breed}' : ''}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
                  ),
                ),
                if (widget.pet.ageInYears != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${widget.pet.ageInYears} years old',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
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
              return NeuContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                borderRadius: 20,
                variant: NeuVariant.raised,
                borderColor: speciesColor.withValues(alpha: 0.3),
                borderWidth: 1,
                boxShadow: NeuShadow.color(context, speciesColor, blur: 10, opacity: 0.18),
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

    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length + 1, // +1 for "All"
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // All filter
            final isSelected = _selectedFilter == null;
            return NeuChip(
              label: 'All',
              selected: isSelected,
              onTap: () => setState(() => _selectedFilter = null),
              selectedColor: speciesColor,
            );
          }
          final (type, label) = filters[index - 1];
          final isSelected = _selectedFilter == type;
          return NeuChip(
            label: label,
            selected: isSelected,
            onTap: () {
              setState(() => _selectedFilter = type);
              context.read<MedicalRecordBloc>().add(
                LoadMedicalRecordsByType(widget.pet.id!, type),
              );
            },
            selectedColor: speciesColor,
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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return _buildEmptyState(context, speciesColor, isDark);
    }

    // Reload via pull-to-refresh instead of a manual refresh button.
    return RefreshIndicator(
      onRefresh: () async {
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
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        itemCount: records.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final record = records[index];
          return NeuCard(
            onTap: () => _navigateToDetail(context, record),
            padding: EdgeInsets.zero,
            child: _MedicalRecordCard(
              record: record,
              speciesColor: speciesColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, Color speciesColor, bool isDark) {
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
            NeuContainer(
              borderRadius: 70,
              variant: NeuVariant.raised,
              borderColor: speciesColor.withValues(alpha: 0.3),
              borderWidth: 2,
              child: const SizedBox(
                width: 140,
                height: 140,
                child: Icon(
                  Icons.medical_information_outlined,
                  size: 70,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              filterText,
              style: AppTextStyles.headlineSmall.copyWith(
                color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
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
                color: isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isVetOrStaff)
              NeuButton(
                text: 'Add Record',
                onPressed: () => _navigateToForm(context),
                icon: Icons.add_rounded,
                expanded: false,
                size: NeuButtonSize.medium,
                variant: NeuButtonVariant.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Failure failure) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuContainer(
              borderRadius: 60,
              variant: NeuVariant.raised,
              color: AppColors.error,
              child: const SizedBox(
                width: 120,
                height: 120,
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load records',
              style: AppTextStyles.headlineSmall.copyWith(
                color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              failure.message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            NeuButton(
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
              variant: NeuButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context, Color speciesColor) {
    return FloatingActionButton.extended(
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
      builder: (context) => NeuCard(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
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
              leading: Icon(Icons.filter_list_rounded, color: ThemeColors.primary(context)),
              title: const Text('Filter Records'),
              subtitle: Text(_selectedFilter?.displayName ?? 'All records'),
              onTap: () => context.pop(),
            ),
            ListTile(
              leading: Icon(Icons.help_outline_rounded, color: ThemeColors.primary(context)),
              title: const Text('About Medical Records'),
              onTap: () => context.pop(),
            ),
          ],
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
    final typeInfo = _getTypeInfo(context, record.recordType);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type icon with background
          NeuContainer(
            borderRadius: 16,
            variant: NeuVariant.raised,
            borderColor: typeInfo.color.withValues(alpha: 0.25),
            borderWidth: 1,
            child: const SizedBox(
              width: 56,
              height: 56,
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
                        color: typeInfo.color.withValues(alpha: 0.12),
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
                        color: isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  record.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
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
                        color: isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                if (record.diagnosis != null && record.diagnosis!.isNotEmpty)
                  ...[
                    const SizedBox(height: 8),
                    NeuContainer(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 10,
                      variant: NeuVariant.raised,
                      borderColor: AppColors.primaryLight.withValues(alpha: 0.2),
                      borderWidth: 1,
                      child: Row(
                        children: [
                          Icon(
                            Icons.medical_services_outlined,
                            size: 16,
                            color: ThemeColors.primary(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Diagnosis: ${record.diagnosis}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: ThemeColors.primary(context),
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
                    NeuContainer(
                      padding: const EdgeInsets.all(10),
                      borderRadius: 10,
                      variant: NeuVariant.raised,
                      borderColor: AppColors.primary.withValues(alpha: 0.2),
                      borderWidth: 1,
                      child: Row(
                        children: [
                          Icon(
                            Icons.healing_outlined,
                            size: 16,
                            color: ThemeColors.primary(context),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Treatment: ${record.treatment}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: ThemeColors.primary(context),
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
            color: isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
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

  TypeInfo _getTypeInfo(BuildContext context, MedicalRecordType type) {
    return MedicalRecordUtils.getTypeInfo(context, type);
  }
}
