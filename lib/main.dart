import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/post_repository.dart';
import 'firebase_options.dart';
import 'routing/router.dart';
import 'ui/core/theme.dart';
import 'ui/core/theme_controller.dart';
import 'ui/features/feed/view_models/feed_view_model.dart';

Future<void> main() async {
  // Required before any plugin work runs ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepository = FirebaseAuthRepository();

  // Firebase restores a persisted session asynchronously, so currentUser is
  // briefly null even for a signed-in user. Waiting for the first auth event
  // means the router's first redirect sees the settled state, instead of
  // bouncing a signed-in user to /login for a frame.
  await authRepository.currentUser.first;

  // Clean, hash-free URLs on the web so deep links look like /post/1.
  usePathUrlStrategy();
  runApp(InkflowApp(authRepository: authRepository));
}

/// Root of the Inkflow application.
class InkflowApp extends StatefulWidget {
  const InkflowApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<InkflowApp> createState() => _InkflowAppState();
}

class _InkflowAppState extends State<InkflowApp> {
  /// Built once: a GoRouter rebuilt on every frame would drop its history.
  late final GoRouter _router = createRouter(widget.authRepository);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: widget.authRepository),
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
          routerConfig: _router,
        ),
      ),
    );
  }
}
