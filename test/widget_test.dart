import 'package:flutter_test/flutter_test.dart';

import 'package:real_estate_crm_sales/main.dart';

void main() {
  testWidgets('shows sales login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SalesCrmApp());

    expect(find.text('Sales Workspace'), findsOneWidget);
    expect(find.text('sales@crm.local'), findsOneWidget);
    expect(find.text('Enter Workspace'), findsOneWidget);
  });
}
