import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/presentation/pages/register_page.dart';
import 'package:carepaw/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_avatar.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_container.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/app_text_styles.dart';
import 'package:carepaw/app/theme/theme_colors.dart';

/// Login page for user authentication with Soft Clinic design.
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

  Widget _buildBrandHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NeuAvatar(
          radius: 40,
          icon: Icons.pets,
        ),
        const SizedBox(height: 20),
        Text(
          'CarePaw',
          style: AppTextStyles.displaySmall.copyWith(
            color: ThemeColors.textPrimary(context),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Smart veterinary care management',
          style: AppTextStyles.titleMedium.copyWith(
            color: ThemeColors.textSecondary(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        NeuContainer(
          borderRadius: 2,
          variant: NeuVariant.flat,
          color: ThemeColors.primary(context),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 2),
          child: const SizedBox(),
        ),
      ],
    );
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
              content: Text('Welcome back, ${state.user.fullName}!'),
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
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildBrandHeader(),
                  const SizedBox(height: 48),
                  _buildLoginFormCard(),
                  const SizedBox(height: 32),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Version 1.0.0',
          style: AppTextStyles.labelSmall.copyWith(
            color: ThemeColors.textSecondary(context).withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '© 2026 CarePaw Veterinary Systems',
          style: AppTextStyles.labelSmall.copyWith(
            color: ThemeColors.textSecondary(context).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFormCard() {
    return NeuCard(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: _formKey,
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: NeuButton(
                text: 'Forgot Password?',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                  );
                },
                variant: NeuButtonVariant.text,
                size: NeuButtonSize.small,
              ),
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account? ',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: ThemeColors.textSecondary(context),
                  ),
                ),
                NeuButton(
                  text: 'Sign Up',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  variant: NeuButtonVariant.text,
                  size: NeuButtonSize.small,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
