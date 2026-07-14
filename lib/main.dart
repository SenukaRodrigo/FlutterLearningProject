import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'data/repositories/post_repository.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';
import 'ui/core/theme_controller.dart';
import 'ui/features/feed/view_models/feed_view_model.dart';

void main() {
  // Clean, hash-free URLs on the web so deep links look like /post/1.
  usePathUrlStrategy();
  runApp(const InkflowApp());
}

/// Root of the Inkflow application.
class InkflowApp extends StatelessWidget {
  const InkflowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PostRepository>(
          create: (_) => MockPostRepository(),
          dispose: (_, repository) => repository.dispose(),
        ),
        // App-scoped so the feed's filters and scroll state survive switching
        // between the bottom-nav tabs.
        ChangeNotifierProvider<FeedViewModel>(
          create: (context) => FeedViewModel(context.read<PostRepository>()),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) => MaterialApp.router(
          title: 'InkFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.themeMode,
          routerConfig: router,
        ),
      ),
    );
  }
}
