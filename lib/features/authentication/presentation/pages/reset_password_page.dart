import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/app/router/routes.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/presentation/widgets/auth_scaffold.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          NeuToast.error(context, state.failure.message);
        } else if (state is AuthPasswordReset) {
          NeuToast.success(context, 'Password has been reset. Please sign in.');
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(Routes.login, (route) => false);
        }
      },
      child: AuthScaffold(
        onBack: () => Navigator.of(context).pop(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                title: 'Set a new password',
                subtitle: 'Make it strong and memorable.',
              ),
              const SizedBox(height: NeuTokens.sectionGap),
              NeuCard(
                padding: const EdgeInsets.all(NeuTokens.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NeuTextField(
                      controller: _passwordController,
                      label: 'New password',
                      hint: 'Create a strong password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      textInputAction: TextInputAction.next,
                      validator: Validators.requiredWith([
                        Validators.password,
                      ], 'Password'),
                    ),
                    const SizedBox(height: NeuTokens.spaceMd),
                    NeuTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm new password',
                      hint: 'Confirm your password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onSubmitPressed(),
                      validator: (value) {
                        final requiredError = Validators.required(
                          value,
                          'Confirm password',
                        );
                        if (requiredError != null) return requiredError;
                        if (value != _passwordController.text) {
                          return 'Passwords don\u2019t match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: NeuTokens.spaceLg),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return NeuButton(
                          text: 'Reset password',
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
    );
  }
}
