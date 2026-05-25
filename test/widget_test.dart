import 'package:flutter_test/flutter_test.dart';
import 'package:lookup_user/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the auth screen when there is no saved session', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => LookUpDataService()),
        ],
        child: const LookUpUserApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Encuentra tu siguiente oportunidad'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
  });
}
