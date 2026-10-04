import 'package:flutter/material.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../app/theme/theme_colors.dart';

/// Transient feedback, in one shape.
///
/// Thirty-eight pages were each building their own [SnackBar], and the shapes
/// had drifted: some had a margin, some did not, some used a rounded rectangle
/// and some a stadium. [NeuToast] is the one place that decides.
///
/// Two rules it enforces:
///
/// 1. **Error and success get a colour; everything else stays neutral.** A
///    toast is chrome, so a warning tinted the same red as a failed write stops
///    meaning anything.
/// 2. **The action is optional and singular.** Two buttons in a toast is a
///    dialog that arrived too late to be read.
abstract final class NeuToast {
  const NeuToast._();

  /// Report a completed action.
  static void success(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      tone: NeuToastTone.success,
      icon: Icons.check_circle_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Report a failure. Use this for anything the user needs to know failed —
  /// silent failure on a medical record is worse than an ugly toast.
  static void error(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      tone: NeuToastTone.error,
      icon: Icons.error_rounded,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Report something neutral — a copy confirmation, a dismissal.
  static void info(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      tone: NeuToastTone.neutral,
      icon: null,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required NeuToastTone tone,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = switch (tone) {
      NeuToastTone.success => ThemeColors.success(context),
      NeuToastTone.error => ThemeColors.error(context),
      NeuToastTone.neutral => null,
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          backgroundColor: isDark
              ? AppColors.surfaceInsetDark
              : AppColors.surfaceInset,
          margin: const EdgeInsets.all(NeuTokens.spaceMd),
          padding: const EdgeInsets.symmetric(
            horizontal: NeuTokens.spaceMd,
            vertical: NeuTokens.spaceSm + 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NeuTokens.radiusMd),
          ),
          duration: Duration(
            // Errors linger. A failure the user missed is a failure they will
            // hit again.
            milliseconds: tone == NeuToastTone.error ? 6000 : 3000,
          ),
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: NeuTokens.iconSm, color: accent),
                const SizedBox(width: NeuTokens.tightGap),
              ],
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ThemeColors.textPrimary(context),
                  ),
                ),
              ),
            ],
          ),
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: ThemeColors.primary(context),
                  onPressed: onAction,
                )
              : null,
        ),
      );
  }
}

enum NeuToastTone { neutral, success, error }
