import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_bloc.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_event.dart';
import 'package:carepaw/features/pets/presentation/bloc/pet_state.dart';
import 'package:carepaw/features/pets/presentation/pages/pet_form_page.dart';
import 'package:carepaw/features/pets/domain/repositories/pet_repository.dart';
import 'package:carepaw/features/pets/domain/entities/pet.dart';
import 'package:carepaw/features/pets/presentation/utils/pet_utils.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';

/// Page showing detailed pet information with premium design.
class PetDetailPage extends StatefulWidget {
  final Pet pet;

  const PetDetailPage({super.key, required this.pet});

  @override
  State<PetDetailPage> createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> with SingleTickerProviderStateMixin {
  late Pet _pet;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updatePet(Pet updatedPet) {
    setState(() => _pet = updatedPet);
  }

  @override
  Widget build(BuildContext context) {
    final speciesColor = PetUtils.getSpeciesColor(_pet.species);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            boxShadow: PremiumShadows.level(context, 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: PremiumShadows.level(context, 1),
            ),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit': _navigateToEdit(context); break;
                  case 'add_weight': _showAddWeightDialog(context); break;
                  case 'deactivate': _showDeactivateDialog(context); break;
                  case 'activate': _showActivateDialog(context); break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Edit')])),
                const PopupMenuItem(value: 'add_weight', child: Row(children: [Icon(Icons.monitor_weight_outlined, size: 20), SizedBox(width: 8), Text('Add Weight Entry')])),
                if (_pet.isActive)
                  const PopupMenuItem(value: 'deactivate', child: Row(children: [Icon(Icons.archive_outlined, size: 20, color: AppColors.warning), SizedBox(width: 8), Text('Deactivate', style: TextStyle(color: AppColors.warning))]))
                else
                  const PopupMenuItem(value: 'activate', child: Row(children: [Icon(Icons.unarchive_outlined, size: 20, color: AppColors.success), SizedBox(width: 8), Text('Activate', style: TextStyle(color: AppColors.success))])),
              ],
              child: const Icon(Icons.more_vert_rounded, size: 24),
            ),
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        colors: [
          speciesColor.withValues(alpha: 0.08),
          Theme.of(context).colorScheme.surface,
        ],
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Hero header with pet avatar
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground, StretchMode.fadeTitle],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [speciesColor.withValues(alpha: 0.9), speciesColor],
                        ),
                      ),
                    ),
                    // Subtle pattern overlay
                    CustomPaint(painter: _PawPrintPainter(color: Colors.white.withValues(alpha: 0.06))),
                    // Pet avatar
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PulsingGlow(
                            glowColor: speciesColor,
                            maxRadius: 40,
                            duration: const Duration(seconds: 3),
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [speciesColor, speciesColor.withValues(alpha: 0.7)]),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: PremiumShadows.custom(color: speciesColor, blurRadius: 24, spreadRadius: 4, offset: const Offset(0, 12)),
                              ),
                              child: _pet.avatarUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(30),
                                      child: Image.network(_pet.avatarUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => _buildAvatarPlaceholder(speciesColor)),
                                    )
                                  : _buildAvatarPlaceholder(speciesColor),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _pet.name,
                            style: AppTextStyles.headlineLarge.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              shadows: [Shadow(blurRadius: 8, color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 2))],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(PetUtils.getSpeciesIcon(_pet.species), size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  PetUtils.formatSpecies(_pet.species),
                                  style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick info chips
                        _QuickInfoChips(pet: _pet),
                        const SizedBox(height: 24),

                        // Basic info section
                        _buildSection(
                          context,
                          title: 'Basic Information',
                          icon: Icons.info_outline_rounded,
                          iconColor: speciesColor,
                          child: _BasicInfoCard(pet: _pet),
                        ),
                        const SizedBox(height: 20),

                        // Weight tracking section
                        _buildSection(
                          context,
                          title: 'Weight Tracking',
                          icon: Icons.monitor_weight_outlined,
                          iconColor: AppColors.primary,
                          child: _WeightTrackingCard(pet: _pet, onAddWeight: _showAddWeightDialog),
                        ),
                        const SizedBox(height: 20),

                        // Quick actions
                        _buildSection(
                          context,
                          title: 'Quick Actions',
                          icon: Icons.flash_on_rounded,
                          iconColor: AppColors.secondary,
                          child: _QuickActionsCard(pet: _pet),
                        ),
                        const SizedBox(height: 20),

                        // Medical records
                        _buildSection(
                          context,
                          title: 'Medical Records',
                          icon: Icons.medical_services_outlined,
                          iconColor: AppColors.tertiary,
                          child: _MedicalRecordsCard(pet: _pet),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required Color iconColor, required Widget child}) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      blur: 20,
      gradient: LinearGradient(
        colors: [
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderColor: Theme.of(context).brightness == Brightness.dark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder(Color speciesColor) {
    return Center(child: PetUtils.buildAvatarPlaceholder(_pet.species, radius: 60, iconSize: 60));
  }

  void _navigateToEdit(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetFormPage(ownerId: _pet.ownerId, pet: _pet))).then((_) {});
  }

  void _showAddWeightDialog(BuildContext context) {
    final weightController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => _PremiumDialog(
        title: 'Add Weight Entry',
        icon: Icons.monitor_weight_outlined,
        iconColor: AppColors.primary,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current weight: ${_pet.weightKg?.toStringAsFixed(1) ?? 'Not set'} kg', style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            TextField(
              controller: weightController,
              decoration: InputDecoration(labelText: 'New Weight (kg)', hintText: 'e.g., 26.5', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.monitor_weight_outlined)),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveWeight(dialogContext, weightController),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          CpButton(text: 'Save', onPressed: () => _saveWeight(dialogContext, weightController), icon: Icons.save, variant: ButtonVariant.primary),
        ],
      ),
    );
  }

  void _saveWeight(BuildContext dialogContext, TextEditingController controller) {
    final weight = double.tryParse(controller.text);
    if (weight != null && weight > 0) {
      Navigator.of(dialogContext).pop();
      final updatedPet = _pet.copyWith(weightKg: weight, updatedAt: DateTime.now());
      _updatePet(updatedPet);
      context.read<PetBloc>().add(UpdatePetWeight(petId: _pet.id!, weightKg: weight));
    }
  }

  void _showDeactivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PremiumDialog(
        title: 'Deactivate ${_pet.name}?',
        icon: Icons.archive_outlined,
        iconColor: AppColors.warning,
        content: Text('This will archive ${_pet.name}. The pet will no longer appear in active lists but can be restored later.', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          CpButton(text: 'Deactivate', variant: ButtonVariant.destructive, onPressed: () {
            Navigator.of(dialogContext).pop();
            final updatedPet = _pet.copyWith(isActive: false);
            _updatePet(updatedPet);
            context.read<PetBloc>().add(UpdatePet(pet: updatedPet));
          }, icon: Icons.archive),
        ],
      ),
    );
  }

  void _showActivateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => _PremiumDialog(
        title: 'Activate ${_pet.name}?',
        icon: Icons.unarchive_outlined,
        iconColor: AppColors.success,
        content: Text('This will restore ${_pet.name} to active status.', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          CpButton(text: 'Activate', variant: ButtonVariant.primary, onPressed: () {
            Navigator.of(dialogContext).pop();
            final updatedPet = _pet.copyWith(isActive: true);
            _updatePet(updatedPet);
            context.read<PetBloc>().add(UpdatePet(pet: updatedPet));
          }, icon: Icons.unarchive),
        ],
      ),
    );
  }
}

