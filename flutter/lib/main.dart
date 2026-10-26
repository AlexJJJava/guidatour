import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';
import 'l10n/gen/app_localizations.dart';
import 'l10n/labels.dart';
import 'l10n/locale_controller.dart';
import 'models.dart';
import 'screens/auth_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/search_screen.dart';
import 'screens/tourist_account_screen.dart';
import 'screens/tour_detail_screen.dart';
import 'screens/whatsapp_optin.dart';
import 'state.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const GuidaTourApp());
}

class GuidaTourApp extends StatelessWidget {
  const GuidaTourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeController,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'GuidaTour',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
            scaffoldBackgroundColor: const Color(0xFFF7F8F4),
            fontFamily: 'Arial',
          ),
          home: const _Startup(),
        );
      },
    );
  }
}

/// Carica i dati pubblici dal backend (il piano free di Render può metterci
/// fino a un minuto a svegliarsi) prima di mostrare l'app.
class _Startup extends StatefulWidget {
  const _Startup();

  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  @override
  void initState() {
    super.initState();
    if (!appState.ready) appState.init();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (!appState.ready) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: kPrimary),
                  const SizedBox(height: 16),
                  Text(l10n(context).startupLoading,
                      style: const TextStyle(color: kMuted)),
                ],
              ),
            ),
          );
        }
        return const AppShell();
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final tabs = [
      (t.navDiscover, Icons.explore_outlined, Icons.explore),
      (t.navSearch, Icons.search, Icons.search),
      (t.navFavorites, Icons.favorite_border, Icons.favorite),
      (t.navCart, Icons.shopping_cart_outlined, Icons.shopping_cart),
      (t.navBookings, Icons.event_note_outlined, Icons.event_note),
      (t.navAccount, Icons.person_outline, Icons.person),
    ];
    final pages = [
      HomeScreen(
          onOpenSearch: () => _select(1), onOpenAccount: () => _select(5)),
      const SearchScreen(),
      const FavoritesScreen(),
      const CartScreen(),
      const BookingsScreen(),
      ListenableBuilder(
        listenable: appState,
        builder: (_, __) {
          final user = appState.currentUser;
          if (user == null) return const AuthScreen();
          return user.role.isProfessional
              ? const DashboardScreen()
              : const TouristAccountScreen();
        },
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth >= 900;
      return Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  if (isDesktop)
                    NavigationRail(
                      extended: true,
                      minExtendedWidth: 220,
                      backgroundColor: Colors.white,
                      selectedIndex: _index,
                      onDestinationSelected: _select,
                      leading: const Padding(
                        padding: EdgeInsets.fromLTRB(0, 24, 0, 32),
                        child: Text('guidatour',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.1,
                                color: kPrimary)),
                      ),
                      destinations: [
                        for (final tab in tabs)
                          NavigationRailDestination(
                            icon: Icon(tab.$2),
                            selectedIcon: Icon(tab.$3),
                            label: Text(tab.$1),
                          ),
                      ],
                    ),
                  Expanded(child: pages[_index]),
                ],
              ),
              const Positioned(top: 10, right: 12, child: LanguagePicker()),
            ],
          ),
        ),
        bottomNavigationBar: isDesktop
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  for (final tab in tabs)
                    NavigationDestination(
                      icon: Icon(tab.$2),
                      selectedIcon: Icon(tab.$3),
                      label: tab.$1,
                    ),
                ],
              ),
      );
    });
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen(
      {super.key, required this.onOpenSearch, required this.onOpenAccount});
  final VoidCallback onOpenSearch;
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final t = l10n(context);
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final upcoming = [...appState.tours]
          ..sort((a, b) => a.start.compareTo(b.start));
        return PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('guidatour',
                        style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.1,
                            color: kPrimary)),
                  ),
                  if (appState.currentUser == null)
                    FilledButton.tonalIcon(
                      onPressed: onOpenAccount,
                      icon: const Icon(Icons.login, size: 18),
                      label: Text(t.login),
                    )
                  else
                    TextButton.icon(
                      onPressed: onOpenAccount,
                      icon: const Icon(Icons.person, size: 18),
                      label: Text(appState.currentUser!.name.split(' ').first),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              _hero(context, isDesktop),
              const SizedBox(height: 28),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final c in tourCategories)
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: const Color(0xFFE1F0EC),
                      side: BorderSide.none,
                      avatar: Icon(categoryIcon(c), size: 16),
                      label: Text(categoryLabel(context, c)),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(backgroundColor: Colors.transparent),
                            body: SearchScreen(initialCategory: c),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              SectionHeading(
                  title: t.homeUpcomingTitle,
                  action: t.seeAll,
                  onAction: onOpenSearch),
              const SizedBox(height: 16),
              ResponsiveGrid(children: [
                for (final tour in upcoming.take(6))
                  TourCard(tour: tour, onTap: () => openTour(context, tour)),
              ]),
              const SizedBox(height: 36),
              const WhatsAppOptInCard(source: 'Home'),
              const SizedBox(height: 28),
              _operatorBanner(t),
              const PlatformDisclaimer(),
            ],
          ),
        );
      },
    );
  }

  Widget _hero(BuildContext context, bool isDesktop) {
    final t = l10n(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 38 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0E4F4A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.homeHeroTitle,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1)),
          const SizedBox(height: 10),
          Text(t.homeHeroSubtitle,
              style: const TextStyle(color: Color(0xFFD7E9E3), fontSize: 16)),
          const SizedBox(height: 22),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: kPrimary),
            onPressed: onOpenSearch,
            icon: const Icon(Icons.search),
            label: Text(t.homeSearchCta),
          ),
        ],
      ),
    );
  }

  Widget _operatorBanner(AppLocalizations t) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9D9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.operatorBannerTitle,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3C3427))),
          const SizedBox(height: 6),
          Text(t.operatorBannerBody,
              style: const TextStyle(color: Color(0xFF625846))),
        ],
      ),
    );
  }
}
