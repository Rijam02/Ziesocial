import 'package:flutter_test/flutter_test.dart';
import 'package:ziesocial/main.dart';

void main() {
  testWidgets('App renders ZieSocial Splash and navigates to LoginView',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('ZieSocial'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();

    expect(find.text('Selamat datang kembali.'), findsOneWidget);
  });
}
