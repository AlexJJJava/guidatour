import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidatour/main.dart';
import 'package:guidatour/models.dart';
import 'package:guidatour/state.dart';

void main() {
  setUp(appState.logout);
  authTests();
  touristTests();
  testWidgets('home mostra i tour di Roma e si apre l\'area guide',
      (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GuidaTourApp());
    expect(find.text('Prossimi tour a Roma'), findsOneWidget);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Accedi o registrati'), findsOneWidget);
  });

  test('regole di dominio: overbooking e assegnazione', () {
    final s = AppState();
    // Colosseo: 4 posti, 5 persone richieste nei dati demo.
    expect(
        s.overbookingAlerts('g1').any((a) => a.contains('Colosseo')), isTrue);
    final t = s.tourById('colosseo-foro')!;
    s.proposeAssignment(t, s.guideById('g2')!);
    s.respond(s.assignments.first, true);
    expect(s.assignments.first.status, AssignmentStatus.accettato);
    expect(s.notifications.last, contains('accettato'));
  });
}

void authTests() {
  testWidgets('login social: primo accesso chiede il ruolo e crea l\'account',
      (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const GuidaTourApp());
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Continua con Google'), findsOneWidget);
    expect(find.text('Continua con Facebook'), findsOneWidget);
    await tester.tap(find.text('Continua con Google'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Completa il profilo'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continua'));
    await tester.pumpAndSettle();
    expect(appState.currentUser?.provider, 'google');
    expect(find.textContaining('Ciao Utente Google'), findsOneWidget);
  });
}

void touristTests() {
  test('turista: preferiti, carrello, storico e conferma della guida', () {
    final s = AppState();
    s.loginAs(s.guideById('g5')!);
    expect(s.isTourist, isTrue);

    s.toggleFavorite('colosseo-foro');
    expect(s.isFavorite('colosseo-foro'), isTrue);
    expect(s.favoriteTours.single.id, 'colosseo-foro');

    s.addToCart('trastevere-sera');
    s.addToCart('trastevere-sera'); // niente duplicati
    s.addToCart('roma-gusto');
    expect(s.cart.length, 2);
    s.setCartPeople(s.cart.first, 3);
    expect(s.cartTotal, 22 * 3 + 45 * 2);

    expect(s.checkoutCart(), 2);
    expect(s.cart, isEmpty);
    expect(s.myRequests.length, 2);
    expect(s.myRequests.first.status, 'Inviata');

    // La guida conferma: il turista vede lo stato aggiornato.
    s.setRequestStatus(s.myRequests.first, 'Confermata');
    expect(s.myRequests.first.status, 'Confermata');

    // I dati sono per utente: un altro account non vede questo carrello.
    s.loginAs(s.guideById('g1')!);
    expect(s.favoriteTours, isEmpty);
    expect(s.myRequests, isEmpty);
  });
}
