import 'package:flutter_test/flutter_test.dart';
import 'package:mediq_app/main.dart';

void main() {
  testWidgets('MediQ App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MediQApp());

    // Verify that our title or welcome text appears
    expect(find.text('MediQ'), findsOneWidget);
    expect(find.text('OPD Queue Management'), findsOneWidget);

    // Advance time past the splash delay (1800ms)
    await tester.pump(const Duration(milliseconds: 2000));
    // Let navigation transition complete (400ms)
    await tester.pump(const Duration(milliseconds: 500));
  });
}