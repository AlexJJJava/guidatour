import 'package:flutter_test/flutter_test.dart';
import 'package:guidatour/app_config.dart';
import 'package:guidatour/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // Supabase persiste la sessione con shared_preferences: in test serve
    // un'implementazione finta del plugin (nessun canale platform nativo).
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  });

  testWidgets('mostra la schermata di avvio mentre carica i dati dal backend',
      (tester) async {
    await tester.pumpWidget(const GuidaTourApp());
    // Prima che la chiamata di rete a /tours e /guides risponda, l'app
    // mostra lo stato di caricamento invece di un albero vuoto o un crash.
    expect(find.text('Sveglio il backend…'), findsOneWidget);
  });
}
