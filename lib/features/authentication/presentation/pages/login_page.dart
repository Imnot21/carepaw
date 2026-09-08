import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/presentation/pages/register_page.dart';
import 'package:carepaw/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_shadows.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_colors.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';

/// Login page for user authentication with neumorphic design.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
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
        } else if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${state.user.fullName}!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: _isDark ? AppColors.backgroundDark : AppColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildBrand(),
                  const SizedBox(height: 40),

                  // Title
                  Text(
                    'Welcome Back',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to your CarePaw account',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Form card
                  NeuCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NeuTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                          textInputAction: TextInputAction.next,
                          validator: Validators.requiredWith([Validators.email], 'Email'),
                        ),
                        const SizedBox(height: 16),

                        NeuTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onLoginPressed(),
                          validator: Validators.requiredWith([Validators.password], 'Password'),
                        ),
                        const SizedBox(height: 8),

                        // Forgot Password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: AppTextStyles.primary(AppTextStyles.labelMedium),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login button
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            return NeuButton(
                              text: 'Sign In',
                              onPressed: isLoading ? null : _onLoginPressed,
                              isLoading: isLoading,
                              expanded: true,
                              variant: NeuButtonVariant.primary,
                              size: NeuButtonSize.large,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: _isDark ? AppColors.textTertiaryOnDark : AppColors.textTertiary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Sign Up',
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
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: NeuContainer(
            borderRadius: 28,
            variant: NeuVariant.raised,
            color: AppColors.primary,
            boxShadow: NeuShadow.color(context, AppColors.primary, blur: 18, opacity: 0.32),
            child: const Icon(Icons.pets, size: 52, color: AppColors.textOnPrimary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'CarePaw',
          style: AppTextStyles.displaySmall.copyWith(
            color: _isDark ? AppColors.textPrimaryOnDark : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Smart Veterinary Care',
          style: AppTextStyles.bodyMedium.copyWith(
            color: _isDark ? AppColors.textSecondaryOnDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}