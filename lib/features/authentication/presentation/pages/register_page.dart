import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/common/cp_button.dart';
import 'package:carepaw/core/widgets/common/cp_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/core/widgets/effects/animated_gradient.dart';
import 'package:carepaw/core/widgets/effects/glass_container.dart';
import 'package:carepaw/core/widgets/effects/premium_shadows.dart';
import 'package:carepaw/core/widgets/effects/pulsing_glow.dart';

/// Registration page for new user accounts with premium design.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

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
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _fullNameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          role: UserRole.petOwner,
        ),
      );
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pop();
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
        } else if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome to CarePaw, ${state.user.fullName}!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Create Account'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: AnimatedGradientBackground(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.primaryLight.withValues(alpha: 0.04),
            AppColors.tertiary.withValues(alpha: 0.06),
          ],
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),

                        // Logo / Brand
                        _buildLogo(),
                        const SizedBox(height: 48),

                        // Title
                        Text(
                          'Join CarePaw',
                          style: AppTextStyles.headlineLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ).primaryGlow,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your account to get started',
                          style: AppTextStyles.bodyLarge.subtleOf(Theme.of(context).brightness),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Glassmorphism Card for form
                        GlassContainer(
                          borderRadius: 24,
                          padding: const EdgeInsets.all(24),
                          blur: 20,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                              Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
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
                              // Full Name Field
                              CpTextFieldName(
                                controller: _fullNameController,
                                label: 'Full Name',
                                hint: 'John Doe',
                                helper: 'Your full name as it appears on ID',
                                validator: Validators.requiredWith([Validators.name], 'Full Name'),
                              ),
                              const SizedBox(height: 16),

                              // Email Field
                              CpTextFieldEmail(
                                controller: _emailController,
                                label: 'Email',
                                hint: 'you@example.com',
                                helper: 'We\'ll use this to sign you in',
                                validator: Validators.requiredWith([Validators.email], 'Email'),
                              ),
                              const SizedBox(height: 16),

                              // Phone Field (Optional)
                              CpTextFieldPhone(
                                controller: _phoneController,
                                label: 'Phone (Optional)',
                                hint: '09XX XXX XXXX',
                                helper: 'Philippine mobile number (optional)',
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              CpTextFieldPassword(
                                controller: _passwordController,
                                label: 'Password',
                                hint: 'Create a strong password',
                                helper: 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number',
                                validator: Validators.requiredWith([Validators.password], 'Password'),
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password Field
                              CpTextFieldPassword(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                hint: 'Confirm your password',
                                helper: 'Must match the password above',
                                validator: (value) {
                                  final requiredError = Validators.required(value, 'Confirm Password');
                                  if (requiredError != null) return requiredError;
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _onRegisterPressed(),
                              ),
                              const SizedBox(height: 24),

                              // Register Button
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  return CpButton(
                                    text: 'Create Account',
                                    onPressed: isLoading ? null : _onRegisterPressed,
                                    isLoading: isLoading,
                                    expanded: true,
                                    variant: ButtonVariant.primary,
                                    size: ButtonSize.large,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Terms & Privacy
                        Text(
                          'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                          style: AppTextStyles.bodySmall.subtleOf(Theme.of(context).brightness),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: AppTextStyles.bodyMedium.subtleOf(Theme.of(context).brightness),
                            ),
                            TextButton(
                              onPressed: _navigateToLogin,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Sign In',
                                style: AppTextStyles.primary(AppTextStyles.labelMedium).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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

  Widget _buildLogo() {
    return Column(
      children: [
        PulsingGlow(
          glowColor: AppColors.primary,
          maxRadius: 30,
          duration: const Duration(seconds: 3),
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: PremiumShadows.primary,
            ),
            child: const Icon(
              Icons.pets,
              size: 56,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'CarePaw',
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.w700,
          ).primaryGradient,
        ),
        const SizedBox(height: 4),
        Text(
          'Smart Veterinary Care',
          style: AppTextStyles.bodyMedium.subtle,
        ),
      ],
    );
  }
}