import 'package:flutter_test/flutter_test.dart';
import 'package:cafeverse_flutter/main.dart';

void main() {
  testWidgets('CafeVerseApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CafeVerseApp());

    // Verify that app renders CaféVerse title
    expect(find.text('CaféVerse'), findsWidgets);
    expect(find.text('Home'), findsWidgets);
  });
}
