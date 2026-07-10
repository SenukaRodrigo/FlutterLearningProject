// Confirms the post detail screen renders Markdown via flutter_markdown_plus.

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:inkflow/data/repositories/post_repository.dart';
import 'package:inkflow/ui/features/post_detail/view_models/post_detail_view_model.dart';
import 'package:inkflow/ui/features/post_detail/views/post_detail_screen.dart';

void main() {
  testWidgets('renders post body as Markdown', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PostDetailViewModel(MockPostRepository(), '1'),
        child: const MaterialApp(
          home: PostDetailScreen(),
        ),
      ),
    );

    // The screen loads the post and its comments in sequence (each 250-500ms
    // of simulated latency), so advance past both before asserting.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // The Markdown widget is present and the H1 from the post body rendered.
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.text('Designing with Material 3'), findsWidgets);
  });
}
