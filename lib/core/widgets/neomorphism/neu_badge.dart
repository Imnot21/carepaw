import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/theme_colors.dart';
import 'neu_container.dart';

/// The semantic weight of a status.
///
/// Status colour is the one place in the app where hue carries meaning, so it
/// is worth naming: a page picks a [NeuStatusTone] and the badge decides how to
/// render it. That is what stops "confirmed" being green on one screen and
/// terracotta on the next.
enum NeuStatusTone { muted, accent, progress, success, warning, danger }

/// Resolves a status value to its tone.
///
/// Keyed off the domain's own string values rather than off Dart enum types,
/// so [AppointmentStatus], [QueueStatus], [ScanStatus] and any future lifecycle
/// all resolve through the same table without this file importing a single
/// feature.
///
/// The default is [NeuStatusTone.muted], never a guess. A status this table has
/// never seen should look inert, not accidentally alarming.
abstract final class NeuStatusToneResolver {
  const NeuStatusToneResolver._();

  static const Map<String, NeuStatusTone> _tones = {
    // Awaiting a decision from someone.
    'REQUESTED': NeuStatusTone.warning,
    'PENDING': NeuStatusTone.warning,
    'PENDING_REVIEW': NeuStatusTone.warning,
    'AWAITING_CONFIRMATION': NeuStatusTone.warning,

    // Locked in and on the books.
    'CONFIRMED': NeuStatusTone.accent,
    'APPROVED': NeuStatusTone.accent,
    'CHECKED_IN': NeuStatusTone.accent,
    'CALLED': NeuStatusTone.accent,

    // Happening right now.
    'IN_PROGRESS': NeuStatusTone.progress,
    'IN_ROOM': NeuStatusTone.progress,
    'DISPENSING': NeuStatusTone.progress,
    'PROCESSING': NeuStatusTone.progress,

    // Finished, successfully.
    'COMPLETED': NeuStatusTone.success,
    'ACTIVE': NeuStatusTone.success,
    'AVAILABLE': NeuStatusTone.success,
    'VERIFIED': NeuStatusTone.success,
    'PAID': NeuStatusTone.success,
    'PAID_FULL': NeuStatusTone.success,

    // Time-sensitive.
    'EXPIRING': NeuStatusTone.warning,
    'LOW_STOCK': NeuStatusTone.warning,
    'DUE': NeuStatusTone.warning,
    'OVERDUE': NeuStatusTone.warning,
    'PARTIALLY_PAID': NeuStatusTone.warning,

    // Gone wrong.
    'REJECTED': NeuStatusTone.danger,
    'NO_SHOW': NeuStatusTone.danger,
    'EXPIRED': NeuStatusTone.danger,
    'OUT_OF_STOCK': NeuStatusTone.danger,
    'FAILED': NeuStatusTone.danger,

    // Withdrawn from use.
    'CANCELLED': NeuStatusTone.muted,
    'CANCELED': NeuStatusTone.muted,
    'SKIPPED': NeuStatusTone.muted,
    'INACTIVE': NeuStatusTone.muted,
    'ARCHIVED': NeuStatusTone.muted,
    'DRAFT': NeuStatusTone.muted,
  };

  /// Look a status up by its domain string value.
  static NeuStatusTone of(String? value) {
    if (value == null) return NeuStatusTone.muted;
    return _tones[value.trim().toUpperCase()] ?? NeuStatusTone.muted;
  }

  /// The accent a tone renders in, resolved for the current brightness.
  static Color colorOf(BuildContext context, NeuStatusTone tone) {
    return switch (tone) {
      NeuStatusTone.muted => ThemeColors.textTertiary(context),
      NeuStatusTone.accent => ThemeColors.primary(context),
      NeuStatusTone.progress => _progress(context),
      NeuStatusTone.success => ThemeColors.success(context),
      NeuStatusTone.warning => ThemeColors.warning(context),
      NeuStatusTone.danger => ThemeColors.error(context),
    };
  }

  static Color _progress(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF5EEAD4)
      : const Color(0xFF0D9488);
}

/// A status pill.
///
/// **Sunken**, not raised. A badge is an annotation the page is carrying, not
/// an object the user is meant to grab — so it reads as pressed into the
/// surface rather than standing on it. It also means a row of badges never
/// competes with the card it sits in for attention.
///
/// The label takes the tone colour at full strength while the fill takes it at
/// a fraction, which keeps the text contrast above 4.5:1 instead of relying on
/// a tinted background to carry legibility.
class NeuStatusBadge extends StatelessWidget {
  final String label;
  final NeuStatusTone tone;
  final IconData? icon;
  final bool compact;

  /// Build from a domain status value directly.
  ///
  /// ```dart
  /// NeuStatusBadge.fromValue(status.value, label: status.displayName)
  /// ```
  factory NeuStatusBadge.fromValue(
    String? value, {
    Key? key,
    required String label,
    IconData? icon,
    bool compact = false,
  }) {
    return NeuStatusBadge(
      key: key,
      label: label,
      tone: NeuStatusToneResolver.of(value),
      icon: icon,
      compact: compact,
    );
  }

  const NeuStatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = NeuStatusToneResolver.colorOf(context, tone);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: NeuContainer(
        variant: NeuVariant.pressed,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? NeuTokens.spaceXs : NeuTokens.spaceSm,
          vertical: compact ? 3 : NeuTokens.spaceXxs + 1,
        ),
        shape: const StadiumBorder(),
        color: Color.alphaBlend(
          accent.withValues(alpha: isDark ? 0.20 : 0.13),
          isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: NeuTokens.iconXs - 2, color: accent),
              const SizedBox(width: NeuTokens.spaceXxs + 2),
            ],
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                // The label is small, so give it the tracking it needs to stay
                // readable at 11px rather than shrinking it further.
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A record-type pill — "Consultation", "Vaccination", "Prescription".
///
/// Deliberately quieter than [NeuStatusBadge]: a record type is a category, not
/// a state, and it must not read as urgent. Same shape, no extrusion, muted ink.
class NeuTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;

  const NeuTag({super.key, required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final ink = color ?? ThemeColors.textSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: NeuTokens.spaceXs + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(NeuTokens.radiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: NeuTokens.iconXs - 2, color: ink),
            const SizedBox(width: NeuTokens.spaceXxs + 2),
          ],
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: ink)),
        ],
      ),
    );
  }
}
