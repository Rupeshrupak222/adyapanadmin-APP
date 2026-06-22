import 'package:flutter_test/flutter_test.dart';
import 'package:adyapan_admin/main.dart';
import 'package:adyapan_admin/screens/login_screen.dart';

void main() {
  testWidgets('App landing check', (WidgetTester tester) async {
    // Build our app with a mock initial screen (LoginScreen)
    await tester.pumpWidget(const AdyapanAdminApp(initialScreen: LoginScreen()));

    // Verify that the login screen title or key text exists
    expect(find.text('ADYAPAN'), findsOneWidget);
  });
}
