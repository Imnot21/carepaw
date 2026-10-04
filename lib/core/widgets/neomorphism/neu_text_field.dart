import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/design_tokens.dart';
import 'neu_container.dart';
import 'neu_style.dart';

/// Text input: a recessed well with focus and error states.
///
/// The field sits in a tinted well below the canvas, edged with a hairline that
/// turns accent-colored on focus and error-colored on validation failure.
/// Supports the full surface area — label, hint, validation, prefix/suffix
/// icons, obscure toggle, formatters.
class NeuTextField extends StatefulWidget {
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
  final EdgeInsetsGeometry? contentPadding;

  /// Optional style override.
  ///
  /// When provided, its [NeumorphicStyle.borderRadius] and
  /// [NeumorphicStyle.padding] take precedence over [contentPadding] and the
  /// hardcoded radius.
  final NeumorphicStyle? style;

  const NeuTextField({
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
    this.contentPadding,
    this.style,
  });

  @override
  State<NeuTextField> createState() => _NeuTextFieldState();
}

class _NeuTextFieldState extends State<NeuTextField> {
  bool _obscureText = false;
  bool _isFocused = false;
  String? _errorText;
  FocusNode? _internalFocusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode!.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(NeuTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.obscureText;
    }
    if (oldWidget.error != widget.error) {
      _errorText = widget.error;
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _internalFocusNode?.removeListener(_onFocusChange);
      _internalFocusNode = widget.focusNode ?? _internalFocusNode;
      _internalFocusNode!.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _internalFocusNode?.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode?.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    final hasFocus = _internalFocusNode?.hasFocus ?? false;
    if (hasFocus != _isFocused) setState(() => _isFocused = hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = _errorText != null || widget.error != null;
    final accent = ThemeColors.primary(context);
    final errorColor = ThemeColors.error(context);
    // Textfield foreground: stark max-contrast. Uses theme-aware colors for proper light/dark mode handling.
    final inputColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    final labelColor = inputColor;
    final hintColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
    final disabledLabelColor = ThemeColors.textTertiary(context);

    // Resolve radius and padding from style, falling back to token defaults.
    final resolvedRadius = widget.style?.borderRadius ?? NeuTokens.radiusMd;
    final resolvedContentPadding =
        widget.contentPadding ??
        (widget.style?.padding as EdgeInsets?) ??
        const EdgeInsets.symmetric(
          horizontal: NeuTokens.spaceMd,
          vertical: NeuTokens.spaceMd,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.labelLarge.copyWith(
              color: widget.enabled ? labelColor : disabledLabelColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          onTap: widget.onTap,
          child: NeuContainer(
            variant: NeuVariant.inset,
            borderRadius: resolvedRadius,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(resolvedRadius),
              // A well is defined by its cavity, so it carries no edge at rest.
              // Focus and error are the two states that earn a ring — WCAG
              // requires a visible focus indicator, and an error the user cannot
              // see is an error they will submit anyway. Anything less than
              // 2dp of accent is not a focus ring, it is decoration.
              side: (_isFocused || hasError)
                  ? BorderSide(
                      color: _borderColor(accent, errorColor),
                      width: 2,
                    )
                  : BorderSide.none,
            ),
            borderWidth: (_isFocused || hasError) ? 2 : 0,
            padding: EdgeInsets.zero,
            child: TextFormField(
              controller: widget.controller,
              focusNode: _internalFocusNode,
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
              onTapOutside: (_) => _internalFocusNode?.unfocus(),
              validator: _validate,
              inputFormatters: widget.inputFormatters,
              autofocus: widget.autofocus,
              style: AppTextStyles.bodyLarge.copyWith(color: inputColor),
              cursorColor: accent,
              decoration: InputDecoration(
                hintText: widget.hint,
                errorText: null,
                helperText: widget.helper,
                helperMaxLines: 2,
                counterText: '',
                contentPadding: resolvedContentPadding,
                prefixIcon: widget.prefixIcon != null
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: IconTheme(
                          data: IconThemeData(
                            color: _isFocused ? accent : hintColor,
                            size: 22,
                          ),
                          child: widget.prefixIcon!,
                        ),
                      )
                    : null,
                suffixIcon: _buildSuffixIcon(isDark, accent),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: hintColor),
                floatingLabelStyle: AppTextStyles.labelLarge.copyWith(
                  color: inputColor,
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
              style: AppTextStyles.bodySmall.copyWith(color: errorColor),
            ),
          ),
        ] else if (widget.helper != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              widget.helper!,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryOnDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Color _borderColor(Color accent, Color errorColor) {
    if (_isFocused) return accent;
    if (_errorText != null || widget.error != null) return errorColor;
    return ThemeColors.border(context);
  }

  Widget? _buildSuffixIcon(bool isDark, Color accent) {
    final iconColor = isDark ? Colors.white70 : AppColors.textSecondary;
    if (widget.obscureText) {
      return IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: _isFocused ? accent : iconColor,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
      );
    }
    if (widget.suffixIcon != null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: IconTheme(
          data: IconThemeData(color: _isFocused ? accent : iconColor, size: 22),
          child: widget.suffixIcon!,
        ),
      );
    }
    return null;
  }

  String? _validate(String? value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      if (error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _errorText = error);
        });
        return error;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _errorText = null);
    });
    return null;
  }
}
