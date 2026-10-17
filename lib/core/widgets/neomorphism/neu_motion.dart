import 'package:flutter/material.dart';

/// Motion, budgeted.
///
/// When the platform asks for reduced motion (the accessibility setting that
/// `MediaQuery.disableAnimations` reports), kit animations collapse to zero
/// duration: state still changes, but nothing travels. This is the one place
/// that decides, so reduce-motion support never depends on a page
/// remembering to ask.
abstract final class NeuMotion {
  const NeuMotion._();

  /// Whether the platform currently asks for reduced motion.
  static bool isReduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [preferred], or zero when the platform asks for reduced motion.
  static Duration duration(BuildContext context, Duration preferred) =>
      isReduced(context) ? Duration.zero : preferred;
}
