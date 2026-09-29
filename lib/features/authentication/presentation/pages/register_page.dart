import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/theme_colors.dart';

/// Registration page for new user accounts with Soft Clinic design.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure.message),
              backgroundColor: ThemeColors.error(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        } else if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome to CarePaw, ${state.user.fullName}!'),
              backgroundColor: ThemeColors.success(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: ThemeColors.background(context),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 36),

                  Text(
                    'Join CarePaw',
                    style: AppTextStyles.headlineLarge.copyWith(
                      color: ThemeColors.textPrimary(context),
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account to get started',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: ThemeColors.textSecondary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  NeuCard(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NeuTextField(
                          controller: _fullNameController,
                          label: 'Full Name',
                          hint: 'John Doe',
                          helper: 'Your full name as it appears on ID',
                          keyboardType: TextInputType.name,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          textInputAction: TextInputAction.next,
                          validator: Validators.requiredWith([Validators.name], 'Full Name'),
                        ),
                        const SizedBox(height: 20),

                        NeuTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'you@example.com',
                          helper: 'We\'ll use this to sign you in',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.alternate_email_rounded),
                          textInputAction: TextInputAction.next,
                          validator: Validators.requiredWith([Validators.email], 'Email'),
                        ),
                        const SizedBox(height: 20),

                        NeuTextField(
                          controller: _phoneController,
                          label: 'Phone (Optional)',
                          hint: '09XX XXX XXXX',
                          helper: 'Philippine mobile number (optional)',
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(Icons.phone_android_rounded),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),

                        NeuTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Create a strong password',
                          helper: 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          textInputAction: TextInputAction.next,
                          validator: Validators.requiredWith([Validators.password], 'Password'),
                        ),
                        const SizedBox(height: 20),

                        NeuTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Confirm your password',
                          helper: 'Must match the password above',
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onRegisterPressed(),
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
                              text: 'Create Account',
                              onPressed: isLoading ? null : _onRegisterPressed,
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

                  Text(
                    'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ThemeColors.textTertiary(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ThemeColors.textSecondary(context),
                        ),
                      ),
                      NeuButton(
                        text: 'Sign In',
                        onPressed: () => Navigator.of(context).pop(),
                        variant: NeuButtonVariant.text,
                        size: NeuButtonSize.small,
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
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        const NeuAvatar(
          radius: 44,
          icon: Icons.pets,
        ),
        const SizedBox(height: 16),
        Text(
          'CarePaw',
          style: AppTextStyles.displaySmall.copyWith(
            color: ThemeColors.textPrimary(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Smart Veterinary Care',
          style: AppTextStyles.bodyMedium.copyWith(
            color: ThemeColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}
