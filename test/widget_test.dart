import 'package:flutter_test/flutter_test.dart';
import 'package:ziesocial/main.dart';

void main() {
  testWidgets('App renders HomeView with ZieSocial title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('ZieSocial'), findsOneWidget);
  });
}
