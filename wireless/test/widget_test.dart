import 'package:flutter_test/flutter_test.dart';

import 'package:wireless/main.dart';

void main() {
  testWidgets('Dashboard loads with warehouse title', (WidgetTester tester) async {
    await tester.pumpWidget(const WarehouseMonitorApp());

    expect(find.text('Warehouse Monitor'), findsOneWidget);
    expect(find.text('5G IoT Temperature Control'), findsOneWidget);
  });
}
