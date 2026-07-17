// The router's auth redirect: signed-out users are held at /login, signed-in
// users are kept off it, and signing out bounces them back.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:provider/provider.dart';

import 'package:inkflow/data/repositories/auth_repository.dart';
import 'package:inkflow/data/repositories/post_repository.dart';
import 'package:inkflow/routing/router.dart';
import 'package:inkflow/ui/core/theme_controller.dart';
import 'package:inkflow/ui/features/feed/view_models/feed_view_model.dart';

import 'fakes/fake_auth_repository.dart';

Future<void> _pumpApp(ft.WidgetTester tester, FakeAuthRepository auth) async {
  final posts = MockPostRepository();
  addTearDown(posts.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: auth),
        Provider<PostRepository>.value(value: posts),
        ChangeNotifierProvider(create: (_) => FeedViewModel(posts)),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: MaterialApp.router(routerConfig: createRouter(auth)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a signed-out user lands on the login screen',
      (WidgetTester tester) async {
    final auth = FakeAuthRepository(signedIn: false);
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('a signed-in user goes straight to the feed',
      (WidgetTester tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Welcome back'), findsNothing);
    expect(find.byIcon(Icons.search), findsOneWidget); // the feed app bar
  });

  testWidgets('signing in redirects off the login screen',
      (WidgetTester tester) async {
    final auth = FakeAuthRepository(signedIn: false);
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);
    expect(find.text('Welcome back'), findsOneWidget);

    // Sign in out of band, as the login form's view model would.
    await auth.signIn(email: 'ada@example.com', password: 'longenough');
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('signing out redirects back to the login screen',
      (WidgetTester tester) async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);

    await _pumpApp(tester, auth);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Welcome back'), findsNothing);

    await auth.signOut();
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
