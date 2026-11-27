import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('SakaySense homepage loads successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SakaySenseApp());
    await tester.pumpAndSettle();

    expect(find.text('Every passenger.\nEvery count.'), findsOneWidget);
    expect(find.text('Made simpler.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}