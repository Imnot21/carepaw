import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/medical_records/presentation/utils/medical_record_utils.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_dialog.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';

/// Page showing detailed view of a medical record with premium design.
class MedicalRecordDetailPage extends StatelessWidget {
  final MedicalRecord record;
  final Pet pet;

  const MedicalRecordDetailPage({
    super.key,
    required this.record,
    required this.pet,
  });

  @override
  Widget build(BuildContext context) {
    final typeInfo = MedicalRecordUtils.getTypeInfoCustom(
      context,
      record.recordType,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          record.recordType.displayName,
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: NeuIconButton(
            plain: true,
            icon: Icons.arrow_back_ios_new_rounded,
            svgAsset: SvgIcons.back,
            onPressed: () => context.pop(),
            tooltip: 'Back',
          ),
        ),
        actions: [
          // Records are append-only: only the clinic side may correct them.
          // Pet owners get a read-only view (no edit pencil).
          Builder(
            builder: (context) {
              final authState = context.watch<AuthBloc>().state;
              final canEdit =
                  authState is AuthAuthenticated && authState.user.isOwnerAdmin;
              if (!canEdit) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NeuIconButton(
                  plain: true,
                  icon: Icons.edit_outlined,
                  svgAsset: SvgIcons.edit,
                  onPressed: () => _navigateToEdit(context),
                  tooltip: 'Correct record',
                ),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with record type and pet info
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  // Type badge
                  NeuContainer(
                    borderRadius: NeuTokens.radiusLg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    color: typeInfo.color,
                    boxShadow: NeuShadow.color(
                      context,
                      typeInfo.color,
                      blur: 16,
                      opacity: 0.28,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NeuSvgIcon(typeInfo.svgAsset, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          record.recordType.displayName,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Pet avatar
                  PetUtils.buildAvatar(
                    species: pet.species,
                    radius: 50,
                    iconSize: 50,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    pet.name,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${pet.species.displayName}${pet.breed != null ? ' - ${pet.breed}' : ''}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    record.title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Recorded on ${_formatFullDate(record.recordedAt)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content sections
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList.separated(
              itemCount: _getSections(context).length,
              separatorBuilder: (_, _) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final section = _getSections(context)[index];
                if (section.content == null || section.content!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _SectionCard(
                  title: section.title,
                  icon: section.icon,
                  svgAsset: section.svgAsset,
                  color: section.color,
                  content: section.content!,
                );
              },
            ),
          ),

          // Bottom padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  List<_DetailSection> _getSections(BuildContext context) {
    final sections = <_DetailSection>[];

    if (record.description != null && record.description!.isNotEmpty) {
      sections.add(
        _DetailSection(
          title: 'Description',
          icon: Icons.description_outlined,
          svgAsset: SvgIcons.note,
          color: ThemeColors.primaryText(context),
          content: record.description!,
        ),
      );
    }

    if (record.diagnosis != null && record.diagnosis!.isNotEmpty) {
      sections.add(
        _DetailSection(
          title: 'Diagnosis',
          icon: Icons.medical_services_outlined,
          svgAsset: SvgIcons.visit,
          color: ThemeColors.info(context),
          content: record.diagnosis!,
        ),
      );
    }

    if (record.treatment != null && record.treatment!.isNotEmpty) {
      sections.add(
        _DetailSection(
          title: 'Treatment',
          icon: Icons.healing_outlined,
          svgAsset: SvgIcons.treatment,
          color: ThemeColors.progress(context),
          content: record.treatment!,
        ),
      );
    }

    if (record.medications != null && record.medications!.isNotEmpty) {
      sections.add(
        _DetailSection(
          title: 'Medications',
          icon: Icons.medication_outlined,
          svgAsset: SvgIcons.medication,
          color: AppColors.quaternary,
          content: record.medications!,
        ),
      );
    }

    if (record.attachments != null && record.attachments!.isNotEmpty) {
      sections.add(
        _DetailSection(
          title: 'Attachments',
          icon: Icons.attachment_outlined,
          svgAsset: SvgIcons.attach,
          color: ThemeColors.textSecondary(context),
          content: record.attachments!,
        ),
      );
    }

    sections.add(
      _DetailSection(
        title: 'Record Information',
        icon: Icons.info_outline,
        svgAsset: SvgIcons.info,
        color: ThemeColors.textTertiary(context),
        content: _buildMetadata(),
      ),
    );

    return sections;
  }

  String _buildMetadata() {
    final buffer = StringBuffer();
    buffer.writeln('Record ID: ${record.id ?? 'N/A'}');
    buffer.writeln('Pet ID: ${record.petId}');
    buffer.writeln('Veterinarian ID: ${record.veterinarianId}');
    if (record.appointmentId != null) {
      buffer.writeln('Appointment ID: ${record.appointmentId}');
    }
    buffer.writeln('Created: ${_formatFullDate(record.createdAt)}');
    return buffer.toString();
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} at '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToEdit(BuildContext context) {
    NeuBottomSheet.show(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Correcting a Record',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Medical records can never be edited or deleted. Mistakes are '
              'fixed by adding a correction note on top, so the full '
              'history is always kept.',
              style: AppTextStyles.bodyLarge.copyWith(
                color: ThemeColors.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            NeuButton(
              text: 'Got it',
              onPressed: () => context.pop(),
              variant: NeuButtonVariant.primary,
              icon: Icons.check_rounded,
              svgAsset: SvgIcons.check,
            ),
          ],
        ),
      ),
    );
  }
}

/// Section card for detail page
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? svgAsset;
  final Color color;
  final String content;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.svgAsset,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return NeuCard(
      padding: const EdgeInsets.all(22),
      borderColor: color.withValues(alpha: 0.2),
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeuContainer(
                borderRadius: NeuTokens.radiusSm,
                padding: const EdgeInsets.all(12),
                variant: NeuVariant.flat,
                color: color.withValues(alpha: 0.12),
                child: svgAsset != null
                    ? NeuSvgIcon(svgAsset!, size: 24)
                    : Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(content, style: AppTextStyles.bodyLarge.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}

class _DetailSection {
  final String title;
  final IconData icon;
  final String? svgAsset;
  final Color color;
  final String? content;

  _DetailSection({
    required this.title,
    required this.icon,
    this.svgAsset,
    required this.color,
    required this.content,
  });
}
