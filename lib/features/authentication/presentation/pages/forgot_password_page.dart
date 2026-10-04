import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmitPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthForgotPasswordRequested(email: _emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          NeuToast.error(context, state.failure.message);
        } else if (state is AuthForgotPasswordSent) {
          NeuToast.success(
            context,
            'If an account exists with that email, a password reset link has been sent.',
          );
        }
      },
      child: AuthScaffold(
        onBack: () => Navigator.of(context).pop(),
        footer: AuthPromptLink(
          prompt: 'Remember your password?',
          actionLabel: 'Back to sign in',
          onTap: () => Navigator.of(context).pop(),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                title: 'Reset your password',
                subtitle:
                    'Enter your email and we\u2019ll send you a link to reset your password.',
              ),
              const SizedBox(height: NeuTokens.sectionGap),
              NeuCard(
                padding: const EdgeInsets.all(NeuTokens.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NeuTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.alternate_email_rounded),
                      onSubmitted: (_) => _onSubmitPressed(),
                      validator: Validators.requiredWith([
                        Validators.email,
                      ], 'Email'),
                    ),
                    const SizedBox(height: NeuTokens.spaceLg),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return NeuButton(
                          text: 'Send reset link',
                          onPressed: isLoading ? null : _onSubmitPressed,
                          isLoading: isLoading,
                          expanded: true,
                          icon: Icons.send_rounded,
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
