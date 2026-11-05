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
import 'package:guidatour/screens/account_screen.dart';
import 'package:guidatour/screens/admin_screen.dart';
import 'package:guidatour/screens/assignments_screen.dart';
import 'package:guidatour/screens/auth_screen.dart';
import 'package:guidatour/screens/bookings_screen.dart';
import 'package:guidatour/screens/cart_screen.dart';
import 'package:guidatour/screens/dashboard_overview_screen.dart';
import 'package:guidatour/screens/favorites_screen.dart';
import 'package:guidatour/screens/my_tours_screen.dart';
import 'package:guidatour/screens/poster_screen.dart';
import 'package:guidatour/screens/profile_edit_screen.dart';
import 'package:guidatour/screens/search_screen.dart';
import 'package:guidatour/screens/tour_detail_screen.dart';
import 'package:guidatour/screens/tour_form_screen.dart';
import 'package:guidatour/state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Telefoni piccoli e grandi, in verticale e in orizzontale, tablet, finestre
/// di browser.
const sizes = [
  Size(320, 568),
  Size(360, 740),
  Size(412, 915),
  Size(740, 360),
  Size(768, 1024),
  Size(1024, 768),
  Size(1280, 800),
  Size(1920, 1080),
];

const locales = [Locale('it'), Locale('en'), Locale('es')];

final guide = Guide(
  id: 'g1',
  name: 'Maria Cristina Bevilacqua',
  email: 'maria.cristina.bevilacqua@example.com',
  role: Role.tourOperator,
  verified: true,
  languages: const ['Italiano', 'Inglese', 'Spagnolo'],
);
final admin = Guide(
    id: 'a1',
    name: 'Admin',
    email: 'admin@example.com',
    role: Role.turista,
    isAdmin: true);
final tourist =
    Guide(id: 't1', name: 'Anna', email: 'a@example.com', role: Role.turista);

final tour = Tour(
  id: 'tour1',
  title: 'Passeggiata serale tra i vicoli di Trastevere e il Gianicolo',
  city: 'Roma',
  category: 'Bambini e famiglie',
  language: 'Italiano',
  duration: '2 ore e 30 minuti',
  start: DateTime(2026, 12, 24, 18),
  price: 1250,
  meetingPoint: 'Piazza di Santa Maria in Trastevere, davanti alla fontana',
  description: 'Una visita lunga. ' * 10,
  seats: 25,
  guideId: 'g1',
  accessories: const ['Radioguida'],
);

void seed(Guide? user) {
  appState
    ..currentUser = user
    ..ready = true
    ..pendingRegistrations = user?.isAdmin == true ? 12 : 0
    ..cart = user == tourist ? [CartItem('tour1')] : []
    ..favoriteTours = [tour]
    ..myTours = [tour]
    ..notifications = [
      AppNotification(
          id: 'n1',
          message: 'Nuova richiesta di prenotazione',
          createdAt: DateTime(2026, 11, 1))
    ]
    ..guides.clear()
    ..guides.addAll([guide, guide, guide])
    ..tours.clear()
    ..tours.addAll([tour, tour, tour, tour]);
}

Future<void> loadFonts() async {
  for (final (family, files) in const [
    (
      'Inter',
      ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold', 'Inter-Bold']
    ),
    (
      'Playfair',
      [
        'PlayfairDisplay-SemiBold',
        'PlayfairDisplay-Bold',
        'PlayfairDisplay-SemiBoldItalic'
      ]
    ),
    ('Caveat', ['Caveat-SemiBold']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

Widget page(Widget child, Locale locale) => MaterialApp(
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    await loadFonts();
  });

  testWidgets('nessuna pagina sfora a nessuna larghezza', (tester) async {
    final problems = <String>{};
    var where = '';
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      final text = d.exceptionAsString().split('\n').first;
      if (text.contains('overflowed')) problems.add('$where: $text');
    };

    Future<void> check(String name, Widget widget) async {
      final s = tester.view.physicalSize;
      where = '$name @${s.width.round()}x${s.height.round()}';
      await tester.pumpWidget(widget);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpWidget(const SizedBox());
    }

    tester.view.devicePixelRatio = 1;
    // Carattere ingrandito nelle impostazioni del telefono.
    tester.platformDispatcher.textScaleFactorTestValue =
        double.parse(const String.fromEnvironment('SCALE', defaultValue: '1'));
    for (final size in sizes) {
      tester.view.physicalSize = size;
      for (final locale in locales) {
        localeController.value = locale;
        final tag = locale.languageCode;
        for (final (who, user) in [
          ('ospite', null),
          ('turista', tourist),
          ('guida', guide),
          ('admin', admin),
        ]) {
          seed(user);
          await check('app $who $tag', const GuidaTourApp());
          // Le pagine interne su telefono, con la riga città/lingua/carrello.
          if (size.width < 1024) {
            where = 'interna $who $tag @$size';
            await tester.pumpWidget(const GuidaTourApp());
            await tester.pump();
            await tester.tap(find.byType(NavigationDestination).at(1));
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pumpWidget(const SizedBox());
          }
        }
        seed(tourist);
        await check('ricerca $tag', page(const SearchScreen(), locale));
        await check('preferiti $tag', page(const FavoritesScreen(), locale));
        await check('carrello $tag', page(const CartScreen(), locale));
        await check(
            'dettaglio $tag', page(TourDetailScreen(tour: tour), locale));
        await check('prenotazioni $tag', page(const BookingsScreen(), locale));
        await check('account $tag', page(const AccountScreen(), locale));
        seed(null);
        await check('accesso $tag', page(const AuthScreen(), locale));
        seed(guide);
        await check(
            'panoramica $tag', page(const DashboardOverviewScreen(), locale));
        await check('miei tour $tag', page(const MyToursScreen(), locale));
        await check('incarichi $tag', page(const AssignmentsScreen(), locale));
        await check('richieste $tag', page(const BookingsScreen(), locale));
        await check('locandina $tag', page(PosterScreen(tour: tour), locale));
        await check('form tour $tag', page(const TourFormScreen(), locale));
        await check('profilo $tag', page(const ProfileEditScreen(), locale));
        seed(admin);
        await check('approvazioni $tag', page(const AdminScreen(), locale));
      }
    }
    FlutterError.onError = previous;
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
