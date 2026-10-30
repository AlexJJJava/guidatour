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
import 'screens/approvals_screen.dart';
import 'screens/assignments_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/dashboard_overview_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/my_tours_screen.dart';
import 'screens/search_screen.dart';
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
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
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
            colorScheme: ColorScheme.fromSeed(
              seedColor: kGold,
              primary: kPrimary,
              onPrimary: Colors.white,
              secondary: kGold,
              onSecondary: kOnGold,
              surface: kSurface,
              onSurface: kInk,
              outline: kLine,
            ),
            scaffoldBackgroundColor: kCream,
            fontFamily: 'Inter',
            // Transizioni leggere e coerenti tra le pagine su tutte le
            // piattaforme (incluse nel framework, nessun pacchetto in più).
            pageTransitionsTheme: const PageTransitionsTheme(builders: {
              TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
            }),
            appBarTheme: const AppBarTheme(
              backgroundColor: kCream,
              foregroundColor: kInk,
              surfaceTintColor: Colors.transparent,
              titleTextStyle: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kInk),
            ),
            cardTheme: CardThemeData(
              elevation: 3,
              shadowColor: kInk.withValues(alpha: 0.14),
              color: kSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadius),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: kOnGold,
                disabledBackgroundColor: kLine,
                textStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
                shape: buttonShape,
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: kInk,
                side: const BorderSide(color: kLine),
                shape: buttonShape,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: kPrimary),
            ),
            chipTheme: const ChipThemeData(
              backgroundColor: kSand,
              selectedColor: kGold,
              secondaryLabelStyle: TextStyle(color: kOnGold),
              side: BorderSide.none,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: kSurface,
              indicatorColor: kSand,
              surfaceTintColor: Colors.transparent,
              iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
                  color: s.contains(WidgetState.selected) ? kPrimary : kMuted)),
              labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                  fontSize: 11.5,
                  fontWeight: s.contains(WidgetState.selected)
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: s.contains(WidgetState.selected) ? kInk : kMuted)),
            ),
            dividerTheme: const DividerThemeData(color: kLine),
            popupMenuTheme: const PopupMenuThemeData(color: kSand),
            scrollbarTheme: ScrollbarThemeData(
              thumbColor: WidgetStatePropertyAll(kGold.withValues(alpha: 0.7)),
              trackColor: const WidgetStatePropertyAll(kSurface),
              trackBorderColor: const WidgetStatePropertyAll(kLine),
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
                  const BrandLogo(light: false),
                  const SizedBox(height: 24),
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

/// Una voce del menu principale: etichetta, icone e la pagina che mostra
/// (null per la home, costruita a parte perché riceve la barra di navigazione).
typedef _NavItem = (
  String label,
  IconData icon,
  IconData selectedIcon,
  Widget? page
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
    final items = <_NavItem>[
      (t.navDiscover, Icons.explore_outlined, Icons.explore, null),
      (t.navSearch, Icons.search, Icons.search, const SearchScreen()),
    ];
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
          t.navBookings,
          Icons.event_note_outlined,
          Icons.event_note,
          const BookingsScreen(),
        ),
      ]);
    }
    if (user != null && user.isAdmin) {
      items.add((
        t.navApprovals,
        Icons.how_to_reg_outlined,
        Icons.how_to_reg,
        const ApprovalsScreen(),
      ));
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
        final accountIndex = items.length - 1;
        return LayoutBuilder(builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          Widget topBar({required bool overPhoto}) => isDesktop
              ? _TopBar(
                  items: items,
                  index: _index,
                  onSelect: _select,
                  overPhoto: overPhoto,
                )
              : const _MobileTopBar();
          final Widget body;
          if (_index == 0) {
            body = HomeScreen(
              header: topBar(overPhoto: true),
              links: [
                for (var i = 0; i < items.length; i++)
                  (items[i].$1, () => _select(i)),
              ],
              onOpenSearch: () => _select(1),
              onOpenAccount: () => _select(accountIndex),
            );
          } else if (isDesktop) {
            body = Column(
              children: [
                topBar(overPhoto: false),
                Expanded(child: items[_index].$4!),
              ],
            );
          } else {
            body = SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: _TopActions(withCity: true)),
                  ),
                  Expanded(child: items[_index].$4!),
                ],
              ),
            );
          }
          return Scaffold(
            body: body,
            bottomNavigationBar: isDesktop
                ? null
                : NavigationBar(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    destinations: [
                      for (final item in items)
                        NavigationDestination(
                          icon: _navIcon(item.$2, item.$4),
                          selectedIcon: _navIcon(item.$3, item.$4),
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

/// Icona del menu, con il numero di registrazioni da approvare sulla voce
/// degli admin.
Widget _navIcon(IconData icon, Widget? page) {
  final pending = appState.pendingRegistrations;
  if (page is! ApprovalsScreen || pending == 0) return Icon(icon);
  return Badge(label: Text('$pending'), child: Icon(icon));
}

/// Barra di navigazione orizzontale (desktop/browser): trasparente sopra la
/// foto della home, blu notte nelle altre pagine.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.items,
    required this.index,
    required this.onSelect,
    required this.overPhoto,
  });
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final bool overPhoto;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Container(
      color: overPhoto ? null : kNight,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Row(
          children: [
            InkWell(
              onTap: () => onSelect(0),
              child: BrandLogo(tagline: t.footerTagline),
            ),
            const SizedBox(width: 36),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _NavLink(
                        label: items[i].$4 is ApprovalsScreen &&
                                appState.pendingRegistrations > 0
                            ? '${items[i].$1} (${appState.pendingRegistrations})'
                            : items[i].$1,
                        selected: i == index,
                        onTap: () => onSelect(i),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            const CityPicker(),
            const SizedBox(width: 8),
            const LanguagePicker(),
            const SizedBox(width: 14),
            GoldButton(t.ctaButton, onPressed: () => onSelect(1)),
            if (_showsCart()) ...[
              const SizedBox(width: 12),
              const CartButton(),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? kGold : Colors.white)),
              const SizedBox(height: 4),
              Container(
                  height: 2,
                  width: 18,
                  color: selected ? kGold : Colors.transparent),
            ],
          ),
        ),
      );
}

/// Su telefono la home mostra solo logo e lingua sopra la foto: il menu è
/// nella barra in basso.
class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 16, 0),
        child: Row(
          children: [
            BrandLogo(),
            Spacer(),
            _TopActions(),
          ],
        ),
      );
}

/// Il carrello è dei turisti (e di chi non ha ancora fatto l'accesso).
bool _showsCart() {
  final user = appState.currentUser;
  return user == null || !user.role.isProfessional;
}

/// Lingua e carrello in alto a destra su telefono; nelle pagine interne
/// anche la città (in home sta sopra il titolo della copertina).
class _TopActions extends StatelessWidget {
  const _TopActions({this.withCity = false});
  final bool withCity;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withCity) ...[
            const CityPicker(),
            const SizedBox(width: 8),
          ],
          const LanguagePicker(),
          if (_showsCart()) ...[
            const SizedBox(width: 8),
            const CartButton(),
          ],
        ],
      );
}
