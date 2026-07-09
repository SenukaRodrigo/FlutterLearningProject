import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'data/repositories/post_repository.dart';
import 'data/repositories/user_repository.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';

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
        Provider<PostRepository>(create: (_) => MockPostRepository()),
        Provider(create: (_) => UserRepository()),
      ],
      child: MaterialApp.router(
        title: 'Inkflow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