/// Premium dialog with consistent styling
class _PremiumDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget content;
  final List<Widget> actions;

  const _PremiumDialog({required this.title, required this.icon, required this.iconColor, required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        blur: 30,
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.surface.withValues(alpha: 0.95), Theme.of(context).colorScheme.surface.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderColor: Theme.of(context).brightness == Brightness.dark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(title, style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 20),
            content,
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions.map((a) => Padding(padding: const EdgeInsets.only(left: 8), child: a)).toList()),
          ],
        ),
      ),
    );
  }
}

/// Quick info chips row using PetUtils.buildInfoChip
class _QuickInfoChips extends StatelessWidget {
  final Pet pet;
  const _QuickInfoChips({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FloatingAnimation(
          delay: const Duration(milliseconds: 100),
          child: PetUtils.buildInfoChip(icon: PetUtils.getSpeciesIcon(pet.species), label: PetUtils.formatSpecies(pet.species), color: PetUtils.getSpeciesColor(pet.species)),
        ),
        if (pet.breed != null)
          FloatingAnimation(
            delay: const Duration(milliseconds: 180),
            child: PetUtils.buildInfoChip(icon: Icons.pets, label: pet.breed!, color: Theme.of(context).colorScheme.primary),
          ),
        if (pet.birthDate != null)
          FloatingAnimation(
            delay: const Duration(milliseconds: 260),
            child: PetUtils.buildInfoChip(icon: Icons.cake_outlined, label: 'Age: ${PetUtils.calculateAge(pet.birthDate!)}', color: AppColors.tertiary),
          ),
        if (pet.weightKg != null)
          FloatingAnimation(
            delay: const Duration(milliseconds: 340),
            child: PetUtils.buildInfoChip(icon: Icons.monitor_weight_outlined, label: '${pet.weightKg!.toStringAsFixed(1)} kg', color: AppColors.primary),
          ),
        if (pet.microchipId != null)
          FloatingAnimation(
            delay: const Duration(milliseconds: 420),
            child: PetUtils.buildInfoChip(icon: Icons.nfc_outlined, label: 'Microchipped', color: AppColors.success),
          ),
      ],
    );
  }
}

