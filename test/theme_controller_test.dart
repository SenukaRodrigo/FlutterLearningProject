// The dark-mode toggle in the Feed app bar.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inkflow/data/repositories/post_repository.dart';
import 'package:inkflow/ui/core/theme_controller.dart';
import 'package:inkflow/ui/features/feed/view_models/feed_view_model.dart';
import 'package:inkflow/ui/features/feed/views/feed_screen.dart';

void main() {
  testWidgets('the feed toggle flips the app between light and dark',
      (WidgetTester tester) async {
    final repository = MockPostRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PostRepository>.value(value: repository),
          ChangeNotifierProvider(create: (_) => FeedViewModel(repository)),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: Consumer<ThemeController>(
          builder: (context, controller, _) => MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: controller.themeMode,
            home: const FeedScreen(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // The test platform reports a light brightness, so the app starts light
    // and the button offers the dark theme.
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(Theme.of(tester.element(find.byType(FeedScreen))).brightness,
        Brightness.light);

    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    // MaterialApp lerps between themes via AnimatedTheme, so the new
    // brightness only lands once that animation has run.
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    expect(Theme.of(tester.element(find.byType(FeedScreen))).brightness,
        Brightness.dark);

    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(Theme.of(tester.element(find.byType(FeedScreen))).brightness,
        Brightness.light);
  });
}
