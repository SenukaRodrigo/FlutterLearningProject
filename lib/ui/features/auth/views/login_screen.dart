import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/login_view_model.dart';

/// Widest the form grows on a desktop window.
const double _formMaxWidth = 400;

/// Auth screen at `/login`, outside the bottom-nav shell.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LoginViewModel(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  /// Field errors stay hidden until the first submit, so an untouched form
  /// doesn't greet the user with two complaints.
  bool _showErrors = false;

  Future<void> _submit() async {
    final viewModel = context.read<LoginViewModel>();

    setState(() => _showErrors = true);
    if (!viewModel.isValid) return;

    if (await viewModel.submit() && mounted) {
      // Replaces the stack rather than pushing: once signed in, Back should not
      // return to the login form.
      GoRouter.of(context).go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<LoginViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _formMaxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Wordmark(),
                  const SizedBox(height: 32),
                  Text(
                    viewModel.isLogin ? 'Welcome back' : 'Create your account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.isLogin
                        ? 'Sign in to keep writing.'
                        : 'Start publishing in minutes.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    key: const ValueKey('email-field'),
                    onChanged: viewModel.updateEmail,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _showErrors ? viewModel.emailError : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const ValueKey('password-field'),
                    onChanged: viewModel.updatePassword,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText:
                          'At least ${LoginViewModel.minPasswordLength} characters',
                      errorText: _showErrors ? viewModel.passwordError : null,
                    ),
                  ),
                  if (viewModel.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('submit-button'),
                    onPressed: viewModel.isSubmitting ? null : _submit,
                    child: viewModel.isSubmitting
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              // The button is disabled while submitting, so it
                              // sits on the disabled grey, not the primary fill.
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : Text(viewModel.isLogin ? 'Sign in' : 'Create account'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const ValueKey('mode-toggle'),
                    onPressed: viewModel.isSubmitting
                        ? null
                        : () {
                            setState(() => _showErrors = false);
                            viewModel.toggleMode();
                          },
                    child: Text(
                      viewModel.isLogin
                          ? "Don't have an account? Sign up"
                          : 'Already have an account? Sign in',
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

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.auto_stories, size: 36, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          'InkFlow',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
