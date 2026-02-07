// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:baby_food_app/main.dart';

void main() {
  testWidgets('App should build successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BabyFoodApp());

    // Verify the app title is displayed
    expect(find.text('이유식 분석'), findsOneWidget);
  });
}
