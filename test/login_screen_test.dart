// The auth form's validation and mode toggle.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inkflow/ui/features/auth/view_models/login_view_model.dart';
import 'package:inkflow/ui/features/auth/views/login_screen.dart';

void main() {
  group('LoginViewModel', () {
    late LoginViewModel viewModel;

    setUp(() => viewModel = LoginViewModel());

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

    test('submitting an invalid form does nothing', () async {
      viewModel.updateEmail('ada@example.com');
      viewModel.updatePassword('short');

      expect(await viewModel.submit(), isFalse);
    });

    test('submitting a valid form succeeds', () async {
      viewModel.updateEmail('ada@example.com');
      viewModel.updatePassword('longenough');
      expect(viewModel.isValid, isTrue);

      final submitting = viewModel.submit();
      expect(viewModel.isSubmitting, isTrue);

      expect(await submitting, isTrue);
      expect(viewModel.isSubmitting, isFalse);
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
    /// The form scrolls, so give it a surface tall enough that every field and
    /// button is laid out and tappable.
    Future<void> pumpLogin(WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
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
  });
}
