import 'package:flutter_test/flutter_test.dart';

import 'package:memoir_flutter/main.dart';

void main() {
  testWidgets('App renders Memoir text', (WidgetTester tester) async {
    await tester.pumpWidget(const MemoirApp());

    expect(find.text('Memoir ✨'), findsOneWidget);
  });
}
