import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carepaw/app/theme/design_tokens.dart';
import 'package:carepaw/features/authentication/domain/entities/user.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_event.dart';
import 'package:carepaw/features/authentication/presentation/bloc/auth_state.dart';
import 'package:carepaw/features/authentication/presentation/widgets/auth_scaffold.dart';
import 'package:carepaw/core/utils/validators.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_button.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_card.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_feedback.dart';
import 'package:carepaw/core/widgets/neomorphism/neu_text_field.dart';

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
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
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
          NeuToast.error(context, state.failure.message);
        } else if (state is AuthAuthenticated) {
          NeuToast.success(
            context,
            'Welcome to CarePaw, ${state.user.fullName}!',
          );
        }
      },
      child: AuthScaffold(
        onBack: () => Navigator.of(context).pop(),
        footer: AuthPromptLink(
          prompt: 'Already have an account?',
          actionLabel: 'Sign in',
          onTap: () => Navigator.of(context).pop(),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeading(
                title: 'Join CarePaw',
                subtitle: 'Create your account to get started',
              ),
              const SizedBox(height: NeuTokens.sectionGap),
              NeuCard(
                padding: const EdgeInsets.all(NeuTokens.pagePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    NeuTextField(
                      controller: _fullNameController,
                      label: 'Full name',
                      hint: 'Alex Rivera',
                      keyboardType: TextInputType.name,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      textInputAction: TextInputAction.next,
                      validator: Validators.requiredWith([
                        Validators.name,
                      ], 'Full name'),
                    ),
                    const SizedBox(height: NeuTokens.spaceMd),
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
                      controller: _phoneController,
                      label: 'Phone',
                      hint: '09XX XXX XXXX (optional)',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_android_rounded),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: NeuTokens.spaceMd),
                    NeuTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Min 8 chars, 1 uppercase, 1 lowercase, 1 number',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      textInputAction: TextInputAction.next,
                      validator: Validators.requiredWith([
                        Validators.password,
                      ], 'Password'),
                    ),
                    const SizedBox(height: NeuTokens.spaceMd),
                    NeuAgedConfirmPasswordField(
                      label: 'Confirm password',
                      controller: _confirmPasswordController,
                      primaryController: _passwordController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onRegisterPressed(),
                    ),
                    const SizedBox(height: NeuTokens.spaceLg),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return NeuButton(
                          text: 'Create account',
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
              const SizedBox(height: NeuTokens.spaceXl),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: NeuTokens.spaceMd,
                ),
                child: Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: ThemeColors.textTertiary(context),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirm password with live mismatch feedback.
///
/// The primary field already has a helper ("min 8 characters..."), so the
/// confirm field needs one thing only: tell the user when they don't match,
/// ideally before they hit the button.
class NeuAgedConfirmPasswordField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextEditingController primaryController;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const NeuAgedConfirmPasswordField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    required this.primaryController,
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
  });

  @override
  State<NeuAgedConfirmPasswordField> createState() =>
      _NeuAgedConfirmPasswordFieldState();
}

class _NeuAgedConfirmPasswordFieldState
    extends State<NeuAgedConfirmPasswordField> {
  String? _mismatch;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_recheck);
    widget.primaryController.addListener(_recheck);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_recheck);
    widget.primaryController.removeListener(_recheck);
    super.dispose();
  }

  void _recheck() {
    final error = _mismatchFor(
      widget.controller.text,
      widget.primaryController.text,
    );
    if (error != _mismatch) {
      setState(() => _mismatch = error);
    }
  }

  String? _mismatchFor(String confirm, String primary) {
    if (confirm.isEmpty) return null;
    if (primary.isEmpty) return null;
    return confirm == primary ? null : 'Passwords don\u2019t match';
  }

  String? _requiredWithConfirm(String? value) {
    final requiredError = Validators.required(value, 'Confirm password');
    if (requiredError != null) return requiredError;
    return _mismatchFor(value ?? '', widget.primaryController.text);
  }

  @override
  Widget build(BuildContext context) {
    return NeuTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      obscureText: true,
      prefixIcon: const Icon(Icons.lock_reset_rounded),
      textInputAction: widget.textInputAction,
      error: _mismatch,
      onSubmitted: widget.onSubmitted,
      validator: _requiredWithConfirm,
    );
  }
}
