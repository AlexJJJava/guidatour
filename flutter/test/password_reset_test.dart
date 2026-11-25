import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidatour/app_config.dart';
import 'package:guidatour/l10n/gen/app_localizations.dart';
import 'package:guidatour/screens/auth_screen.dart';
import 'package:guidatour/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('it'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  });

  testWidgets('login: "Password dimenticata?" apre il dialog con l\'email',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const AuthScreen()));
    await tester.enterText(
        find.byType(TextFormField).first, 'mario@example.com');
    await tester.tap(find.byKey(const ValueKey('forgot-password')));
    await tester.pumpAndSettle();
    expect(find.text('Reimposta la password'), findsOneWidget);
    final dialogField = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextFormField));
    expect(tester.widget<TextFormField>(dialogField).controller!.text,
        'mario@example.com');

    // Email non valida: niente invio.
    await tester.enterText(dialogField, 'mario');
    await tester.tap(find.text('Invia link'));
    await tester.pump();
    expect(find.text('Inserisci un’email valida'), findsWidgets);
  });

  testWidgets('registrazione: il link non compare', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(const AuthScreen()));
    await tester.tap(find.text('Non hai un account? Registrati'));
    await tester.pump();
    expect(find.byKey(const ValueKey('forgot-password')), findsNothing);
  });

  testWidgets('nuova password: controlla lunghezza e conferma', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) => TextButton(
        onPressed: () => showNewPasswordDialog(context),
        child: const Text('apri'),
      ),
    )));
    appState.passwordRecovery.value = true;
    await tester.tap(find.text('apri'));
    await tester.pumpAndSettle();
    expect(find.text('Scegli una nuova password'), findsOneWidget);

    final fields = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(TextFormField));
    await tester.enterText(fields.at(0), '123');
    await tester.tap(find.text('Salva'));
    await tester.pump();
    expect(find.text('Almeno 6 caratteri'), findsOneWidget);

    await tester.enterText(fields.at(0), 'nuovaPass1');
    await tester.enterText(fields.at(1), 'diversa1');
    await tester.tap(find.text('Salva'));
    await tester.pump();
    expect(find.text('Le password non coincidono'), findsOneWidget);

    // Annulla: si chiude e la richiesta di recupero non resta appesa.
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(appState.passwordRecovery.value, isFalse);
  });
}
