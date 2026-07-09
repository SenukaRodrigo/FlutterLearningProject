// Confirms the post detail screen renders Markdown via flutter_markdown_plus.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inkflow/data/repositories/post_repository.dart';
import 'package:inkflow/ui/features/post_detail/views/post_detail_screen.dart';

void main() {
  testWidgets('renders post body as Markdown', (WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<PostRepository>(
        create: (_) => PostRepository(),
        child: const MaterialApp(
          home: PostDetailScreen(postId: '1'),
        ),
      ),
    );

    // Let the repository's simulated async load resolve.
    await tester.pump(const Duration(milliseconds: 400));

    // The Markdown widget is present and the H1 from the post body rendered.
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('Designing with Material 3'), findsWidgets);
  });
}
