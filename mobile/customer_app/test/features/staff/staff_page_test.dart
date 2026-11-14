import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/features/staff/staff_page.dart';

void main() {
  testWidgets('StaffPage renders dealer login form when unauthenticated', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StaffPage(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Dealer workspace'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(3)); // dealer code, username, password
    expect(find.text('Sign in'), findsOneWidget);
  });
}
