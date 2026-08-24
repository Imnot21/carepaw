import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/floating_animation.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';
import 'package:carepaw/core/widgets/effects/scale_on_tap.dart';

/// Reset password page - set new password using reset token.
class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
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
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Reset Password'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              boxShadow: PremiumShadows.level(context, 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        body: AnimatedGradientBackground(
          colors: [
            AppColors.success.withValues(alpha: 0.08),
            Theme.of(context).colorScheme.surface,
          ],
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 32),
                        // Premium logo with PulsingGlow
                        Center(
                          child: PulsingGlow(
                            glowColor: AppColors.success,
                            maxRadius: 25,
                            duration: const Duration(seconds: 3),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientSuccess,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: PremiumShadows.glow(context, AppColors.success, intensity: 0.4),
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                size: 54,
                                color: AppColors.textOnPrimary,
                              ),
                            ),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Glass container for form
                        GlassContainer(
                          borderRadius: 24,
                          padding: const EdgeInsets.all(28),
                          blur: 20,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                              Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderColor: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.glassBorderDark
                              : AppColors.glassBorderLight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Title
                              FloatingAnimation(
                                delay: const Duration(milliseconds: 100),
                                child: Text(
                                  'Set New Password',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 12),
                              FloatingAnimation(
                                delay: const Duration(milliseconds: 150),
                                child: Text(
                                  'Enter your new password below. Make it strong and memorable.',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Password Field
                              FloatingAnimation(
                                delay: const Duration(milliseconds: 200),
                                child: CpTextFieldPassword(
                                  controller: _passwordController,
                                  label: 'New Password',
                                  hint: 'Create a strong password',
                                  validator: Validators.requiredWith([Validators.password], 'Password'),
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password Field
                              FloatingAnimation(
                                delay: const Duration(milliseconds: 220),
                                child: CpTextFieldPassword(
                                  controller: _confirmPasswordController,
                                  label: 'Confirm New Password',
                                  hint: 'Confirm your password',
                                  validator: (value) {
                                    final requiredError = Validators.required(value, 'Confirm Password');
                                    if (requiredError != null) return requiredError;
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _onSubmitPressed(),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // Submit Button
                              FloatingAnimation(
                                delay: const Duration(milliseconds: 260),
                                child: BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    final isLoading = state is AuthLoading;
                                    return ScaleOnTap(
                                      onTap: isLoading ? null : _onSubmitPressed,
                                      child: CpButton(
                                        text: 'Reset Password',
                                        onPressed: isLoading ? null : _onSubmitPressed,
                                        isLoading: isLoading,
                                        expanded: true,
                                        size: ButtonSize.large,
                                        variant: ButtonVariant.primary,
                                        icon: Icons.check_circle_outline_rounded,
                                      ),
                                    );
                                  },
                                ),
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
          ),
        ),
      ),
    );
  }
}