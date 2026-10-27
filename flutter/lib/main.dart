import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';
import 'l10n/gen/app_localizations.dart';
import 'l10n/labels.dart';
import 'l10n/locale_controller.dart';
import 'models.dart';
import 'screens/account_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/dashboard_overview_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/my_tours_screen.dart';
import 'screens/search_screen.dart';
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
            // Transizioni leggere e coerenti tra le pagine su tutte le
            // piattaforme (incluse nel framework, nessun pacchetto in più).
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
            }),
            cardTheme: CardThemeData(
              elevation: 2,
              shadowColor: kInk.withValues(alpha: 0.12),
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadius),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
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

/// Una voce del menu principale: etichetta, icone e la pagina che mostra.
typedef _NavItem = (
  String label,
  IconData icon,
  IconData selectedIcon,
  Widget page
);

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// 'guest' | 'tourist' | 'pro': quando cambia (login/logout/cambio ruolo)
  /// il menu cambia voci, quindi si torna alla prima.
  String? _lastKind;

  void _select(int i) => setState(() => _index = i);

  List<_NavItem> _navItems(BuildContext context) {
    final t = l10n(context);
    final user = appState.currentUser;
    final items = <_NavItem>[];
    items.add(
      (
        t.navDiscover,
        Icons.explore_outlined,
        Icons.explore,
        HomeScreen(
            onOpenSearch: () => _select(1),
            onOpenAccount: () => _select(items.length - 1)),
      ),
    );
    items.add(
      (t.navSearch, Icons.search, Icons.search, const SearchScreen()),
    );
    if (user != null && user.role.isProfessional) {
      items.addAll([
        (
          t.dashTabOverview,
          Icons.dashboard_outlined,
          Icons.dashboard,
          const DashboardOverviewScreen(),
        ),
        (
          t.dashTabMyTours,
          Icons.map_outlined,
          Icons.map,
          const MyToursScreen(),
        ),
        (
          t.dashTabAssignments,
          Icons.swap_horiz_outlined,
          Icons.swap_horiz,
          const AssignmentsScreen(),
        ),
        (
          t.navBookings,
          Icons.event_note_outlined,
          Icons.event_note,
          const BookingsScreen(),
        ),
      ]);
    } else {
      items.addAll([
        (
          t.navFavorites,
          Icons.favorite_border,
          Icons.favorite,
          const FavoritesScreen(),
        ),
        (
          t.navCart,
          Icons.shopping_cart_outlined,
          Icons.shopping_cart,
          const CartScreen(),
        ),
        (
          t.navBookings,
          Icons.event_note_outlined,
          Icons.event_note,
          const BookingsScreen(),
        ),
      ]);
    }
    items.add((
      t.navAccount,
      Icons.person_outline,
      Icons.person,
      const AccountScreen()
    ));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        final kind = user == null
            ? 'guest'
            : (user.role.isProfessional ? 'pro' : 'tourist');
        if (kind != _lastKind) {
          _lastKind = kind;
          _index = 0;
        }
        final items = _navItems(context);
        if (_index >= items.length) _index = 0;
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
                            for (final item in items)
                              NavigationRailDestination(
                                icon: Icon(item.$2),
                                selectedIcon: Icon(item.$3),
                                label: Text(item.$1),
                              ),
                          ],
                        ),
                      Expanded(child: items[_index].$4),
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
                      for (final item in items)
                        NavigationDestination(
                          icon: Icon(item.$2),
                          selectedIcon: Icon(item.$3),
                          label: item.$1,
                        ),
                    ],
                  ),
          );
        });
      },
    );
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
                  title: t.homeUpcomingTitle(cityLabel(context, appState.city)),
                  action: t.seeAll,
                  onAction: onOpenSearch),
              const SizedBox(height: 16),
              ResponsiveGrid(children: [
                for (final tour in upcoming.take(6))
                  TourCard(tour: tour, onTap: () => openTour(context, tour)),
              ]),
              const SizedBox(height: 36),
              const WhatsAppOptInCard(source: 'Home'),
              if (appState.currentUser == null ||
                  !appState.currentUser!.role.isProfessional) ...[
                const SizedBox(height: 28),
                _operatorBanner(context, t),
              ],
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
          const SizedBox(height: 18),
          const _HeroSearchBar(),
        ],
      ),
    );
  }

  Widget _operatorBanner(BuildContext context, AppLocalizations t) {
    return InkWell(
      borderRadius: BorderRadius.circular(kRadius),
      onTap: onOpenAccount,
      child: Container(
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
      ),
    );
  }
}

/// Città e ricerca affiancate nel riquadro verde della home.
class _HeroSearchBar extends StatefulWidget {
  const _HeroSearchBar();

  @override
  State<_HeroSearchBar> createState() => _HeroSearchBarState();
}

class _HeroSearchBarState extends State<_HeroSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _go(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.transparent),
          body: SearchScreen(initialQuery: _controller.text.trim()),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CityPicker(),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _go(context),
            style: const TextStyle(color: kInk),
            decoration: InputDecoration(
              isDense: true,
              hintText: t.searchHint,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: kPrimary),
                onPressed: () => _go(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
