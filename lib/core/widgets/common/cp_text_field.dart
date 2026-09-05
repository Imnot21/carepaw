import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../effects/glass_container.dart';
import '../effects/premium_shadows.dart';

/// CarePaw text field widget with premium styling.
///
/// Provides consistent input styling throughout the app
/// with validation support and various configurations.
class CpTextField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? error;
  final String? helper;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool autofocus;
  final bool autocorrect;
  final bool enableSuggestions;
  final EdgeInsetsGeometry? contentPadding;
  final bool usePremiumStyle;

  const CpTextField({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.helper,
    this.controller,
    this.focusNode,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.autofocus = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.contentPadding,
    this.usePremiumStyle = true,
  });

  @override
  State<CpTextField> createState() => _CpTextFieldState();
}

class _CpTextFieldState extends State<CpTextField> {
  late bool _obscureText;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(CpTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
    if (oldWidget.error != widget.error) {
      _errorText = widget.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usePremiumStyle) {
      return _buildPremiumField(context);
    }
    return _buildStandardField(context);
  }

  Widget _buildPremiumField(BuildContext context) {
    final hasError = _errorText != null || widget.error != null;
    final isFocused = widget.focusNode?.hasFocus ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final labelColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inputColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final helperColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final iconColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final disabledColor = isDark ? AppColors.disabledDark : AppColors.disabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelLarge.copyWith(
              color: widget.enabled ? labelColor : disabledColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: hasError
                ? []
                : isFocused
                    ? PremiumShadows.coloredShadow(AppColors.primary)
                    : PremiumShadows.level(context, 1),
          ),
          child: GlassContainer(
            borderRadius: 14,
            borderColor: hasError
                ? AppColors.error.withValues(alpha: 0.5)
                : isFocused
                    ? AppColors.primary
                    : (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
            borderWidth: isFocused || hasError ? 2 : 1,
            blur: 0,
            child: TextFormField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              obscureText: _obscureText,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              validator: _validate,
              inputFormatters: widget.inputFormatters,
              autofocus: widget.autofocus,
              autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              style: AppTextStyles.bodyLarge.copyWith(
                color: widget.enabled ? inputColor : disabledColor,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                errorText: null, // We handle error display separately
                helperText: widget.helper,
                helperMaxLines: 2,
                contentPadding: widget.contentPadding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: IconTheme(
                          data: IconThemeData(
                            color: isFocused ? AppColors.primary : iconColor,
                            size: 22,
                          ),
                          child: widget.prefixIcon!,
                        ),
                      )
                    : null,
                suffixIcon: _buildSuffixIcon(isFocused, isDark),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: hintColor,
                ),
                errorStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
                helperStyle: AppTextStyles.bodySmall.copyWith(
                  color: helperColor,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _errorText ?? widget.error!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
        if (widget.helper != null && !hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.helper!,
              style: AppTextStyles.bodySmall.copyWith(
                color: helperColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStandardField(BuildContext context) {
    final isFocused = widget.focusNode?.hasFocus ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final labelColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final inputColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.textHintDark : AppColors.textHint;
    final helperColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final disabledColor = isDark ? AppColors.disabledDark : AppColors.disabled;
    final fillColor = isDark ? AppColors.surfaceContainerDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelLarge.copyWith(
              color: widget.enabled ? labelColor : disabledColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          validator: _validate,
          inputFormatters: widget.inputFormatters,
          autofocus: widget.autofocus,
          autocorrect: widget.autocorrect,
          enableSuggestions: widget.enableSuggestions,
          style: AppTextStyles.bodyLarge.copyWith(
            color: widget.enabled ? inputColor : disabledColor,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: _errorText ?? widget.error,
            helperText: widget.helper,
            helperMaxLines: 2,
            errorMaxLines: 2,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon: widget.prefixIcon,
            suffixIcon: _buildSuffixIcon(isFocused, isDark),
            filled: true,
            fillColor: widget.enabled ? fillColor : (isDark ? AppColors.backgroundDark : AppColors.background),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? AppColors.primaryLight : AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.divider),
            ),
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: hintColor,
            ),
            errorStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
            helperStyle: AppTextStyles.bodySmall.copyWith(
              color: helperColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(bool isFocused, bool isDark) {
    final iconColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: isFocused ? AppColors.primary : iconColor,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }
    return widget.suffixIcon != null
        ? Padding(
            padding: const EdgeInsets.all(14),
            child: IconTheme(
              data: IconThemeData(
                color: isFocused ? AppColors.primary : iconColor,
                size: 22,
              ),
              child: widget.suffixIcon!,
            ),
          )
        : null;
  }

  String? _validate(String? value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _errorText = error;
          });
        });
        return error;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _errorText = null;
      });
    });
    return null;
  }
}

/// Preconfigured text field variants
class CpTextFieldEmail extends CpTextField {
  const CpTextFieldEmail({
    super.key,
    super.label = 'Email',
    super.hint = 'Enter your email',
    super.controller,
    super.focusNode,
    super.enabled,
    super.onChanged,
    super.onSubmitted,
    super.validator,
    super.autofocus,
    super.helper,
  }) : super(
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.email_outlined),
        );
}

class CpTextFieldPassword extends CpTextField {
  const CpTextFieldPassword({
    super.key,
    super.label = 'Password',
    super.hint = 'Enter your password',
    super.controller,
    super.focusNode,
    super.enabled,
    super.onChanged,
    super.onSubmitted,
    super.validator,
    super.autofocus,
    super.textInputAction,
    super.helper,
  }) : super(
          obscureText: true,
          keyboardType: TextInputType.visiblePassword,
          prefixIcon: const Icon(Icons.lock_outlined),
        );
}

class CpTextFieldPhone extends CpTextField {
  CpTextFieldPhone({
    super.key,
    super.label = 'Mobile Number',
    super.hint = 'Enter mobile number (e.g. 09XX XXX XXXX)',
    super.controller,
    super.focusNode,
    super.enabled,
    super.onChanged,
    super.onSubmitted,
    super.autofocus,
    super.helper,
  }) : super(
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.phone_android_rounded),
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(14), // 09XX XXX XXXX = 14 chars with spaces
            _PhoneNumberInputFormatter(),
          ],
          validator: Validators.requiredWith([Validators.phone], 'Mobile Number'),
        );
}

/// Custom formatter for Philippine mobile number input
/// Formats as user types: 09XX XXX XXXX
class _PhoneNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If deleting, allow it
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    // Only allow digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Limit to 11 digits (Philippine mobile format)
    if (digitsOnly.length > 11) {
      return oldValue;
    }

    // Format as 09XX XXX XXXX
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i == 4 || i == 7) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CpTextFieldName extends CpTextField {
  const CpTextFieldName({
    super.key,
    super.label = 'Name',
    super.hint = 'Enter your name',
    super.controller,
    super.focusNode,
    super.enabled,
    super.onChanged,
    super.onSubmitted,
    super.validator,
    super.autofocus,
    super.helper,
  }) : super(
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(Icons.person_outline),
        );
}

class CpTextFieldSearch extends CpTextField {
  const CpTextFieldSearch({
    super.key,
    super.hint = 'Search...',
    super.controller,
    super.focusNode,
    super.onChanged,
    super.onSubmitted,
    super.autofocus,
    super.helper,
  }) : super(
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          prefixIcon: const Icon(Icons.search),
        );
}