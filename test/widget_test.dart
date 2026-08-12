import 'package:flutter_test/flutter_test.dart';
import 'package:buyer_crm_app/main.dart';

void main() {
  testWidgets('Buyer CRM App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BuyerCRMApp());
    expect(find.text('Buyer Follow-up CRM'), findsOneWidget);
  });
}
