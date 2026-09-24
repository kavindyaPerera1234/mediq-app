import 'package:flutter_test/flutter_test.dart';
import 'package:mediq_app/main.dart';

void main() {
  testWidgets('MediQ App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MediQApp());

    // Verify that our title or welcome text appears
    expect(find.text('Who are you booking for?'), findsOneWidget);
  });
}