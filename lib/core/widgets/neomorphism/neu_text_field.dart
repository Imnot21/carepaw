import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import 'neu_container.dart';

/// Neumorphic text input: a sunken (inset) field with focus/error states.
///
/// Replaces the legacy Material-era text field. The field sits recessed in the
/// canvas: its inset edge shadows communicate affordance, and a primary border
/// snaps in when focused. Supports the full surface area - label, hint,
/// validation, prefix/suffix icons, obscure toggle, formatters.
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
    // Textfield foreground: stark max-contrast. Pure white on the dark field,
    // dark-navy on the light field — matching "white in dark mode, dark in light".
    final inputColor = isDark ? Colors.white : AppColors.textPrimary;
    final labelColor = inputColor;
    final hintColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final disabledLabelColor = isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary;

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
            borderRadius: 14,
            borderColor: _borderColor(accent, errorColor),
            borderWidth: (_isFocused || hasError) ? 1.6 : 1,
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
              style: AppTextStyles.bodyLarge.copyWith(
                color: inputColor,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                errorText: null,
                helperText: widget.helper,
                helperMaxLines: 2,
                counterText: '',
                contentPadding: widget.contentPadding ??
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: hintColor,
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
                color: isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
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
    return Colors.transparent;
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
          data: IconThemeData(
            color: _isFocused ? accent : iconColor,
            size: 22,
          ),
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