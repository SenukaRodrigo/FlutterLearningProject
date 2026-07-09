// Basic smoke test for the Inkflow app.

import 'package:flutter_test/flutter_test.dart';

import 'package:inkflow/main.dart';

void main() {
  testWidgets('App launches and shows the feed', (WidgetTester tester) async {
    await tester.pumpWidget(const InkflowApp());

    // The feed app bar renders on the first frame.
    expect(find.text('InkFlow'), findsOneWidget);

    // Let the async feed load settle without throwing.
    await tester.pump(const Duration(milliseconds: 500));
  });
}
