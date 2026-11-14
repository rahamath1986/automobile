import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motosaas_customer/core/widgets/login_required.dart';
import 'package:motosaas_customer/core/widgets/status_chip.dart';
import 'package:motosaas_customer/features/catalog/presentation/widgets/vehicle_card.dart';

import 'features/catalog/fixtures.dart';

void main() {
  testWidgets('StatusChip humanises backend status values', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: StatusChip(status: 'WORK_IN_PROGRESS'))),
      ),
    );

    expect(find.text('Work In Progress'), findsOneWidget);
  });

  testWidgets('VehicleCard renders model name, price and category', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleCard(
            model: modelFixture('model-1', name: 'R15 V4'),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('R15 V4'), findsOneWidget);
    expect(find.textContaining('₹1,80,000'), findsOneWidget);
    expect(find.text('Motorcycle'), findsOneWidget);
  });

  testWidgets('LoginRequired shows the sign-in call to action', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoginRequired(
            title: 'Sign in to see your activity',
            message: 'Track enquiries and test rides.',
            redirect: '/activity',
          ),
        ),
      ),
    );

    expect(find.text('Sign in to see your activity'), findsOneWidget);
    expect(find.text('Sign in with mobile'), findsOneWidget);
  });
}
