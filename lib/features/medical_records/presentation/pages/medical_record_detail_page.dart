import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:carepaw/features/medical_records/presentation/utils/medical_record_utils.dart';
import 'package:carepaw/features/medical_records/domain/entities/medical_record.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';

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
    final speciesColor = pet.species.accentColor;
    final typeInfo = MedicalRecordUtils.getTypeInfo(record.recordType);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          record.recordType.displayName,
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
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _navigateToEdit(context),
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        colors: [
          speciesColor.withValues(alpha: 0.05),
          typeInfo.color.withValues(alpha: 0.03),
        ],
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header with record type and pet info
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              sliver: SliverToBoxAdapter(
                child: FloatingAnimation(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    children: [
                      // Type badge with PulsingGlow
                      PulsingGlow(
                        glowColor: typeInfo.color,
                        maxRadius: 20,
                        duration: const Duration(seconds: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [typeInfo.color, typeInfo.color.withValues(alpha: 0.8)],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: PremiumShadows.glow(context, typeInfo.color, intensity: 0.4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(typeInfo.icon, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
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
                      ),
                      const SizedBox(height: 24),
                      // Pet avatar
                      PulsingGlow(
                        glowColor: speciesColor,
                        maxRadius: 25,
                        duration: const Duration(seconds: 3),
                        child: PetUtils.buildAvatar(
                          species: pet.species,
                          radius: 50,
                          iconSize: 50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pet.name,
                        style: AppTextStyles.headlineMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pet.species.displayName}${pet.breed != null ? ' • ${pet.breed}' : ''}',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Date and title
                      Text(
                        record.title,
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Recorded on ${_formatFullDate(record.recordedAt)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content sections
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList.separated(
                itemCount: _getSections().length,
                separatorBuilder: (_, _) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final section = _getSections()[index];
                  if (section.content == null || section.content!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return FloatingAnimation(
                    delay: Duration(milliseconds: 80 * (index + 1)),
                    child: _SectionCard(
                      title: section.title,
                      icon: section.icon,
                      color: section.color,
                      content: section.content!,
                    ),
                  );
                },
              ),
            ),

            // Bottom padding for FAB if needed
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  List<_DetailSection> _getSections() {
    final sections = <_DetailSection>[];

    if (record.description != null && record.description!.isNotEmpty) {
      sections.add(_DetailSection(
        title: 'Description',
        icon: Icons.description_outlined,
        color: AppColors.primary,
        content: record.description!,
      ));
    }

    if (record.diagnosis != null && record.diagnosis!.isNotEmpty) {
      sections.add(_DetailSection(
        title: 'Diagnosis',
        icon: Icons.medical_services_outlined,
        color: AppColors.info,
        content: record.diagnosis!,
      ));
    }

    if (record.treatment != null && record.treatment!.isNotEmpty) {
      sections.add(_DetailSection(
        title: 'Treatment',
        icon: Icons.healing_outlined,
        color: AppColors.tertiary,
        content: record.treatment!,
      ));
    }

    if (record.medications != null && record.medications!.isNotEmpty) {
      sections.add(_DetailSection(
        title: 'Medications',
        icon: Icons.medication_outlined,
        color: AppColors.quaternary,
        content: record.medications!,
      ));
    }

    if (record.attachments != null && record.attachments!.isNotEmpty) {
      sections.add(_DetailSection(
        title: 'Attachments',
        icon: Icons.attachment_outlined,
        color: AppColors.secondary,
        content: record.attachments!,
      ));
    }

    // Add metadata section
    sections.add(_DetailSection(
      title: 'Record Information',
      icon: Icons.info_outline,
      color: AppColors.textTertiary,
      content: _buildMetadata(),
    ));

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
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} at '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToEdit(BuildContext context) {
    // TODO: Implement edit navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }
}

/// Section card for detail page
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String content;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      borderColor: color.withValues(alpha: 0.2),
      boxShadow: [
        ...PremiumShadows.level2,
        BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: AppTextStyles.bodyLarge.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection {
  final String title;
  final IconData icon;
  final Color color;
  final String? content;

  _DetailSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });
}