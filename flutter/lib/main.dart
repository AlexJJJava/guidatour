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
import 'screens/tour_detail_screen.dart';
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

/// Link diretto a un tour (`?tour=id`, con `&src=qr` se arriva dalla locandina).
(String, bool)? tourLinkFrom(Uri uri) {
  final id = uri.queryParameters['tour'];
  if (id == null || id.isEmpty) return null;
  return (id, uri.queryParameters['src'] == 'qr');
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

  /// AppShell può ricostruirsi: il link va aperto una volta sola.
  static bool _linkOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openLinkedTour());
  }

  Future<void> _openLinkedTour() async {
    final link = tourLinkFrom(Uri.base);
    if (link == null || _linkOpened) return;
    _linkOpened = true;
    final (id, fromQr) = link;
    final tour = await appState.fetchTour(id);
    if (!mounted) return;
    if (tour == null) {
      snack(context, l10n(context).tourUnavailable);
    } else {
      openTour(context, tour, fromQr: fromQr);
    }
  }

  /// 'guest' | 'tourist' | 'pro': quando cambia (login/logout/cambio ruolo)
  /// il menu cambia voci, quindi si torna alla prima.
  String? _lastKind;

  void _select(int i) => setState(() => _index = i);

  /// Chi è collegato arriva all'Account dal pallino, non dal menu.
  void openAccount() {
    if (appState.currentUser == null) {
      _select(_navItems(context).length - 1);
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const _AccountPage()));
    }
  }

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
    if (user == null) {
      items.add((
        t.navAccount,
        Icons.person_outline,
        Icons.person,
        const AccountScreen()
      ));
    }
    return items;
  }

  Widget _bottomBar(BuildContext context, List<_NavItem> items) {
    final t = l10n(context);
    final collapsed = items.length > _maxBottomItems;
    final visible = collapsed ? items.sublist(0, _maxBottomItems - 1) : items;
    final hidden =
        collapsed ? items.sublist(_maxBottomItems - 1) : <_NavItem>[];
    // Telefono in orizzontale: lo spazio in altezza è poco.
    final short = MediaQuery.sizeOf(context).height < 480;
    final bar = NavigationBar(
      height: short ? 56 : null,
      labelBehavior:
          short ? NavigationDestinationLabelBehavior.alwaysHide : null,
      selectedIndex: _index.clamp(0, visible.length),
      onDestinationSelected: (i) =>
          i < visible.length ? _select(i) : _openMore(context, hidden),
      destinations: [
        for (final item in visible)
          NavigationDestination(
            icon: _navIcon(item.$2, item.$4),
            selectedIcon: _navIcon(item.$3, item.$4),
            label: item.$1,
          ),
        if (collapsed)
          NavigationDestination(
            icon: Badge(
              isLabelVisible: hidden.any((i) => i.$4 is ApprovalsScreen) &&
                  appState.pendingRegistrations > 0,
              label: Text('${appState.pendingRegistrations}'),
              child: const Icon(Icons.menu),
            ),
            label: t.navMore,
          ),
      ],
    );
    if (MediaQuery.sizeOf(context).width >= 360) return bar;
    // Sui telefoni più stretti "Prenotazioni" andrebbe a capo a metà parola.
    final theme = NavigationBarTheme.of(context);
    return NavigationBarTheme(
      data: theme.copyWith(
        labelTextStyle: WidgetStateProperty.resolveWith(
            (s) => theme.labelTextStyle?.resolve(s)?.copyWith(fontSize: 10)),
      ),
      child: bar,
    );
  }

  /// Le voci che non stanno nella barra in basso.
  void _openMore(BuildContext context, List<_NavItem> hidden) {
    final offset = _maxBottomItems - 1;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: kSurface,
      builder: (sheet) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < hidden.length; i++)
              ListTile(
                leading: _navIcon(hidden[i].$2, hidden[i].$4),
                title: Text(hidden[i].$1),
                selected: _index == offset + i,
                selectedColor: kPrimary,
                onTap: () {
                  Navigator.pop(sheet);
                  _select(offset + i);
                },
              ),
          ],
        ),
      ),
    );
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
          final isDesktop = constraints.maxWidth >= kDesktopWidth;
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
              onOpenAccount: openAccount,
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
            bottomNavigationBar: isDesktop ? null : _bottomBar(context, items),
          );
        });
      },
    );
  }
}

