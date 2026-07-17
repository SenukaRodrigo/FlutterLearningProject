// Basic smoke test for the Inkflow app.
//
// InkflowApp takes its AuthRepository by injection, so a signed-in fake gets
// the router past the login redirect without Firebase.

import 'package:flutter_test/flutter_test.dart';

import 'package:inkflow/main.dart';

import 'fakes/fake_auth_repository.dart';

void main() {
  testWidgets('App launches and shows the feed', (WidgetTester tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);

    await tester.pumpWidget(InkflowApp(authRepository: auth));

    // The feed app bar renders on the first frame.
    expect(find.text('InkFlow'), findsOneWidget);

    // Let the async feed load settle without throwing.
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets('a signed-out user is redirected to the login screen',
      (WidgetTester tester) async {
    final auth = FakeAuthRepository(signedIn: false);
    addTearDown(auth.dispose);

    await tester.pumpWidget(InkflowApp(authRepository: auth));
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('InkFlow'), findsWidgets); // the wordmark
  });
}
