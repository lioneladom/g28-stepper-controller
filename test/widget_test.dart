import 'package:flutter_test/flutter_test.dart';
import 'package:nema17_controller/main.dart';

void main() {
  testWidgets('Nema17App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const Nema17App());
    expect(find.text('Scan for Devices'), findsOneWidget);
  });
}
