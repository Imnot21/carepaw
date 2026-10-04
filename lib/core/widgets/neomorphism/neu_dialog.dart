import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_button.dart';
import 'neu_shadows.dart';
import 'neu_shapes.dart';
import 'neu_style.dart';

/// A dialog that replaces Material's [AlertDialog] and [Dialog].
///
/// A floating surface with a soft shadow, a hairline edge, and [NeuButton]
/// actions — the replacement for Material's [AlertDialog] and [Dialog].
///
/// Typical usage:
/// ```dart
/// NeuDialog.show(
///   context: context,
///   title: 'Delete Appointment?',
///   content: 'This action cannot be undone.',
///   actions: [
///     NeuButton(text: 'Cancel', variant: NeuButtonVariant.ghost, onPressed: () => Navigator.pop(context)),
///     NeuButton(text: 'Delete', variant: NeuButtonVariant.destructive, onPressed: () { ... }),
///   ],
/// );
/// ```
class NeuDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<Widget> actions;
  final double? maxWidth;
  final EdgeInsetsGeometry contentPadding;
  final CrossAxisAlignment actionsAlignment;

  /// Optional style override forwarded to the underlying [NeuCard].
  /// When provided, its [NeumorphicStyle.borderRadius] and
  /// [NeumorphicStyle.padding] take precedence over [contentPadding].
  final NeumorphicStyle? style;

  const NeuDialog({
    super.key,
    this.title,
    this.content,
    required this.actions,
    this.maxWidth = 360,
    this.contentPadding = const EdgeInsets.all(NeuTokens.spaceXl),
    this.actionsAlignment = CrossAxisAlignment.stretch,
    this.style,
  });

  /// Shows a [NeuDialog] modally.
  ///
  /// Returns the value passed to [Navigator.pop] when the dialog closes.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? content,
    required List<Widget> actions,
    double? maxWidth,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.all(NeuTokens.spaceXl),
    CrossAxisAlignment actionsAlignment = CrossAxisAlignment.stretch,
    bool barrierDismissible = true,
    NeumorphicStyle? style,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => NeuDialog(
        title: title,
        content: content,
        actions: actions,
        maxWidth: maxWidth,
        contentPadding: contentPadding,
        actionsAlignment: actionsAlignment,
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedPadding = style?.padding ?? contentPadding;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: ThemeColors.surface(context),
            shape: RoundedRectangleBorder(borderRadius: NeuShape.panel),
            shadows: NeuShadow.floating(context),
          ),
          child: Padding(
            padding: resolvedPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                ],
                if (content != null) ...[
                  Flexible(child: content!),
                  const SizedBox(height: 24),
                ],
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 12,
                  runSpacing: 12,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A confirmation dialog with standard Yes/No actions.
class NeuConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final NeuButtonVariant confirmVariant;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const NeuConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.confirmVariant = NeuButtonVariant.destructive,
    this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    NeuButtonVariant confirmVariant = NeuButtonVariant.destructive,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return NeuDialog.show<bool>(
      context: context,
      title: title,
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      actions: [
        NeuButton(
          text: cancelText,
          variant: NeuButtonVariant.ghost,
          onPressed: () {
            onCancel?.call();
            Navigator.pop(context, false);
          },
        ),
        NeuButton(
          text: confirmText,
          variant: confirmVariant,
          onPressed: () {
            onConfirm?.call();
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeuDialog(
      title: title,
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      actions: [
        NeuButton(
          text: cancelText,
          variant: NeuButtonVariant.ghost,
          onPressed: () {
            onCancel?.call();
            Navigator.pop(context, false);
          },
        ),
        NeuButton(
          text: confirmText,
          variant: confirmVariant,
          onPressed: () {
            onConfirm?.call();
            Navigator.pop(context, true);
          },
        ),
      ],
    );
  }
}

/// A bottom sheet wrapper — the one surface allowed to float at full height.
class NeuBottomSheet extends StatelessWidget {
  final Widget child;
  final double? maxHeight;
  final EdgeInsetsGeometry padding;
  final bool isScrollControlled;

  const NeuBottomSheet({
    super.key,
    required this.child,
    this.maxHeight,
    this.padding = const EdgeInsets.all(24),
    this.isScrollControlled = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? maxHeight,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    bool isScrollControlled = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      isDismissible: isDismissible,
      builder: (context) => NeuBottomSheet(
        maxHeight: maxHeight,
        padding: padding,
        isScrollControlled: isScrollControlled,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = maxHeight ?? MediaQuery.of(context).size.height * 0.85;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: isDark ? AppColors.surfaceDarkMode : AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: NeuShape.panel),
          shadows: NeuShadow.floating(context),
        ),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ThemeColors.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}
