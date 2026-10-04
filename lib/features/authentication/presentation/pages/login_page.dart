import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/presentation/pages/forgot_password_page.dart';
import 'package:carepaw/features/authentication/presentation/pages/register_page.dart';
import 'package:carepaw/features/authentication/presentation/widgets/auth_scaffold.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';
import 'package:carepaw/app/theme/design_tokens.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          NeuToast.error(context, state.failure.message);
        } else if (state is AuthAuthenticated) {
          NeuToast.success(context, 'Welcome back, ${state.user.fullName}!');
        }
      },
      child: AuthScaffold(
        footer: Column(
          children: [
            AuthPromptLink(
              prompt: 'Don\u2019t have an account?',
              actionLabel: 'Create one',
              onTap: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
              },
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                title: 'Welcome back',
                subtitle: 'Sign in to continue to CarePaw',
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
                      textInputAction: TextInputAction.next,
                      validator: Validators.requiredWith([
                        Validators.email,
                      ], 'Email'),
                    ),
                    const SizedBox(height: NeuTokens.spaceMd),
                    NeuTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onLoginPressed(),
                      validator: Validators.requiredWith([
                        Validators.password,
                      ], 'Password'),
                    ),
                    const SizedBox(height: NeuTokens.spaceXs),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: NeuTokens.minTapTarget,
                          ),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: NeuTokens.spaceXs,
                              ),
                              child: Text(
                                'Forgot your password?',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: ThemeColors.primary(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: NeuTokens.spaceLg),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return NeuButton(
                          text: 'Sign in',
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
            ],
          ),
        ),
      ),
    );
  }
}
