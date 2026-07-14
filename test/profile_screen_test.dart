// The Profile tab lists the signed-in author's own posts.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inkflow/data/repositories/post_repository.dart';
import 'package:inkflow/ui/features/editor/view_models/editor_view_model.dart';
import 'package:inkflow/ui/features/profile/view_models/profile_view_model.dart';
import 'package:inkflow/ui/features/profile/views/profile_screen.dart';

/// Comfortably longer than the repository's simulated 250–500ms latency.
const Duration _pastLatency = Duration(seconds: 1);

Future<void> _pumpProfile(WidgetTester tester, PostRepository repository) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    Provider<PostRepository>.value(
      value: repository,
      child: const MaterialApp(home: ProfileScreen()),
    ),
  );
  await tester.pump(_pastLatency);
  await tester.pump();
}

void main() {
  testWidgets('shows the author and their seeded posts',
      (WidgetTester tester) async {
    final repository = MockPostRepository();
    addTearDown(repository.dispose);

    await _pumpProfile(tester, repository);

    expect(find.text('Senuka Rodrigo'), findsOneWidget);
    expect(
      find.text(
          'Writing about Flutter, design, and the craft of shipping software.'),
      findsOneWidget,
    );

    // Two of the six seeded posts are attributed to the current author.
    expect(find.text('Published posts'), findsOneWidget);
    expect(find.text('State management with Provider'), findsOneWidget);
    expect(find.text('Testing Flutter apps with confidence'), findsOneWidget);

    // ...and no one else's posts appear.
    expect(find.text('Shipping Flutter to the web'), findsNothing);

    expect(find.byKey(const ValueKey('profile-post-4')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-post-5')), findsOneWidget);
  });

  test('a post published elsewhere appears without a refetch', () async {
    final repository = MockPostRepository();
    addTearDown(repository.dispose);

    final profile = ProfileViewModel(repository);
    await Future<void>.delayed(_pastLatency);
    expect(profile.postCount, 2);

    final editor = EditorViewModel(repository)
      ..updateTitle('Straight to the profile')
      ..updateBody('Hello.');
    await editor.publish();
    await Future<void>.delayed(Duration.zero);

    expect(profile.postCount, 3);
    expect(profile.posts.first.title, 'Straight to the profile');

    profile.dispose();
  });
}
