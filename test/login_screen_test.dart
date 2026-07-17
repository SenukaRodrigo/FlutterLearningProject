// The auth form's validation, mode toggle, and error reporting, against a
// fake AuthRepository so nothing reaches Firebase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inkflow/data/repositories/auth_repository.dart';
import 'package:inkflow/ui/features/auth/view_models/login_view_model.dart';
import 'package:inkflow/ui/features/auth/views/login_screen.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  group('LoginViewModel', () {
    late FakeAuthRepository auth;
    late LoginViewModel viewModel;

    setUp(() {
      auth = FakeAuthRepository(signedIn: false);
      viewModel = LoginViewModel(auth);
    });

    tearDown(() => auth.dispose());

    test('rejects a malformed email', () {
      viewModel.updateEmail('not-an-email');
      expect(viewModel.emailError, 'Enter a valid email address.');

      viewModel.updateEmail('ada@example.com');
      expect(viewModel.emailError, isNull);
    });

    test('requires a password of at least 8 characters', () {
      viewModel.updatePassword('short');
      expect(viewModel.passwordError, 'Use at least 8 characters.');

      viewModel.updatePassword('longenough');
      expect(viewModel.passwordError, isNull);
    });

    test('submitting an invalid form never reaches the repository', () async {
      viewModel.updateEmail('ada@example.com');
      viewModel.updatePassword('short');

      expect(await viewModel.submit(), isFalse);
      expect(auth.calls, isEmpty);
    });

    test('login mode calls signIn', () async {
      viewModel.updateEmail('ada@example.com');
      viewModel.updatePassword('longenough');

      final submitting = viewModel.submit();
      expect(viewModel.isSubmitting, isTrue);

      expect(await submitting, isTrue);
      expect(viewModel.isSubmitting, isFalse);
      expect(auth.calls, ['signIn(ada@example.com)']);
    });

    test('signup mode calls signUp', () async {
      viewModel.toggleMode();
      viewModel.updateEmail('new@example.com');
      viewModel.updatePassword('longenough');

      expect(await viewModel.submit(), isTrue);
      expect(auth.calls, ['signUp(new@example.com)']);
    });

    test('an auth failure surfaces its message', () async {
      auth.nextFailure = const AuthException('Incorrect email or password.');
      viewModel.updateEmail('ada@example.com');
      viewModel.updatePassword('wrongpassword');

      expect(await viewModel.submit(), isFalse);
      expect(viewModel.errorMessage, 'Incorrect email or password.');
      expect(viewModel.isSubmitting, isFalse);
    });

    test('typing again clears a previous error', () async {
      auth.nextFailure = const AuthException('Incorrect email or password.');
      viewModel.updateEmail('ada@example.com');
      viewModel.updatePassword('wrongpassword');
      await viewModel.submit();
      expect(viewModel.errorMessage, isNotNull);

      viewModel.updatePassword('anotherguess');
      expect(viewModel.errorMessage, isNull);
    });

    test('toggling the mode switches between login and signup', () {
      expect(viewModel.isLogin, isTrue);

      viewModel.toggleMode();
      expect(viewModel.mode, AuthMode.signup);

      viewModel.toggleMode();
      expect(viewModel.mode, AuthMode.login);
    });
  });

  group('LoginScreen', () {
    late FakeAuthRepository auth;

    setUp(() => auth = FakeAuthRepository(signedIn: false));
    tearDown(() => auth.dispose());

    /// The form scrolls, so give it a surface tall enough that every field and
    /// button is laid out and tappable.
    Future<void> pumpLogin(WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        Provider<AuthRepository>.value(
          value: auth,
          child: const MaterialApp(home: LoginScreen()),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows field errors only after a submit attempt',
        (WidgetTester tester) async {
      await pumpLogin(tester);

      // An untouched form does not scold the user.
      expect(find.text('Enter your email address.'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('submit-button')));
      await tester.pump();

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
    });

    testWidgets('the mode toggle swaps the call to action',
        (WidgetTester tester) async {
      await pumpLogin(tester);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mode-toggle')));
      await tester.pump();

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
    });

    testWidgets('a rejected sign-in shows the error on the form',
        (WidgetTester tester) async {
      auth.nextFailure = const AuthException('Incorrect email or password.');
      await pumpLogin(tester);

      await tester.enterText(
          find.byKey(const ValueKey('email-field')), 'ada@example.com');
      await tester.enterText(
          find.byKey(const ValueKey('password-field')), 'wrongpassword');
      await tester.tap(find.byKey(const ValueKey('submit-button')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Incorrect email or password.'), findsOneWidget);
    });
  });
}
