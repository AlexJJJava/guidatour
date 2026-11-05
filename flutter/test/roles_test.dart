import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guidatour/app_config.dart';
import 'package:guidatour/l10n/gen/app_localizations.dart';
import 'package:guidatour/l10n/locale_controller.dart';
import 'package:guidatour/main.dart';
import 'package:guidatour/models.dart';
import 'package:guidatour/screens/approvals_screen.dart';
import 'package:guidatour/screens/avatar_crop_screen.dart';
import 'package:guidatour/screens/account_screen.dart';
import 'package:guidatour/screens/auth_screen.dart';
import 'package:guidatour/screens/bookings_screen.dart';
import 'package:guidatour/screens/cart_screen.dart';
import 'package:guidatour/screens/faq_screen.dart';
import 'package:guidatour/screens/favorites_screen.dart';
import 'package:guidatour/screens/my_tours_screen.dart';
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
  t.navBookings,
];
final proPages = [
  t.navDiscover,
  t.navSearch,
  t.dashTabOverview,
  t.dashTabMyTours,
  t.dashTabAssignments,
  t.navBookings,
];
final allPages = {
  ...turistaPages,
  ...proPages,
  t.navApprovals,
  t.navAccount,
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
        [...turistaPages, t.navApprovals],
        true
      ),
      (
        'admin con ruolo guida',
        user(Role.guida, isAdmin: true),
        [...proPages, t.navApprovals],
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
              navLabel(p).evaluate().length + menuLabel(p).evaluate().length,
              1,
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
      testWidgets('$name: pagina aperta con intestazione, footer e senza freccia',
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
        // Footer con il solo link FAQ e senza scelta della lingua.
        final footer = find.byType(SiteFooter);
        expect(footer, findsOneWidget);
        expect(find.descendant(of: footer, matching: find.byType(LanguagePicker)),
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
          final labels = u?.role.isProfessional == true ? proPages : turistaPages;
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

  group('una sola intestazione', () {
    Finder bars(Size size) => find.byWidgetPredicate((w) =>
        '${w.runtimeType}' == (size.width >= 1024 ? '_TopBar' : '_MobileTopBar'));

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
    }
  });

  group('barra su telefono', () {
    testWidgets('il turista ha tutte le voci', (tester) async {
      sized(tester, const Size(412, 915));
      seed(user(Role.turista));
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text(t.navAccount), findsNothing);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('il visitatore ha anche Account', (tester) async {
      sized(tester, const Size(412, 915));
      seed(null);
      await tester.pumpWidget(const GuidaTourApp());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(NavigationDestination), findsNWidgets(5));
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
      final guida = Guide(
          id: 'g1', name: 'Guida', email: 'g@e.it', role: Role.guida);
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
      await tester.tap(find.byWidgetPredicate(
          (w) => '${w.runtimeType}'.startsWith('DropdownButton<String>')).at(1));
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
          expect(u.requestedRole, roleFromString(role));
        }
      }
    });

    test('approvato ha il suo ruolo', () {
      final u = fromMe('accompagnatore', 'approvato');
      expect(u.role, Role.accompagnatore);
      expect(u.requestedRole, isNull);
      expect(fromMe('turista', 'approvato').requestedRole, isNull);
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

  group('approvazioni', () {
    testWidgets('la pagina si apre per l\'admin', (tester) async {
      sized(tester, const Size(1280, 1600));
      seed(user(Role.turista, isAdmin: true));
      await tester.pumpWidget(page(const ApprovalsScreen()));
      await tester.pump();
      expect(find.text(t.approvalsTitle), findsOneWidget);
    });
  });
}
