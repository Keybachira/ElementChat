import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:element_chat/main.dart';

void main() {
  testWidgets('ElementChat app starts', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ElementChatApp());
    await tester.pump();

    expect(find.text('ElementChat'), findsWidgets);
  });
}