/// Basic info card using PetUtils for species formatting
class _BasicInfoCard extends StatelessWidget {
  final Pet pet;
  const _BasicInfoCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoRow(icon: Icons.badge_outlined, label: 'Name', value: pet.name, valueStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        _InfoRow(icon: PetUtils.getSpeciesIcon(pet.species), label: 'Species', value: PetUtils.formatSpecies(pet.species), valueStyle: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600, color: PetUtils.getSpeciesColor(pet.species))),
        if (pet.breed != null) _InfoRow(icon: Icons.category_outlined, label: 'Breed', value: pet.breed!),
        if (pet.color != null) _InfoRow(icon: Icons.palette_outlined, label: 'Color', value: pet.color!),
        if (pet.birthDate != null) _InfoRow(icon: Icons.cake_outlined, label: 'Birth Date', value: '${pet.birthDate!.day}/${pet.birthDate!.month}/${pet.birthDate!.year}'),
        if (pet.microchipId != null) _InfoRow(icon: Icons.nfc_outlined, label: 'Microchip ID', value: pet.microchipId!),
        _InfoRow(
          icon: Icons.flag_outlined,
          label: 'Status',
          value: pet.isActive ? 'Active' : 'Inactive',
          valueStyle: AppTextStyles.bodyMedium.copyWith(color: pet.isActive ? AppColors.success : AppColors.warning, fontWeight: FontWeight.w600),
        ),
        _InfoRow(icon: Icons.access_time_outlined, label: 'Created', value: '${pet.createdAt.day}/${pet.createdAt.month}/${pet.createdAt.year}'),
        _InfoRow(icon: Icons.update_outlined, label: 'Last Updated', value: '${pet.updatedAt.day}/${pet.updatedAt.month}/${pet.updatedAt.year}'),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 22, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Text(value, style: valueStyle ?? AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Weight tracking card
class _WeightTrackingCard extends StatelessWidget {
  final Pet pet;
  final void Function(BuildContext) onAddWeight;
  const _WeightTrackingCard({required this.pet, required this.onAddWeight});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pet.weightKg != null) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.monitor_weight_outlined, size: 26, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Weight', style: AppTextStyles.labelMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text('${pet.weightKg!.toStringAsFixed(1)} kg', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
              ),
              CpButton(text: 'Add Entry', onPressed: () => onAddWeight(context), icon: Icons.add, size: ButtonSize.small),
            ],
          ),
        ] else ...[
          Center(
            child: Column(
              children: [
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)), child: Icon(Icons.monitor_weight_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3))),
                const SizedBox(height: 16),
                Text('No weight recorded yet', style: AppTextStyles.titleSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('Add a weight entry to track your pet\'s health', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                CpButton(text: 'Add First Weight', onPressed: () => onAddWeight(context), icon: Icons.add),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Quick actions card
class _QuickActionsCard extends StatelessWidget {
  final Pet pet;
  const _QuickActionsCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionTile(icon: Icons.calendar_today_outlined, title: 'Book Appointment', subtitle: 'Schedule a vet visit', color: AppColors.primary, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment booking coming soon')))),
        const Divider(height: 1, indent: 56),
        _ActionTile(icon: Icons.medical_services_outlined, title: 'View Medical Records', subtitle: 'Vaccinations, treatments, notes', color: AppColors.tertiary, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical records coming soon')))),
        const Divider(height: 1, indent: 56),
        _ActionTile(icon: Icons.vaccines_outlined, title: 'Vaccination Schedule', subtitle: 'Track upcoming vaccines', color: AppColors.secondary, onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vaccination schedule coming soon')))),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color, size: 24)),
        title: Text(title, style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        trailing: Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Medical records card
class _MedicalRecordsCard extends StatelessWidget {
  final Pet pet;
  const _MedicalRecordsCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)), child: Icon(Icons.medical_services_outlined, size: 26, color: Theme.of(context).colorScheme.onPrimaryContainer)),
          const SizedBox(width: 16),
          Text('Medical Records', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(24)), child: Icon(Icons.folder_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5))),
              const SizedBox(height: 16),
              Text('No medical records yet', style: AppTextStyles.titleSmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text('Medical records will appear here after vet visits', style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              CpButton(text: 'View Medical Records', variant: ButtonVariant.secondary, onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medical records coming soon'))), icon: Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for subtle paw print pattern
class _PawPrintPainter extends CustomPainter {
  final Color color;
  _PawPrintPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 90.0;
    const radius = 14.0;
    for (double x = -spacing; x < size.width + spacing; x += spacing) {
      for (double y = -spacing; y < size.height + spacing; y += spacing) {
        final center = Offset(x + (y / spacing).floor() * (spacing / 2), y);
        canvas.drawCircle(center, radius * 0.7, paint);
        canvas.drawCircle(Offset(center.dx - radius, center.dy - radius), radius * 0.4, paint);
        canvas.drawCircle(Offset(center.dx + radius, center.dy - radius), radius * 0.4, paint);
        canvas.drawCircle(Offset(center.dx - radius, center.dy + radius), radius * 0.4, paint);
        canvas.drawCircle(Offset(center.dx + radius, center.dy + radius), radius * 0.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Wrapper page that provides PetBloc and fetches pet by ID for detail view
class PetDetailPageWithBloc extends StatelessWidget {
  final int petId;
  const PetDetailPageWithBloc({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PetBloc(petRepository: context.read<PetRepository>())..add(LoadPetsById(petId)),
      child: _PetDetailLoader(petId: petId),
    );
  }
}

/// Wrapper page that provides PetBloc and fetches pet by ID for edit view
class PetFormPageWithBloc extends StatelessWidget {
  final int petId;
  const PetFormPageWithBloc({super.key, required this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PetBloc(petRepository: context.read<PetRepository>())..add(LoadPetsById(petId)),
      child: _PetFormLoader(petId: petId),
    );
  }
}

/// Loads pet by ID and shows PetDetailPage
class _PetDetailLoader extends StatelessWidget {
  final int petId;
  const _PetDetailLoader({required this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        if (state is PetLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (state is PetDetailLoaded) return PetDetailPage(pet: state.pet);
        if (state is PetError) return _buildError(context, state.failure.message);
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: AnimatedGradientBackground(
        colors: [AppColors.error.withValues(alpha: 0.08), Theme.of(context).colorScheme.surface],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(32),
              blur: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24)), child: Icon(Icons.error_outline, size: 64, color: AppColors.error)),
                  const SizedBox(height: 20),
                  Text('Error Loading Pet', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 12),
                  Text(message, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  CpButton(text: 'Retry', onPressed: () => context.read<PetBloc>().add(LoadPetsById(petId)), icon: Icons.refresh_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Loads pet by ID and shows PetFormPage for editing
class _PetFormLoader extends StatelessWidget {
  final int petId;
  const _PetFormLoader({required this.petId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PetBloc, PetState>(
      builder: (context, state) {
        if (state is PetLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (state is PetDetailLoaded) {
          final authState = context.read<AuthBloc>().state;
          final ownerId = authState is AuthAuthenticated ? authState.user.id! : 0;
          return PetFormPage(ownerId: ownerId, pet: state.pet);
        }
        if (state is PetError) return _buildError(context, state.failure.message);
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: AnimatedGradientBackground(
        colors: [AppColors.error.withValues(alpha: 0.08), Theme.of(context).colorScheme.surface],
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(32),
              blur: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(24)), child: Icon(Icons.error_outline, size: 64, color: AppColors.error)),
                  const SizedBox(height: 20),
                  Text('Error Loading Pet', style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 12),
                  Text(message, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  CpButton(text: 'Retry', onPressed: () => context.read<PetBloc>().add(LoadPetsById(petId)), icon: Icons.refresh_rounded),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}