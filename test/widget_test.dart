import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text_app/main.dart';

void main() {
  testWidgets('App renders main home screen and bottom navigation bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SpeechToTextApp());
    await tester.pump();

    expect(find.text('Speech Studio'), findsOneWidget);
    expect(find.text('Recorder'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);

    // Switch to Library tab
    await tester.tap(find.text('Library'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TextField), findsWidgets);
  });
}
