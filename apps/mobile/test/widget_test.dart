import 'package:flutter_test/flutter_test.dart';
import 'package:smartkash/app/smartkash_app.dart';

void main() {
  testWidgets('SmartKash app boots to placeholder home screen', (tester) async {
    await tester.pumpWidget(const SmartKashApp());

    expect(find.text('SmartKash'), findsWidgets);
    expect(find.textContaining('Flutter skeleton ready'), findsOneWidget);
  });
}

