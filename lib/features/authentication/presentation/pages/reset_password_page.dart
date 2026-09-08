import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_icon_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/router/routes.dart';

/// Reset password page - set new password using reset token (neumorphic design).
class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSubmitPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthResetPasswordRequested(
          token: widget.token,
          newPassword: _passwordController.text,
        ),
      );
    }
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else if (state is AuthPasswordReset) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password has been reset. Please sign in.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.login,
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: _isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: NeuIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              size: 20,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: NeuContainer(
                      borderRadius: 26,
                      variant: NeuVariant.raised,
                      color: AppColors.success,
                      boxShadow: NeuShadow.color(context, AppColors.success, blur: 16, opacity: 0.32),
                      child: const Icon(Icons.lock_reset_rounded, size: 50, color: AppColors.textOnPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CarePaw',
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Smart Veterinary Care',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  NeuCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Set New Password',
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter your new password below. Make it strong and memorable.',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        NeuTextField(
                          controller: _passwordController,
                          label: 'New Password',
                          hint: 'Create a strong password',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          textInputAction: TextInputAction.next,
                          validator: Validators.requiredWith([Validators.password], 'Password'),
                        ),
                        const SizedBox(height: 16),

                        NeuTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm New Password',
                          hint: 'Confirm your password',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onSubmitPressed(),
                          validator: (value) {
                            final requiredError = Validators.required(value, 'Confirm Password');
                            if (requiredError != null) return requiredError;
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return NeuButton(
                              text: 'Reset Password',
                              onPressed: isLoading ? null : _onSubmitPressed,
                              isLoading: isLoading,
                              expanded: true,
                              icon: Icons.check_circle_outline_rounded,
                              variant: NeuButtonVariant.primary,
                              size: NeuButtonSize.large,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}