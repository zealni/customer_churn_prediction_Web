import 'package:flutter_test/flutter_test.dart';
import 'package:churn_intelligence_web/main.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ChurnIntelligenceApp());
    expect(find.text('Churn AI'), findsOneWidget);
  });
}