/// Oltre questo numero di voci la barra in basso non è più leggibile: le
/// ultime finiscono in "Altro".
const _maxBottomItems = 5;

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
    // Nelle finestre strette lo spazio va ai link del menu.
    final roomy = MediaQuery.sizeOf(context).width >= 1240;
    return Container(
      color: overPhoto ? null : kNight,
      padding: EdgeInsets.symmetric(horizontal: roomy ? 48 : 24, vertical: 14),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentWidth),
        child: Row(
          children: [
            InkWell(
              onTap: () => onSelect(0),
              child: BrandLogo(tagline: roomy ? t.footerTagline : null),
            ),
            SizedBox(width: roomy ? 36 : 16),
            Expanded(
              child: _NavLinks(items: items, index: index, onSelect: onSelect),
            ),
            const SizedBox(width: 12),
            const CityPicker(),
            const SizedBox(width: 8),
            const LanguagePicker(),
            if (roomy) ...[
              const SizedBox(width: 14),
              GoldButton(t.ctaButton, onPressed: () => onSelect(1)),
            ],
            if (_showsCart()) ...[
              const SizedBox(width: 12),
              const CartButton(),
            ],
            if (appState.currentUser != null) ...[
              const SizedBox(width: 12),
              const _UserButton(),
            ],
          ],
        ),
      ),
    );
  }
}

/// I link che stanno nella barra, con misura del testo reale (cambia con la
/// lingua); gli altri finiscono nel menu "Altro".
class _NavLinks extends StatelessWidget {
  const _NavLinks(
      {required this.items, required this.index, required this.onSelect});
  final List<_NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  String _label(_NavItem item) =>
      item.$4 is ApprovalsScreen && appState.pendingRegistrations > 0
          ? '${item.$1} (${appState.pendingRegistrations})'
          : item.$1;

  double _width(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: _NavLink.textStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width + _NavLink.padding * 2;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final more = l10n(context).navMore;
    return LayoutBuilder(builder: (context, c) {
      final widths = [for (final i in items) _width(context, _label(i))];
      final total = widths.fold(0.0, (a, b) => a + b);
      var shown = items.length;
      // Un po' di margine: il peso del carattere cambia sul link attivo.
      if (total + 16 > c.maxWidth) {
        final room = c.maxWidth - _width(context, more) - 20;
        var used = 0.0;
        shown = 0;
        while (shown < items.length && used + widths[shown] <= room) {
          used += widths[shown++];
        }
      }
      final row = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < shown; i++)
            _NavLink(
              label: _label(items[i]),
              selected: i == index,
              onTap: () => onSelect(i),
            ),
          if (shown < items.length)
            PopupMenuButton<int>(
              tooltip: more,
              initialValue: index,
              onSelected: onSelect,
              itemBuilder: (_) => [
                for (var i = shown; i < items.length; i++)
                  PopupMenuItem(value: i, child: Text(_label(items[i]))),
              ],
              child: _NavLink(
                label: more,
                selected: index >= shown,
                showArrow: true,
              ),
            ),
        ],
      );
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: row,
      );
    });
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.selected,
    this.onTap,
    this.showArrow = false,
  });
  final String label;
  final bool selected;

  /// Null quando il tocco lo gestisce il menu che lo contiene.
  final VoidCallback? onTap;
  final bool showArrow;

  static const padding = 13.0;
  static const textStyle =
      TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600);

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: padding, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: textStyle.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? kGold : Colors.white)),
                  if (showArrow)
                    Icon(Icons.expand_more,
                        size: 16, color: selected ? kGold : Colors.white),
                ],
              ),
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
            // Sui telefoni più stretti il logo si rimpicciolisce.
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: BrandLogo(),
              ),
            ),
            SizedBox(width: 8),
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
            // Su uno schermo stretto il nome della città si accorcia.
            const Flexible(child: CityPicker()),
            const SizedBox(width: 8),
          ],
          const LanguagePicker(),
          if (_showsCart()) ...[
            const SizedBox(width: 8),
            const CartButton(),
          ],
          if (appState.currentUser != null) ...[
            const SizedBox(width: 8),
            const _UserButton(),
          ],
        ],
      );
}

/// Account di chi è collegato; dopo il logout si torna alla pagina di prima.
class _AccountPage extends StatelessWidget {
  const _AccountPage();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(l10n(context).navAccount)),
        body: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            if (appState.currentUser != null) return const AccountScreen();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) Navigator.of(context).maybePop();
            });
            return const SizedBox.shrink();
          },
        ),
      );
}

/// Pallino dell'utente collegato: porta alla pagina Account.
class _UserButton extends StatelessWidget {
  const _UserButton();

  @override
  Widget build(BuildContext context) => InkWell(
        key: const ValueKey('user-avatar'),
        customBorder: const CircleBorder(),
        onTap: () =>
            context.findAncestorStateOfType<_AppShellState>()?.openAccount(),
        child: UserAvatar(user: appState.currentUser!),
      );
}
