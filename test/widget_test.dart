import 'package:flutter_test/flutter_test.dart';
import 'package:goatguard_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const GoatGuardApp());
    expect(find.text('GOATGUARD'), findsOneWidget);
  });
}
