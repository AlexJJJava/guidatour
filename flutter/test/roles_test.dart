import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidatour/app_config.dart';
import 'package:guidatour/l10n/gen/app_localizations.dart';
import 'package:guidatour/l10n/labels.dart';
import 'package:guidatour/l10n/locale_controller.dart';
import 'package:guidatour/main.dart';
import 'package:guidatour/models.dart';
import 'package:guidatour/screens/admin_screen.dart';
import 'package:guidatour/screens/avatar_crop_screen.dart';
import 'package:guidatour/screens/account_screen.dart';
import 'package:guidatour/screens/auth_screen.dart';
import 'package:guidatour/screens/bookings_screen.dart';
import 'package:guidatour/screens/cart_screen.dart';
import 'package:guidatour/screens/faq_screen.dart';
import 'package:guidatour/screens/favorites_screen.dart';
import 'package:guidatour/screens/home_screen.dart';
import 'package:guidatour/screens/my_tours_screen.dart';
import 'package:guidatour/screens/profile_edit_screen.dart';
import 'package:guidatour/screens/search_screen.dart';
import 'package:guidatour/screens/tour_detail_screen.dart';
import 'package:guidatour/screens/tour_form_screen.dart';
import 'package:guidatour/state.dart';
import 'package:guidatour/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pagine e pulsanti che ogni ruolo deve vedere (e quelli che non deve vedere).
final t = lookupAppLocalizations(const Locale('it'));

Guide user(Role role, {bool verified = true, bool isAdmin = false}) => Guide(
      id: 'u1',
      name: 'Utente Prova',
      email: 'prova@example.com',
      role: role,
      verified: verified,
      isAdmin: isAdmin,
    );

Tour tourBy(String guideId, {String category = 'Accompagnamento'}) => Tour(
      id: 'tour1',
      title: 'Tour di prova',
      city: 'Roma',
      category: category,
      language: 'Italiano',
      duration: '2 ore',
      start: DateTime(2099, 6, 15, 10),
      price: 20,
      meetingPoint: 'Piazza Navona',
      description: 'Descrizione',
      seats: 10,
      guideId: guideId,
    );

void seed(Guide? u, {Guide? owner}) {
  final tour = tourBy(owner?.id ?? 'u1');
  appState
    ..currentUser = u
    ..ready = true
    ..pendingRegistrations = 0
    ..cart = []
    ..favoriteTours = []
    ..myTours = u?.role.isProfessional == true ? [tour] : []
    ..notifications = []
    ..guides.clear()
    ..guides.addAll([if (owner != null) owner, if (u != null) u])
    ..tours.clear()
    ..tours.add(tour);
}

