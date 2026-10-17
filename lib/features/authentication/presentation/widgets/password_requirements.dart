import 'package:flutter/material.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_svg_icon.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_motion.dart';

/// Live password requirement checklist.
///
/// Sits directly under the password field so the user sees what to type
/// without reading a long truncated hint. Each rule turns green with a
/// filled check as soon as it is met.
class PasswordRequirements extends StatelessWidget {
  final String password;

  const PasswordRequirements({super.key, required this.password});

  bool get _hasMinLength => password.length >= 8;
  bool get _hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => password.contains(RegExp(r'[0-9]'));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _RuleRow(
          label: 'At least 8 characters',
          met: _hasMinLength,
        ),
        const SizedBox(height: 4),
        _RuleRow(
          label: '1 uppercase letter (A-Z)',
          met: _hasUppercase,
        ),
        const SizedBox(height: 4),
        _RuleRow(
          label: '1 lowercase letter (a-z)',
          met: _hasLowercase,
        ),
        const SizedBox(height: 4),
        _RuleRow(
          label: '1 number (0-9)',
          met: _hasNumber,
        ),
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final bool met;

  const _RuleRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final success = ThemeColors.success(context);
    final muted = ThemeColors.textSecondary(context);
    return AnimatedDefaultTextStyle(
      duration: NeuMotion.duration(context, NeuTokens.durationMedium),
      style: AppTextStyles.bodySmall.copyWith(
        color: met ? success : muted,
        fontWeight: met ? FontWeight.w600 : FontWeight.w400,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: NeuMotion.duration(context, NeuTokens.durationMedium),
            child: met
                ? NeuSvgIcon(
                    SvgIcons.check,
                    size: 16,
                    key: ValueKey(met),
                    tooltip: '$label - met',
                  )
                : NeuSvgIcon(
                    SvgIcons.radioUnchecked,
                    size: 16,
                    key: ValueKey(met),
                    tooltip: '$label - not met',
                  ),
          ),
          const SizedBox(width: 6),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}
