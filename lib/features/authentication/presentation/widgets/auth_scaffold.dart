import 'package:flutter/material.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/app/theme/theme_colors.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shapes.dart';

/// The shell every authentication screen sits in.
///
/// Four screens each built their own version of "brand mark, heading, extruded
/// card, footer", which is how the brand mark ended up terracotta on one screen
/// and green on another, and how the page padding ended up at four different
/// values. This is that arrangement, once.
///
/// The card is the only extruded object on the screen. Everything above it —
/// mark, wordmark, heading, helper text — sits directly on the canvas, so the
/// form reads as the one thing on the page you can act on.
class AuthScaffold extends StatelessWidget {
  final Widget child;

  /// The line under the wordmark, e.g. "Smart Veterinary Care".
  final String tagline;

  /// Render a back control. Off for the first screen in the flow (login).
  final VoidCallback? onBack;

  /// Shown pinned to the bottom of the scroll, below [child]. Used for the
  /// "don't have an account" and legal lines so they never scroll away from
  /// the edge in a way that strands them mid-screen.
  final Widget? footer;

  const AuthScaffold({
    super.key,
    required this.child,
    this.tagline = 'Smart Veterinary Care',
    this.onBack,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.background(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: NeuTokens.pagePadding,
                vertical: NeuTokens.spaceLg,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - NeuTokens.spaceLg * 2,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: NeuTokens.maxContentWidth,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (onBack != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: NeuIconButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'Back',
                              onPressed: onBack,
                            ),
                          ),
                          const SizedBox(height: NeuTokens.spaceXl),
                        ],
                        const Center(child: AuthBrandMark()),
                        const SizedBox(height: NeuTokens.tightGap),
                        Text(
                          'CarePaw',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.displaySmall.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: NeuTokens.spaceXxs),
                        Text(
                          tagline,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.subtleOf(
                            Theme.of(context).brightness,
                          ),
                        ),
                        const SizedBox(height: NeuTokens.spaceXxl),
                        child,
                        if (footer != null) ...[
                          const SizedBox(height: NeuTokens.spaceXl),
                          footer!,
                        ],
                        const SizedBox(height: NeuTokens.spaceLg),
                        const Center(child: AuthLegalLine()),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The brand mark: a paw recessed into an extruded disc.
///
/// Recessed, not raised. This is the one object on the auth screens that is not
/// asking to be touched, and a cavity reads as "insignia" where a raised plate
/// would read as "button" — and on a login screen a large button-shaped object
/// with no label is a trap.
class AuthBrandMark extends StatelessWidget {
  final double radius;
  final IconData? icon;

  const AuthBrandMark({super.key, this.radius = 40, this.icon});

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.primary(context);
    final size = radius * 2;

    return NeuContainer(
      variant: NeuVariant.inset,
      shape: const CircleBorder(),
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: icon != null
            ? Icon(icon, size: radius, color: accent)
            : CustomPaint(
                painter: _PawPainter(color: accent),
                size: Size.square(size * 0.62),
              ),
      ),
    );
  }
}

class _PawPainter extends CustomPainter {
  final Color color;

  const _PawPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      NeuShape.pawPrint(size),
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PawPainter oldDelegate) => oldDelegate.color != color;
}

/// A heading and its supporting line, centred above a form.
class AuthHeading extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AuthHeading({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: NeuTokens.spaceXs),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
          ),
        ],
      ],
    );
  }
}

/// A sentence and a text action, centred.
///
/// The link is a text action rather than a button on purpose: it is a
/// navigational alternative to the primary CTA, and giving it a plate would put
/// two competing actions on one line.
class AuthPromptLink extends StatelessWidget {
  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthPromptLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            prompt,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium.subtleOf(
              Theme.of(context).brightness,
            ),
          ),
        ),
        const SizedBox(width: NeuTokens.spaceXxs),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: NeuTokens.minTapTarget,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: NeuTokens.spaceXs,
                ),
                child: Text(
                  actionLabel,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: ThemeColors.primary(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The version and copyright line.
///
/// Present, because a clinic system should say what it is, but deliberately the
/// quietest text on the screen.
class AuthLegalLine extends StatelessWidget {
  const AuthLegalLine({super.key});

  @override
  Widget build(BuildContext context) {
    final quiet = ThemeColors.textTertiary(context).withValues(alpha: 0.7);
    return Text(
      'CarePaw 1.0.0',
      textAlign: TextAlign.center,
      style: AppTextStyles.labelSmall.copyWith(color: quiet),
    );
  }
}