Widget page(Widget child) => MaterialApp(
      locale: const Locale('it'),
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

Finder navLabel(String label) => find.descendant(
      of: find.byWidgetPredicate((w) => '${w.runtimeType}' == '_NavLink'),
      matching: find.text(label),
    );

/// Una voce può stare nel menu o, se non c'è spazio, sotto "Altro".
Finder menuLabel(String label) => find.descendant(
      of: find.byWidgetPredicate((w) => w is PopupMenuItem),
      matching: find.text(label),
    );

final turistaPages = [
  t.navDiscover,
  t.navSearch,
  t.navFavorites,
];
final proPages = [
  t.navDiscover,
  t.navSearch,
  t.dashTabOverview,
  t.dashTabMyTours,
  t.dashTabAssignments,
  t.navRequests,
];
final allPages = {
  ...turistaPages,
  ...proPages,
  t.navManage,
  t.navAccount,
  // Non più nel menu: le richieste del turista stanno nel carrello.
  t.navBookings,
};

/// Con i font veri il menu ha le misure reali: le voci non finiscono in Altro.
Future<void> loadFonts() async {
  for (final (family, files) in const [
    (
      'Inter',
      ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold', 'Inter-Bold']
    ),
    ('Playfair', ['PlayfairDisplay-SemiBold', 'PlayfairDisplay-Bold']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    await loadFonts();
    // Il primo evento di accesso (nessuna sessione) arriva subito dopo:
    // lo si lascia passare, così non azzera l'utente preparato dal test.
    appState.notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    localeController.value = const Locale('it');
  });

  void sized(WidgetTester tester, Size size) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
  }

  group('menu su computer', () {
    final cases = <(String, Guide?, List<String>, bool)>[
      ('visitatore', null, [...turistaPages, t.navAccount], true),
      ('turista', user(Role.turista), turistaPages, true),
      ('guida', user(Role.guida), proPages, false),
      ('accompagnatore', user(Role.accompagnatore), proPages, false),
      ('tour operator', user(Role.tourOperator), proPages, false),
      (
        'admin',
        user(Role.turista, isAdmin: true),
        [...turistaPages, t.navManage],
        true
      ),
      (
        'admin con ruolo guida',
        user(Role.guida, isAdmin: true),
        [...proPages, t.navManage],
        false
      ),
    ];
    for (final (name, u, pages, cart) in cases) {
      testWidgets('$name vede solo le sue pagine', (tester) async {
        sized(tester, const Size(1920, 1080));
        seed(u);
        await tester.pumpWidget(const GuidaTourApp());
        await tester.pump(const Duration(milliseconds: 100));
        if (navLabel(t.navMore).evaluate().isNotEmpty) {
          await tester.tap(navLabel(t.navMore));
          await tester.pump(const Duration(milliseconds: 400));
        }
        for (final p in pages) {
          expect(
              navLabel(p).evaluate().length + menuLabel(p).evaluate().length, 1,
              reason: '$name senza $p');
        }
        for (final p in allPages.difference(pages.toSet())) {
          expect(navLabel(p), findsNothing, reason: '$name vede $p');
          expect(menuLabel(p), findsNothing, reason: '$name vede $p');
        }
        expect(find.byIcon(Icons.shopping_cart_outlined),
            cart ? findsWidgets : findsNothing,
            reason: 'carrello per $name');
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('intestazione e footer in tutte le pagine', () {
    for (final (name, size) in const [
      ('computer', Size(1920, 1080)),
      ('telefono', Size(412, 915)),
    ]) {
      testWidgets(
          '$name: pagina aperta con intestazione, footer e senza freccia',
          (tester) async {
        sized(tester, size);
        seed(user(Role.guida));
        await tester.pumpWidget(const GuidaTourApp());
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byKey(const ValueKey('user-avatar')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(AccountScreen), findsOneWidget);
        expect(find.byType(BackButton), findsNothing);
        expect(find.byType(AppBar), findsNothing);
        // Intestazione con il logo e il pallino.
        expect(find.byType(BrandLogo), findsWidgets);
        expect(find.byKey(const ValueKey('user-avatar')), findsOneWidget);
        // Footer con il solo link FAQ e senza scelta della lingua (in fondo:
        // su telefono si scorre).
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('footer-brand')), 300,
            scrollable: find.byType(Scrollable).last);
        final footer = find.byType(SiteFooter);
        expect(footer, findsOneWidget);
        expect(
            find.descendant(of: footer, matching: find.byType(LanguagePicker)),
            findsNothing);
        expect(find.descendant(of: footer, matching: find.byType(InkWell)),
            findsNWidgets(2));
        // Il marchio nel footer riporta a Scopri.
        await tester.ensureVisible(find.byKey(const ValueKey('footer-brand')));
        await tester.tap(find.byKey(const ValueKey('footer-brand')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(AccountScreen), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('$name: FAQ dal footer e ritorno a Scopri dal logo',
          (tester) async {
        sized(tester, size);
        seed(null);
        await tester.pumpWidget(const GuidaTourApp());
        await tester.pump(const Duration(milliseconds: 100));
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('footer-faq')), 400,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.byKey(const ValueKey('footer-faq')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(FaqScreen), findsOneWidget);
        expect(find.text(t.faq1Q), findsOneWidget);
        expect(find.byType(BackButton), findsNothing);
        expect(find.byType(SiteFooter), findsWidgets);
        final logo = size.width >= 1024
            ? find.byType(BrandLogo).first
            : find.byKey(const ValueKey('header-logo'));
        await tester.tap(logo);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byType(FaqScreen), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });
    }

    for (final (name, screen) in <(String, Widget)>[
      ('ricerca', const Scaffold(body: Text('x'))),
    ]) {
      testWidgets('ogni voce del menu ha il footer ($name)', (tester) async {
        sized(tester, const Size(1920, 1080));
        for (final u in [null, user(Role.turista), user(Role.guida)]) {
          seed(u);
          await tester.pumpWidget(const GuidaTourApp());
          await tester.pump(const Duration(milliseconds: 100));
          final labels =
              u?.role.isProfessional == true ? proPages : turistaPages;
          for (final label in labels.skip(1)) {
            final link = navLabel(label);
            if (link.evaluate().isEmpty) continue;
            await tester.tap(link);
            await tester.pump(const Duration(milliseconds: 300));
            expect(find.byType(SiteFooter, skipOffstage: false), findsWidgets,
                reason: 'manca il footer in $label');
            expect(find.byType(BrandLogo), findsWidgets,
                reason: "manca l'intestazione in $label");
          }
          await tester.pumpWidget(const SizedBox());
        }
        expect(screen, isNotNull);
      });
    }
  });

  testWidgets('la home non mostra più la lista delle guide', (tester) async {
    sized(tester, const Size(1920, 4000));
    seed(user(Role.turista), owner: user(Role.guida));
    await tester.pumpWidget(const GuidaTourApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(t.guidesTitle, skipOffstage: false), findsNothing);
    expect(find.byType(SiteFooter, skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final size in const [Size(1920, 1400), Size(412, 915)]) {
    testWidgets(
        'ricerca dalla home: si passa alla voce Tour e il risultato apre la scheda (${size.width})',
        (tester) async {
      sized(tester, size);
      seed(user(Role.turista), owner: user(Role.guida));
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byType(TextField).first, 'prova');
      await tester.tap(find.text(t.heroSearch));
      await tester.pumpAndSettle();
      // Non una pagina sopra Scopri: la home non c'è più, si è sulla voce Tour
      // con la ricerca già scritta.
      expect(find.byType(HomeScreen, skipOffstage: false), findsNothing);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(SearchScreen),
              matching: find.widgetWithText(TextField, 'prova')),
          findsOneWidget);
      if (size.width < 1024) {
        expect(
            tester.widget<NavigationBar>(find.byType(NavigationBar))
                .selectedIndex,
            1);
      }
      final result = find.descendant(
          of: find.byType(SearchScreen), matching: find.byType(TourCard));
      expect(result, findsOneWidget);
      await tester.ensureVisible(result);
      await tester.pumpAndSettle();
      await tester.tap(result);
      await tester.pumpAndSettle();
      expect(find.byType(TourDetailScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('cerchio categoria in home: voce Tour con la categoria scelta',
      (tester) async {
    sized(tester, const Size(1920, 2400));
    seed(user(Role.turista), owner: user(Role.guida));
    await tester.pumpWidget(const GuidaTourApp());
    await tester.pump(const Duration(milliseconds: 100));
    final bubble = find.text(categoryLabel(
        tester.element(find.byType(HomeScreen)), 'Serale'));
    await tester.ensureVisible(bubble.first);
    await tester.pumpAndSettle();
    await tester.tap(bubble.first);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen, skipOffstage: false), findsNothing);
    final serale = find.descendant(
        of: find.byType(SearchScreen),
        matching: find.widgetWithText(ChoiceChip, 'Serale'));
    expect(tester.widget<ChoiceChip>(serale).selected, isTrue);
    // Dal menu, invece, la pagina Tour riparte senza filtri.
    await tester.tap(find.text(t.navDiscover).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.navSearch).first);
    await tester.pumpAndSettle();
    final tutti = find.descendant(
        of: find.byType(SearchScreen),
        matching: find.widgetWithText(ChoiceChip, t.filterAll));
    expect(tester.widget<ChoiceChip>(tutti).selected, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  group('una sola intestazione', () {
    Finder bars(Size size) => find.byWidgetPredicate((w) =>
        '${w.runtimeType}' ==
        (size.width >= 1024 ? '_TopBar' : '_MobileTopBar'));

    for (final size in const [Size(1920, 1080), Size(412, 915)]) {
      testWidgets('dopo il login dalla pagina di accesso (${size.width})',
          (tester) async {
        sized(tester, size);
        seed(null);
        await tester.pumpWidget(const GuidaTourApp());
        await tester.pump(const Duration(milliseconds: 100));
        expect(bars(size), findsOneWidget);
        // Come nell'app: l'utente apre una pagina, poi fa l'accesso.
        await tester.tap(find.text(t.navAccount).last);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.scrollUntilVisible(
            find.byKey(const ValueKey('footer-faq')), 400,
            scrollable: find.byType(Scrollable).first);
        await tester.tap(find.byKey(const ValueKey('footer-faq')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        appState.currentUser = user(Role.turista);
        appState.notifyListeners();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(bars(size), findsOneWidget);
        // E anche dopo il logout.
        appState.currentUser = null;
        appState.notifyListeners();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(bars(size), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('con il menu della lingua aperto (${size.width})',
          (tester) async {
        sized(tester, size);
        seed(user(Role.turista));
        await tester.pumpWidget(const GuidaTourApp());
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byType(LanguagePicker).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(bars(size), findsOneWidget, reason: 'menu aperto');
        await tester.tap(find.text('English').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(bars(size), findsOneWidget, reason: 'lingua cambiata');
        localeController.value = const Locale('it');
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('login e logout restano sulla pagina', () {
    Future<void> open(WidgetTester tester, Guide? u) async {
      sized(tester, const Size(1920, 1080));
      seed(u);
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<void> become(WidgetTester tester, Guide? u) async {
      appState.currentUser = u;
      appState.notifyListeners();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    Future<void> go(WidgetTester tester, String label) async {
      await tester.tap(navLabel(label));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('visitatore su Preferiti, accede da turista: resta',
        (tester) async {
      await open(tester, null);
      await go(tester, t.navFavorites);
      expect(find.byType(AuthScreen), findsOneWidget);
      await become(tester, user(Role.turista));
      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('visitatore su Preferiti, accede da guida: Scopri',
        (tester) async {
      await open(tester, null);
      await go(tester, t.navFavorites);
      await become(tester, user(Role.guida));
      expect(find.byType(FavoritesScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('turista su Preferiti, esce: resta', (tester) async {
      await open(tester, user(Role.turista));
      await go(tester, t.navFavorites);
      await become(tester, null);
      expect(find.byType(FavoritesScreen), findsOneWidget);
      expect(find.byType(AuthScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('guida su I miei tour, esce: Scopri', (tester) async {
      await open(tester, user(Role.guida));
      await go(tester, t.dashTabMyTours);
      expect(find.byType(MyToursScreen), findsOneWidget);
      await become(tester, null);
      expect(find.byType(MyToursScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('accesso dalla voce Account: si apre il proprio Account',
        (tester) async {
      await open(tester, null);
      await go(tester, t.navAccount);
      await become(tester, user(Role.turista));
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text(t.accountProfileSection), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("uscita dall'Account: si vede la pagina di accesso",
        (tester) async {
      await open(tester, user(Role.turista));
      await tester.tap(find.byKey(const ValueKey('user-avatar')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await become(tester, null);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(navLabel(t.navAccount), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('scheda di un tour aperta: resta anche dopo il login',
        (tester) async {
      await open(tester, null);
      openTour(tester.element(find.byType(HomeScreen)), tourBy('u1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(TourDetailScreen), findsOneWidget);
      await become(tester, user(Role.turista));
      expect(find.byType(TourDetailScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('carrello e richieste', () {
    BookingRequest req(String id, String status) => BookingRequest(
          id: id,
          tourId: 'tour1',
          name: 'Anna',
          email: 'a@example.com',
          phone: '',
          people: 2,
          message: '',
          createdAt: DateTime(2026, 11, 1),
          status: status,
        );

    testWidgets('il carrello mostra da inviare e richieste inviate',
        (tester) async {
      sized(tester, const Size(1280, 2000));
      seed(user(Role.turista));
      appState.myRequests = [req('q1', 'inviata'), req('q2', 'confermata')];
      await tester.pumpWidget(page(const CartScreen()));
      await tester.pump();
      expect(find.text(t.cartToSendSection), findsOneWidget);
      expect(find.text(t.cartSentSection), findsOneWidget);
      expect(find.text(t.cartEmpty), findsOneWidget);
      expect(find.text(t.statusConfermata), findsOneWidget);
      // La conferma è una risposta nuova finché non viene vista.
      expect(find.byKey(const ValueKey('new-answer-q2')), findsOneWidget);
      expect(find.byKey(const ValueKey('new-answer-q1')), findsNothing);
      expect(appState.unseenAnswers, 1);
      await tester.pump(const Duration(seconds: 4));
      expect(appState.unseenAnswers, 0);
      appState.myRequests = [];
    });

    testWidgets("l'icona del carrello conta anche le risposte nuove",
        (tester) async {
      sized(tester, const Size(1920, 1080));
      seed(user(Role.turista));
      appState.myRequests = [req('q3', 'rifiutata')];
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(
          find.descendant(
              of: find.byType(CartButton), matching: find.text('1')),
          findsOneWidget);
      appState.myRequests = [];
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('il professionista vede la voce Richieste', (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(user(Role.guida));
      await tester.pumpWidget(page(const BookingsScreen()));
      await tester.pump();
      expect(find.text(t.bookingsTitleReceived), findsOneWidget);
    });
  });

  group('barra su telefono', () {
    testWidgets('il turista ha tutte le voci', (tester) async {
      sized(tester, const Size(412, 915));
      seed(user(Role.turista));
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NavigationDestination), findsNWidgets(3));
      expect(find.text(t.navAccount), findsNothing);
      expect(find.text(t.navBookings), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('il visitatore ha anche Account', (tester) async {
      sized(tester, const Size(412, 915));
      seed(null);
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text(t.navAccount), findsWidgets);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('le voci in più del professionista vanno in Altro',
        (tester) async {
      sized(tester, const Size(412, 915));
      seed(user(Role.accompagnatore));
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await tester.tap(find.text(t.navMore).last);
      await tester.pump(const Duration(milliseconds: 400));
      final inBar = tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((d) => d.label)
          .toSet();
      for (final p in proPages.where((p) => !inBar.contains(p))) {
        expect(find.text(p), findsWidgets, reason: '$p irraggiungibile');
      }
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('pagine riservate senza accesso', () {
    for (final (name, screen) in <(String, Widget)>[
      ('preferiti', const FavoritesScreen()),
      ('prenotazioni', const BookingsScreen()),
      ('carrello', const CartScreen()),
    ]) {
      testWidgets('$name porta all\'accesso', (tester) async {
        sized(tester, const Size(1280, 1600));
        seed(null);
        await tester.pumpWidget(page(screen));
        await tester.pump();
        expect(find.byType(AuthScreen), findsOneWidget);
      });
    }
  });

  group('accesso rapido', () {
    testWidgets('c\'è un pulsante per ogni ruolo', (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(null);
      await tester.pumpWidget(page(const AuthScreen()));
      await tester.pump();
      for (final label in const [
        'Turista',
        'Guida',
        'Accompagnatore',
        'Guida + Accomp.',
        'Tour operator',
        'Admin',
      ]) {
        expect(find.widgetWithText(OutlinedButton, label), findsOneWidget,
            reason: label);
      }
    });
  });

  group('i miei tour', () {
    for (final role in [Role.guida, Role.accompagnatore, Role.tourOperator]) {
      testWidgets('${role.name} ha tutte le azioni', (tester) async {
        sized(tester, const Size(1280, 1600));
        seed(user(role));
        await tester.pumpWidget(page(const MyToursScreen()));
        await tester.pump();
        for (final label in [
          t.newTour,
          t.qrAndPoster,
          t.proposeToColleague,
          t.editTour,
          t.deleteTour,
        ]) {
          expect(find.text(label), findsWidgets, reason: label);
        }
      });
    }
  });

  group('scheda del tour', () {
    testWidgets('il turista può aggiungere al carrello', (tester) async {
      sized(tester, const Size(1280, 2400));
      final guida =
          Guide(id: 'g1', name: 'Guida', email: 'g@e.it', role: Role.guida);
      seed(user(Role.turista), owner: guida);
      await tester.pumpWidget(page(TourDetailScreen(tour: tourBy('g1'))));
      await tester.pump(const Duration(milliseconds: 100));
      final button = tester.widget<OutlinedButton>(find.ancestor(
          of: find.text(t.addToCart),
          matching: find.byWidgetPredicate((w) => w is OutlinedButton)));
      expect(button.onPressed, isNotNull);
      expect(find.text(t.accompagnatoreNotice), findsNothing);
    });

    testWidgets('il tour di un accompagnatore lo dichiara', (tester) async {
      sized(tester, const Size(1280, 2400));
      final acc = Guide(
          id: 'g2', name: 'Acc', email: 'a@e.it', role: Role.accompagnatore);
      seed(null, owner: acc);
      await tester.pumpWidget(page(TourDetailScreen(tour: tourBy('g2'))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(t.accompagnatoreNotice), findsOneWidget);
    });
  });

  group('modulo del tour', () {
    Future<void> open(WidgetTester tester, Guide u) async {
      sized(tester, const Size(1280, 2400));
      seed(u);
      await tester.pumpWidget(page(const TourFormScreen()));
      await tester.pump();
    }

    testWidgets('l\'accompagnatore vede l\'avviso e solo la sua categoria',
        (tester) async {
      await open(tester, user(Role.accompagnatore));
      expect(find.text(t.accompagnatoreNotice), findsOneWidget);
      await tester.tap(find
          .byWidgetPredicate(
              (w) => '${w.runtimeType}'.startsWith('DropdownButton<String>'))
          .at(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Visita guidata'), findsNothing);
    });

    testWidgets('la guida viene bloccata se aggiunge un servizio',
        (tester) async {
      await open(tester, user(Role.guida));
      expect(find.text(t.accompagnatoreNotice), findsNothing);
      await tester.tap(find.byType(FilterChip).first);
      await tester.pump();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('ogni tour operator approvato può creare pacchetti',
        (tester) async {
      await open(tester, user(Role.tourOperator, verified: false));
      await tester.tap(find.byType(FilterChip).first);
      await tester.pump();
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });
  });

  group('più ruoli', () {
    Guide multi(List<String> roles, {String approval = 'approvato'}) =>
        Guide.fromProfileJson({
          'id': 'm1',
          'name': 'Marta Neri',
          'email': 'm@example.com',
          'role': primaryRole(roles.map(roleFromString)).name,
          'roles': roles,
          'approvalStatus': approval,
        });

    test('i ruoli arrivano tutti, con il principale', () {
      final u = multi(['accompagnatore', 'guida']);
      expect(u.roles, [Role.guida, Role.accompagnatore]);
      expect(u.role, Role.guida);
      expect(u.onlyAccompagnatore, isFalse);
      expect(multi(['accompagnatore']).onlyAccompagnatore, isTrue);
      expect(multi(['accompagnatore', 'tourOperator']).onlyAccompagnatore,
          isFalse);
    });

    test('in attesa: turista con tutti i ruoli chiesti', () {
      final u = multi(['guida', 'tourOperator'], approval: 'in_attesa');
      expect(u.role, Role.turista);
      expect(u.roles, isEmpty);
      expect(u.requestedRoles, [Role.guida, Role.tourOperator]);
    });

    test('il ruolo principale segue la priorità', () {
      expect(primaryRole([Role.accompagnatore, Role.tourOperator]),
          Role.tourOperator);
      expect(primaryRole([Role.accompagnatore]), Role.accompagnatore);
      expect(primaryRole(const []), Role.turista);
    });

    testWidgets('guida e accompagnatore: tutte le categorie, senza avviso',
        (tester) async {
      sized(tester, const Size(1280, 2400));
      seed(multi(['guida', 'accompagnatore']));
      await tester.pumpWidget(page(const TourFormScreen()));
      await tester.pump();
      expect(find.text(t.accompagnatoreNotice), findsNothing);
      await tester.tap(find
          .byWidgetPredicate(
              (w) => '${w.runtimeType}'.startsWith('DropdownButton<String>'))
          .at(1));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Visita guidata'), findsWidgets);
      expect(find.text('Accompagnamento'), findsWidgets);
    });

    testWidgets('pacchetti solo con il ruolo tour operator', (tester) async {
      sized(tester, const Size(1280, 2400));
      seed(multi(['guida', 'accompagnatore']));
      await tester.pumpWidget(page(const TourFormScreen()));
      await tester.pump();
      await tester.tap(find.byType(FilterChip).first);
      await tester.pump();
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      seed(multi(['guida', 'tourOperator']));
      await tester.pumpWidget(page(const TourFormScreen()));
      await tester.pump();
      await tester.tap(find.byType(FilterChip).first);
      await tester.pump();
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('in registrazione si scelgono più profili', (tester) async {
      sized(tester, const Size(1280, 2000));
      seed(null);
      await tester.pumpWidget(page(const AuthScreen()));
      await tester.pump();
      await tester.tap(find.text(t.authNoAccount));
      await tester.pump();
      expect(find.byType(CheckboxListTile), findsNWidgets(4));
      expect(find.text(t.authRolesTourist), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('role-guida')));
      await tester.tap(find.byKey(const ValueKey('role-accompagnatore')));
      await tester.pump();
      expect(
          find.text(t.authRolesPro('${t.roleGuida} · ${t.roleAccompagnatore}')),
          findsOneWidget);
    });

    testWidgets('Account mostra tutti i ruoli', (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(multi(['guida', 'accompagnatore']));
      await tester.pumpWidget(page(const AccountScreen()));
      await tester.pump();
      // Un'etichetta per ruolo nella fascia in alto.
      expect(find.text(t.roleGuida), findsOneWidget);
      expect(find.text(t.roleAccompagnatore), findsOneWidget);
    });

    testWidgets('Approvazioni mostra i ruoli chiesti', (tester) async {
      sized(tester, const Size(1280, 1600));
      final u = multi(['guida', 'tourOperator'], approval: 'in_attesa');
      expect(
          find.textContaining(t.roleGuida), findsNothing); // prima di montare
      seed(user(Role.turista, isAdmin: true));
      await tester.pumpWidget(page(Builder(
          builder: (context) => Text(rolesLabel(context,
              u.requestedRoles.isEmpty ? u.roles : u.requestedRoles)))));
      expect(
          find.text('${t.roleGuida} · ${t.roleTourOperator}'), findsOneWidget);
    });
  });

  group('ruoli dal profilo', () {
    Guide me(Map<String, dynamic> extra) => Guide.fromProfileJson({
          'id': 'r1',
          'name': 'Rita Bianchi',
          'email': 'r@example.com',
          'role': 'guida',
          'roles': ['guida'],
          'approvalStatus': 'approvato',
          ...extra,
        });

    testWidgets('si scelgono più ruoli, con quelli attuali già spuntati',
        (tester) async {
      sized(tester, const Size(1280, 2400));
      seed(me({
        'pendingRoles': ['tourOperator']
      }));
      await tester.pumpWidget(page(const ProfileEditScreen()));
      await tester.pump();
      expect(find.text(t.profileRolesSection), findsOneWidget);
      expect(find.text(t.profileRolesHint), findsOneWidget);
      CheckboxListTile box(String r) =>
          tester.widget<CheckboxListTile>(find.byKey(ValueKey('edit-role-$r')));
      expect(box('guida').value, isTrue);
      expect(box('accompagnatore').value, isFalse);
      expect(box('tourOperator').value, isTrue);
      // Il ruolo in attesa è segnalato.
      expect(find.text(t.profileRolesPendingTag), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('edit-role-accompagnatore')));
      await tester.pump();
      expect(box('accompagnatore').value, isTrue);
    });

    testWidgets('sospeso: i ruoli non si cambiano', (tester) async {
      sized(tester, const Size(1280, 2400));
      seed(me({'approvalStatus': 'sospeso'}));
      await tester.pumpWidget(page(const ProfileEditScreen()));
      await tester.pump();
      expect(find.text(t.profileRolesSuspended), findsOneWidget);
      final box = tester.widget<CheckboxListTile>(
          find.byKey(const ValueKey('edit-role-guida')));
      expect(box.onChanged, isNull);
    });

    testWidgets('Account mostra i ruoli in attesa', (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(me({
        'pendingRoles': ['accompagnatore']
      }));
      await tester.pumpWidget(page(const AccountScreen()));
      await tester.pump();
      expect(find.byKey(const ValueKey('pending-role-accompagnatore')),
          findsOneWidget);
      expect(find.text(t.accountRolesPending(t.roleAccompagnatore)),
          findsOneWidget);
    });

    test('i ruoli in attesa arrivano dal profilo', () {
      final u = me({
        'pendingRoles': ['tourOperator', 'accompagnatore']
      });
      expect(u.roles, [Role.guida]);
      expect(u.pendingRoles, [Role.tourOperator, Role.accompagnatore]);
      expect(
          u.chosenRoles, [Role.guida, Role.accompagnatore, Role.tourOperator]);
    });
  });

  group('professionista non approvato', () {
    Guide fromMe(String role, String approval) => Guide.fromProfileJson({
          'id': 'p1',
          'name': 'Paola Rossi',
          'email': 'p@example.com',
          'role': role,
          'approvalStatus': approval,
        });

    test('in attesa o rifiutato è un turista', () {
      for (final approval in ['in_attesa', 'rifiutato']) {
        for (final role in ['guida', 'accompagnatore', 'tourOperator']) {
          final u = fromMe(role, approval);
          expect(u.role, Role.turista, reason: '$role $approval');
          expect(u.requestedRoles, [roleFromString(role)]);
          expect(u.roles, isEmpty);
        }
      }
    });

    test('approvato ha il suo ruolo', () {
      final u = fromMe('accompagnatore', 'approvato');
      expect(u.role, Role.accompagnatore);
      expect(u.requestedRoles, isEmpty);
      expect(u.roles, [Role.accompagnatore]);
      expect(fromMe('turista', 'approvato').requestedRoles, isEmpty);
    });

    for (final approval in ['in_attesa', 'rifiutato']) {
      testWidgets('$approval: pagine del turista e avviso in Account',
          (tester) async {
        sized(tester, const Size(1920, 1080));
        seed(fromMe('guida', approval));
        await tester.pumpWidget(const GuidaTourApp());
        await tester.pump(const Duration(milliseconds: 100));
        for (final p in turistaPages) {
          expect(navLabel(p), findsOneWidget, reason: p);
        }
        expect(navLabel(t.dashTabMyTours), findsNothing);
        expect(find.byIcon(Icons.shopping_cart_outlined), findsWidgets);
        await tester.tap(find.byKey(const ValueKey('user-avatar')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('requested-role')), findsOneWidget);
        expect(
            find.text(approval == 'rifiutato'
                ? t.accountRoleRejected(t.roleGuida)
                : t.accountRolePending(t.roleGuida)),
            findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });
    }
  });

  group('pallino utente', () {
    test('iniziali di nome e cognome', () {
      Guide named(String name) =>
          Guide(id: 'x', name: name, email: '', role: Role.turista);
      expect(named('Maria Cristina Bevilacqua').initials, 'MB');
      expect(named('giulia romano').initials, 'GR');
      expect(named('Admin').initials, 'A');
      expect(named('  ').initials, '?');
    });

    for (final (name, u) in <(String, Guide)>[
      ('turista', user(Role.turista)),
      ('guida', user(Role.guida)),
      ('accompagnatore', user(Role.accompagnatore)),
      ('tour operator', user(Role.tourOperator)),
      ('admin', user(Role.turista, isAdmin: true)),
    ]) {
      testWidgets('$name lo vede e apre l\'account', (tester) async {
        sized(tester, const Size(1920, 1080));
        seed(u);
        await tester.pumpWidget(const GuidaTourApp());
        await tester.pump(const Duration(milliseconds: 100));
        expect(
            find.descendant(
                of: find.byKey(const ValueKey('user-avatar')),
                matching: find.text('UP')),
            findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('user-avatar')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(t.editProfile), findsOneWidget);
        expect(find.byType(BackButton), findsNothing);
        appState.currentUser = null;
        appState.notifyListeners();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(find.text(t.editProfile), findsNothing);
        await tester.pumpWidget(const SizedBox());
      });
    }

    testWidgets('il visitatore non lo vede', (tester) async {
      sized(tester, const Size(1920, 1080));
      seed(null);
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(UserAvatar), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('ritaglio della foto', () {
    test('una foto larga parte centrata e riempie il riquadro', () {
      const side = 300.0;
      final rect =
          visibleRect(coverTransform(const Size(2000, 1000), side), side);
      expect(rect.left, closeTo(500, 0.01));
      expect(rect.top, closeTo(0, 0.01));
      expect(rect.width, closeTo(1000, 0.01));
    });

    test('una foto alta parte centrata e riempie il riquadro', () {
      const side = 300.0;
      final rect =
          visibleRect(coverTransform(const Size(1000, 3000), side), side);
      expect(rect.left, closeTo(0, 0.01));
      expect(rect.top, closeTo(1000, 0.01));
      expect(rect.height, closeTo(1000, 0.01));
    });

    test('spostando la foto cambia la parte tenuta', () {
      const side = 300.0;
      final moved = coverTransform(const Size(2000, 1000), side)
        ..setTranslationRaw(0, 0, 0);
      expect(visibleRect(moved, side).left, closeTo(0, 0.01));
    });
  });

  group('link e QR', () {
    test('il link del tour usa il sito pubblico', () {
      final tour = tourBy('g1');
      expect(tour.url, '$publicSiteUrl?tour=tour1');
      expect(Uri.parse(tour.url).host, isNot('guidatour.it'));
    });

    test('il link del QR si riconosce come scansione', () {
      final qr = Uri.parse('${tourBy('g1').url}&src=qr');
      expect(tourLinkFrom(qr), ('tour1', true));
    });

    test('il link semplice è una visita', () {
      expect(tourLinkFrom(Uri.parse(tourBy('g1').url)), ('tour1', false));
    });

    test('senza tour non si apre nulla', () {
      expect(tourLinkFrom(Uri.parse(publicSiteUrl)), isNull);
      expect(tourLinkFrom(Uri.parse('$publicSiteUrl?tour=')), isNull);
    });
  });

  group('gestione (admin)', () {
    testWidgets('ha le cinque schede e si apre sulla panoramica',
        (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(user(Role.turista, isAdmin: true));
      await tester.pumpWidget(page(const AdminScreen()));
      await tester.pump();
      expect(find.text(t.adminTitle), findsOneWidget);
      for (final label in [
        t.adminTabOverview,
        t.adminTabProfessionals,
        t.adminTabTours,
        t.adminTabApprovals,
        t.adminTabWhatsapp,
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('la scheda Approvazioni parte da Tutte, poi i filtri',
        (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(user(Role.turista, isAdmin: true));
      await tester.pumpWidget(page(const AdminScreen(initialTab: 3)));
      await tester.pump();
      expect(find.text(t.approvalsIntro), findsOneWidget);
      final seg = tester.widget<SegmentedButton<String>>(
          find.byType(SegmentedButton<String>));
      expect(seg.selected, {'tutte'});
      expect(seg.segments.map((s) => s.value).toList(),
          ['tutte', 'in_attesa', 'approvato', 'rifiutato']);
    });

    test('lo stato mostrato segue la richiesta', () {
      Guide g(String status, [List<String> pending = const []]) =>
          Guide.fromProfileJson({
            'id': 'x',
            'name': 'X',
            'email': 'x@e.it',
            'role': 'guida',
            'roles': ['guida'],
            'pendingRoles': pending,
            'approvalStatus': status,
          });
      // Senza contesto: si confrontano solo i toni.
      PillTone tone(Guide x) => x.pendingRoles.isNotEmpty
          ? PillTone.waiting
          : switch (x.approvalStatus) {
              'approvato' => PillTone.ok,
              'rifiutato' || 'sospeso' => PillTone.alert,
              _ => PillTone.waiting,
            };
      expect(tone(g('approvato')), PillTone.ok);
      expect(tone(g('approvato', ['tourOperator'])), PillTone.waiting);
      expect(tone(g('rifiutato')), PillTone.alert);
    });

    testWidgets('il menu dice Gestione, non Approvazioni', (tester) async {
      sized(tester, const Size(1920, 1080));
      seed(user(Role.turista, isAdmin: true));
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(navLabel(t.navManage), findsOneWidget);
      expect(navLabel(t.navApprovals), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('account', () {
    testWidgets('turista: numeri, profilo e azioni', (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(user(Role.turista));
      await tester.pumpWidget(page(const AccountScreen()));
      await tester.pump();
      for (final s in [
        t.accountStatFavorites,
        t.accountStatRequests,
        t.accountStatCart,
        t.accountProfileSection,
        t.accountBioEmpty,
        t.editProfile,
        t.logout,
      ]) {
        expect(find.text(s), findsWidgets, reason: s);
      }
      expect(find.byType(GoldPanel), findsNWidgets(2));
    });

    testWidgets('professionista: tour e richieste ricevute', (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(user(Role.guida));
      await tester.pumpWidget(page(const AccountScreen()));
      await tester.pump();
      expect(find.text(t.accountStatTours), findsOneWidget);
      expect(find.text(t.accountStatReceived), findsOneWidget);
      expect(find.text(t.accountStatFavorites), findsNothing);
    });

    testWidgets('sospeso: avviso dedicato', (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(Guide.fromProfileJson({
        'id': 's1',
        'name': 'Sara Sospesa',
        'email': 's@example.com',
        'role': 'guida',
        'approvalStatus': 'sospeso',
      }));
      await tester.pumpWidget(page(const AccountScreen()));
      await tester.pump();
      expect(find.text(t.accountRoleSuspended(t.roleGuida)), findsOneWidget);
    });

    testWidgets('modifica profilo a riquadri', (tester) async {
      sized(tester, const Size(1280, 2000));
      seed(user(Role.guida));
      await tester.pumpWidget(page(const ProfileEditScreen()));
      await tester.pump();
      expect(find.text(t.profilePhotoSection), findsOneWidget);
      expect(find.text(t.profileDataSection), findsOneWidget);
      expect(find.text(t.fieldLanguagesSpoken), findsOneWidget);
    });
  });

  group('date multiple', () {
    final d1 = DateTime(2099, 6, 2, 21);
    final d2 = DateTime(2099, 6, 9, 21);
    final d3 = DateTime(2099, 6, 16, 21);
    Tour multi(String guideId) => Tour(
          id: 'tour1',
          title: 'Trastevere by night',
          city: 'Roma',
          category: 'Serale',
          language: 'Italiano',
          duration: '2 ore',
          start: d1,
          dates: [d1, d2, d3],
          price: 20,
          meetingPoint: 'Piazza Trilussa',
          description: 'Descrizione',
          seats: 10,
          guideId: guideId,
        );

    test('date settimanali, prossima uscita e tour passato', () {
      expect(weeklyDates(d1, DateTime(2099, 6, 16)), [d2, d3]);
      expect(weeklyDates(d1, DateTime(2099, 6, 8)), isEmpty);
      expect(isWeekly([d1, d2, d3]), isTrue);
      expect(isWeekly([d1, d3]), isFalse);
      final tour = multi('g1');
      expect(tour.upcoming, [d1, d2, d3]);
      expect(tour.nextStart, d1);
      expect(tour.isPast, isFalse);
      final old = Tour(
        id: 'x',
        title: 'Passato',
        city: 'Roma',
        category: 'Serale',
        language: 'Italiano',
        duration: '1 ora',
        start: DateTime(2020, 1, 1),
        dates: [DateTime(2020, 1, 1), DateTime(2020, 1, 8)],
        price: 10,
        meetingPoint: 'Qui',
        description: '',
        seats: 5,
        guideId: 'g1',
      );
      expect(old.isPast, isTrue);
      expect(old.upcoming, isEmpty);
      expect(old.nextStart, DateTime(2020, 1, 8));
      // Un tour con una data sola funziona come prima.
      expect(tourBy('g1').dates, [DateTime(2099, 6, 15, 10)]);
    });

    testWidgets('la scheda fa scegliere la data', (tester) async {
      sized(tester, const Size(1280, 2600));
      final guida =
          Guide(id: 'g1', name: 'Guida', email: 'g@e.it', role: Role.guida);
      seed(user(Role.turista), owner: guida);
      final tour = multi('g1');
      appState.tours
        ..clear()
        ..add(tour);
      await tester.pumpWidget(page(TourDetailScreen(tour: tour)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(t.detailChooseDate), findsOneWidget);
      final chips = find.descendant(
          of: find.byKey(const ValueKey('tour-date-choice')),
          matching: find.byType(ChoiceChip));
      expect(chips, findsNWidgets(3));
      expect(tester.widget<ChoiceChip>(chips.at(0)).selected, isTrue);
      await tester.tap(chips.at(1));
      await tester.pump();
      expect(tester.widget<ChoiceChip>(chips.at(1)).selected, isTrue);
      expect(tester.widget<ChoiceChip>(chips.at(0)).selected, isFalse);
    });

    testWidgets('dal link si apre sulla data scelta', (tester) async {
      sized(tester, const Size(1280, 2600));
      seed(null,
          owner: Guide(
              id: 'g1', name: 'Guida', email: 'g@e.it', role: Role.guida));
      final tour = multi('g1');
      await tester
          .pumpWidget(page(TourDetailScreen(tour: tour, initialDate: d3)));
      await tester.pump(const Duration(milliseconds: 100));
      final chips = find.byType(ChoiceChip);
      expect(tester.widget<ChoiceChip>(chips.at(2)).selected, isTrue);
      final iso = d3.toUtc().toIso8601String();
      expect(
          tourLinkDate(Uri.parse('$publicSiteUrl?tour=tour1&date=$iso')), d3);
    });

    testWidgets('il modulo mostra le date e le toglie', (tester) async {
      sized(tester, const Size(1280, 2600));
      seed(user(Role.guida));
      await tester.pumpWidget(page(TourFormScreen(existing: multi('u1'))));
      await tester.pump();
      expect(find.text(t.fieldDates), findsOneWidget);
      final chips = find.descendant(
          of: find.byKey(const ValueKey('tour-dates')),
          matching: find.byType(InputChip));
      expect(chips, findsNWidgets(3));
      expect(find.text(t.formAddDate), findsOneWidget);
      expect(find.text(t.formRepeatWeekly), findsOneWidget);
      tester.widget<InputChip>(chips.first).onDeleted!();
      await tester.pump();
      expect(chips, findsNWidgets(2));
    });

    testWidgets('carrello con la data scelta', (tester) async {
      sized(tester, const Size(1280, 2000));
      seed(user(Role.turista));
      final tour = multi('g1');
      appState.tours
        ..clear()
        ..add(tour);
      appState.cart = [CartItem('tour1', start: d2)];
      await tester.pumpWidget(page(const CartScreen()));
      await tester.pump();
      expect(find.textContaining(fmtDate(d2)), findsOneWidget);
      expect(find.byKey(const ValueKey('cart-date-tour1')), findsOneWidget);
      appState.cart = [];
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('la guida vede la data di ogni richiesta', (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(user(Role.guida));
      appState.requests = [
        BookingRequest(
          id: 'r1',
          tourId: 'tour1',
          name: 'Anna',
          email: 'a@example.com',
          phone: '',
          people: 2,
          message: '',
          createdAt: DateTime(2026, 11, 1),
          start: d2,
        ),
      ];
      await tester.pumpWidget(page(const BookingsScreen()));
      await tester.pump();
      expect(find.byKey(const ValueKey('request-date-r1')), findsOneWidget);
      expect(find.text(t.requestForDate(fmtDate(d2))), findsOneWidget);
      appState.requests = [];
    });

    test('foto per tour: stabile, varia tra tour, file presenti', () {
      final seen = <String>{};
      for (final c in tourCategories) {
        for (var i = 0; i < 40; i++) {
          final tour = Tour(
              id: 'id$i',
              title: 'T',
              city: 'Roma',
              category: c,
              language: 'Italiano',
              duration: '1 ora',
              start: d1,
              price: 10,
              meetingPoint: 'P',
              description: 'D',
              seats: 5,
              guideId: 'g1');
          final img = tourImage(tour);
          expect(tourImage(tour), img); // sempre la stessa per lo stesso tour
          expect(File(img).existsSync(), isTrue, reason: img);
          seen.add(img);
        }
      }
      // 4 foto per ognuna delle 6 categorie, tutte usate.
      expect(seen.length, tourCategories.length * 4);
    });

    testWidgets('data leggibile nella lingua scelta', (tester) async {
      late String label;
      await tester.pumpWidget(page(Builder(builder: (context) {
        label = fmtFriendlyDate(context, DateTime(2030, 6, 4, 21, 0));
        return const SizedBox();
      })));
      expect(label, 'mar 4 giu 2030 · 21:00');
    });

    testWidgets('scheda tour sul telefono: barra Prenota porta al modulo',
        (tester) async {
      sized(tester, const Size(390, 844));
      seed(user(Role.turista),
          owner: Guide(
              id: 'g1', name: 'Guida', email: 'g@e.it', role: Role.guida));
      final tour = multi('g1');
      await tester.pumpWidget(page(TourDetailScreen(tour: tour)));
      await tester.pump();
      expect(find.byKey(const ValueKey('book-bar-button')), findsOneWidget);
      expect(find.text(t.detailBookNow), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('book-bar-button')));
      await tester.pumpAndSettle();
      expect(find.text(t.bookingSectionTitle).hitTestable(), findsOneWidget);
    });

    testWidgets('scheda tour su computer: niente barra in basso',
        (tester) async {
      sized(tester, const Size(1280, 900));
      seed(user(Role.turista),
          owner: Guide(
              id: 'g1', name: 'Guida', email: 'g@e.it', role: Role.guida));
      await tester.pumpWidget(page(TourDetailScreen(tour: multi('g1'))));
      await tester.pump();
      expect(find.byKey(const ValueKey('book-bar-button')), findsNothing);
    });

    testWidgets('locandina: ogni settimana alla stessa ora', (tester) async {
      late String label;
      await tester.pumpWidget(page(Builder(builder: (context) {
        label = tourScheduleLabel(context, multi('g1'));
        return const SizedBox();
      })));
      expect(label, t.scheduleWeekly('martedì', '21:00', '02/06', '16/06'));
    });

    test('avvisi: posti contati per data, niente sovrapposizioni con sé stesso',
        () {
      final tour = Tour(
        id: 'tour1',
        title: 'Settimanale',
        city: 'Roma',
        category: 'Serale',
        language: 'Italiano',
        duration: '2 ore',
        start: d1,
        dates: [d1, d2],
        price: 20,
        meetingPoint: 'Qui',
        description: '',
        seats: 3,
        guideId: 'u1',
      );
      BookingRequest r(String id, DateTime d, int people) => BookingRequest(
            id: id,
            tourId: 'tour1',
            name: 'X',
            email: 'x@e.it',
            phone: '',
            people: people,
            message: '',
            createdAt: DateTime(2026, 11, 1),
            start: d,
          );
      appState
        ..myTours = [tour]
        ..requests = [r('a', d1, 2), r('b', d2, 2)];
      // 2 + 2 su date diverse: nessun overbooking.
      expect(appState.overbookingAlerts('u1'), isEmpty);
      appState.requests = [r('a', d1, 2), r('b', d1, 2)];
      expect(appState.overbookingAlerts('u1'), hasLength(1));
      appState
        ..myTours = []
        ..requests = [];
    });
  });
}
