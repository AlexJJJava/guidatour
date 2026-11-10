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
import 'screens/admin_screen.dart';
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
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm));
    OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusSm),
        borderSide: BorderSide(color: c, width: w));
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
          theme: withAppText(ThemeData(
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
              error: kDanger,
            ),
            scaffoldBackgroundColor: kCream,
            fontFamily: 'Inter',
            // Campi di testo: sfondo sabbia chiaro, bordo oro quando attivi.
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: kCream,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: field(kLine),
              enabledBorder: field(kLine),
              focusedBorder: field(kPrimary, 1.6),
              errorBorder: field(kDanger),
              focusedErrorBorder: field(kDanger, 1.6),
              disabledBorder: field(kLine.withValues(alpha: 0.6)),
              labelStyle: const TextStyle(color: kMuted),
              floatingLabelStyle:
                  const TextStyle(color: kPrimary, fontWeight: FontWeight.w600),
              hintStyle: TextStyle(color: kMuted.withValues(alpha: 0.8)),
              prefixIconColor: kMuted,
              suffixIconColor: kMuted,
            ),
            // Messaggi: fascia blu notte mobile, testo crema, azione oro.
            snackBarTheme: SnackBarThemeData(
              behavior: SnackBarBehavior.floating,
              backgroundColor: kNight,
              contentTextStyle:
                  const TextStyle(color: kCream, fontSize: 14, height: 1.35),
              actionTextColor: kGold,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusSm)),
              elevation: 4,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: kSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadius)),
              titleTextStyle: const TextStyle(
                  fontFamily: kSerif,
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: kInk),
              contentTextStyle:
                  const TextStyle(fontSize: 14, height: 1.45, color: kInk),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: kSurface,
              surfaceTintColor: Colors.transparent,
              showDragHandle: true,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(kRadius * 1.5))),
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: kPrimary,
              linearTrackColor: kLine,
            ),
            tooltipTheme: TooltipThemeData(
              decoration: BoxDecoration(
                  color: kNight, borderRadius: BorderRadius.circular(6)),
              textStyle: const TextStyle(color: kCream, fontSize: 12),
            ),
            listTileTheme: const ListTileThemeData(
              iconColor: kPrimary,
              titleTextStyle: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: kInk),
              subtitleTextStyle:
                  TextStyle(fontFamily: 'Inter', fontSize: 13, color: kMuted),
            ),
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
              elevation: 2,
              shadowColor: const Color(0xFF6B4A12).withValues(alpha: 0.16),
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
              shape: StadiumBorder(),
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
            popupMenuTheme: PopupMenuThemeData(
              color: kSurface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusSm),
                  side: const BorderSide(color: kLine)),
            ),
            scrollbarTheme: ScrollbarThemeData(
              thumbColor: WidgetStatePropertyAll(kGold.withValues(alpha: 0.7)),
              trackColor: const WidgetStatePropertyAll(kSurface),
              trackBorderColor: const WidgetStatePropertyAll(kLine),
            ),
          )),
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
                  // Barra sottile dorata: più discreta di una rotellina accanto al logo.
                  const SizedBox(
                    width: 180,
                    child: LinearProgressIndicator(
                        minHeight: 4,
                        borderRadius: BorderRadius.all(Radius.circular(2))),
                  ),
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

/// Data scelta nella pagina pubblica del tour (`&date=` in ISO), se valida.
DateTime? tourLinkDate(Uri uri) =>
    DateTime.tryParse(uri.queryParameters['date'] ?? '')?.toLocal();

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

  /// Navigatore delle pagine interne: nuovo a ogni cambio di voce del menu.
  var _navKey = GlobalKey<NavigatorState>();

  /// Pagine aperte sopra quella del menu (0 = solo quella del menu).
  int _depth = 0;

  /// Un contatore per ogni navigatore: quello vecchio, sostituito senza
  /// chiudere le sue pagine, non deve più contare.
  late var _observer = _newObserver();

  _DepthObserver _newObserver() {
    late final _DepthObserver observer;
    observer = _DepthObserver((depth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || observer != _observer || depth == _depth) return;
        setState(() => _depth = depth);
      });
    });
    return observer;
  }

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
    final inner = _navKey.currentContext;
    if (tour == null) {
      snack(context, l10n(context).tourUnavailable);
    } else if (inner != null) {
      openTour(inner, tour, fromQr: fromQr, date: tourLinkDate(Uri.base));
    }
  }

  /// 'guest' | 'tourist' | 'pro': quando cambia (login/logout/cambio ruolo)
  /// il menu cambia voci, quindi si torna alla prima.
  String? _lastKind;

  /// Tipo della pagina di menu mostrata all'ultimo disegno (Null = Scopri):
  /// dopo login o logout si resta lì se il nuovo menu la contiene ancora.
  Type _rootType = Null;

  /// Pagine aperte con un nome (carrello, account) nel navigatore attuale:
  /// premere di nuovo il pulsante riporta a quella pagina invece di aprirne
  /// una seconda uguale.
  final _openNames = <String>{};

  /// Account aperto dal pallino: dopo il logout si mostra la voce Account.
  bool get _accountOpen => _openNames.contains(_accountRoute);
  static const _accountRoute = 'account';

  /// Login, logout o cambio di ruolo: si resta sulla stessa pagina se è
  /// ancora consentita, altrimenti si torna a Scopri.
  void _keepPage(List<_NavItem> items, {required bool wasGuest}) {
    _tabHistory.clear();
    final nowGuest = appState.currentUser == null;
    if (nowGuest && _accountOpen) {
      _reset(items.indexWhere((i) => i.$4 is AccountScreen));
      return;
    }
    if (!nowGuest && _rootType == AccountScreen) {
      // La voce Account non c'è più: Scopri, con l'Account aperto sopra.
      _reset(0);
      // Segnato subito: il menu deve già saperlo prima che la pagina si apra.
      _openNames.add(_accountRoute);
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _open(const _AccountPage(), name: _accountRoute, force: true));
      return;
    }
    final same = items.indexWhere((i) => i.$4.runtimeType == _rootType);
    if (same < 0) {
      _reset(0);
      return;
    }
    // Stessa pagina: il navigatore resta, cambia solo la voce di menu.
    _index = same;
    // Le pagine aperte sopra potevano essere riservate: al logout si chiudono.
    if (!wasGuest) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _navKey.currentState?.popUntil((r) => r.isFirst));
    }
  }

  void _select(int i) {
    // Sulla stessa voce si torna alla sua pagina principale.
    if (i == _index) {
      _navKey.currentState?.popUntil((r) => r.isFirst);
      return;
    }
    setState(() {
      // Dal menu la pagina Tour si apre senza filtri.
      if (i == 1) {
        _searchQuery = '';
        _searchCategory = null;
        _searchLanguage = null;
      }
      _remember();
      _reset(i);
    });
  }

  /// Voci visitate prima di quella attuale: "indietro" (browser o telefono),
  /// quando nella voce non c'è più niente da chiudere, torna alla precedente.
  final _tabHistory = <int>[];

  void _remember() {
    _tabHistory.add(_index);
    if (_tabHistory.length > 30) _tabHistory.removeAt(0);
  }

  /// Indietro: prima si chiudono le pagine aperte nella voce, poi si torna
  /// alla voce precedente (la pagina Tour con la ricerca che aveva).
  void _back() {
    final nav = _navKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.maybePop();
    } else if (_tabHistory.isNotEmpty) {
      setState(() => _reset(_tabHistory.removeLast()));
    }
  }

  /// La pagina Tour comunica ricerca e filtri: tornandoci con "indietro"
  /// si ritrovano. Niente setState: servono solo alla prossima apertura.
  void _rememberSearch(String query, String? category, String? language) {
    _searchQuery = query;
    _searchCategory = category;
    _searchLanguage = language;
  }

  /// Ricerca e categoria con cui aprire la voce "Tour" (dalla home).
  String _searchQuery = '';
  String? _searchCategory;
  String? _searchLanguage;

  /// Cambia a ogni ricerca dalla home: la pagina Tour riparte con i nuovi
  /// filtri anche se era già aperta.
  int _searchSeq = 0;

  /// "Cerca tour" e i cerchi delle categorie in home: si passa alla voce
  /// "Tour" (sempre la seconda) con i risultati, non una pagina sopra Scopri.
  void _openSearch({String query = '', String? category}) {
    setState(() {
      _searchQuery = query;
      _searchCategory = category;
      _searchLanguage = null;
      _searchSeq++;
      if (_index != 1) _remember();
      _reset(1);
    });
  }

  void _reset(int i) {
    _index = i;
    _navKey = GlobalKey<NavigatorState>();
    _observer = _newObserver();
    _depth = 0;
    _openNames.clear();
  }

  /// Apre una pagina sotto intestazione e footer. Con [name], se quella
  /// pagina è già aperta si torna lì (chiudendo quelle sopra) invece di
  /// aprirne un'altra uguale; [force] apre comunque (nome già segnato).
  void _open(Widget page, {String? name, bool force = false}) {
    final nav = _navKey.currentState;
    if (nav == null) return;
    if (name != null && !force && _openNames.contains(name)) {
      nav.popUntil((r) => r.settings.name == name || r.isFirst);
      return;
    }
    if (name != null) _openNames.add(name);
    final key = _navKey;
    nav
        .push(MaterialPageRoute(
            settings: RouteSettings(name: name), builder: (_) => page))
        .then((_) {
      // Solo se il navigatore è ancora lo stesso (cambio voce = elenco nuovo).
      if (name != null && key == _navKey) _openNames.remove(name);
    });
  }

  /// Chi è collegato arriva all'Account dal pallino, non dal menu.
  void openAccount() {
    if (appState.currentUser == null) {
      _select(_navItems(context).length - 1);
    } else {
      _open(const _AccountPage(), name: _accountRoute);
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
          t.navRequests,
          Icons.inbox_outlined,
          Icons.inbox,
          const BookingsScreen(),
        ),
      ]);
    } else {
      // Le richieste inviate dal turista stanno nel carrello.
      items.add((
        t.navFavorites,
        Icons.favorite_border,
        Icons.favorite,
        const FavoritesScreen(),
      ));
    }
    if (user != null && user.isAdmin) {
      items.add((
        t.navManage,
        Icons.how_to_reg_outlined,
        Icons.how_to_reg,
        const AdminScreen(),
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
              isLabelVisible: hidden.any((i) => i.$4 is AdminScreen) &&
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
        final items = _navItems(context);
        if (kind != _lastKind) {
          final previous = _lastKind;
          _lastKind = kind;
          if (previous == null) {
            _reset(0);
          } else {
            _keepPage(items, wasGuest: previous == 'guest');
          }
        }
        if (_index >= items.length) _reset(0);
        _rootType = items[_index].$4.runtimeType;
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
          final home = _index == 0;
          final root = home
              ? HomeScreen(
                  header: topBar(overPhoto: true),
                  onOpenSearch: () => _select(1),
                  onOpenAccount: openAccount,
                )
              : items[_index].$4 is SearchScreen
                  ? SearchScreen(
                      key: ValueKey('search-$_searchSeq'),
                      initialQuery: _searchQuery,
                      initialCategory: _searchCategory,
                      initialLanguage: _searchLanguage)
                  : items[_index].$4!;
          // In home l'intestazione sta sopra la foto; nelle altre pagine in alto.
          final showHeader = !home || _depth > 0;
          // Indietro del browser o del telefono: pagine aperte, poi voci
          // visitate; solo quando non resta niente esce dall'app.
          final inner = PopScope(
            canPop: _depth == 0 && _tabHistory.isEmpty,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _back();
            },
            child: Navigator(
              key: _navKey,
              observers: [_observer],
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (context) => ShellScope.of(context)!.root,
              ),
            ),
          );
          final Widget content;
          if (isDesktop) {
            content = Column(
              children: [
                if (showHeader) topBar(overPhoto: false),
                Expanded(child: inner),
              ],
            );
          } else {
            content = Column(
              children: [
                if (showHeader) const _MobileTopBar(solid: true),
                Expanded(child: inner),
              ],
            );
          }
          final body = ShellScope(
            goHome: () => _select(0),
            open: _open,
            openSearch: _openSearch,
            rememberSearch: _rememberSearch,
            root: root,
            child: content,
          );
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
  if (page is! AdminScreen || pending == 0) return Icon(icon);
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
      item.$4 is AdminScreen && appState.pendingRegistrations > 0
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
  /// [solid]: sfondo blu notte, per le pagine senza la foto della home.
  const _MobileTopBar({this.solid = false});
  final bool solid;

  @override
  Widget build(BuildContext context) => Container(
        color: solid ? kNight : null,
        padding: EdgeInsets.fromLTRB(
            20,
            solid ? MediaQuery.paddingOf(context).top + 10 : 14,
            16,
            solid ? 10 : 0),
        child: Row(
          children: [
            // Sui telefoni più stretti il logo si rimpicciolisce.
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  key: const ValueKey('header-logo'),
                  onTap: ShellScope.of(context)?.goHome,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: BrandLogo(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // La città resta accanto alla lingua: nelle finestre strette si
            // accorcia con i puntini invece di andare a capo.
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: (MediaQuery.sizeOf(context).width *
                          (MediaQuery.sizeOf(context).width < 400
                              ? 0.25
                              : 0.32))
                      .clamp(72.0, 200.0)),
              child: const CityPicker(),
            ),
            const SizedBox(width: 8),
            const _TopActions(),
          ],
        ),
      );
}

/// Il carrello è dei turisti (e di chi non ha ancora fatto l'accesso).
bool _showsCart() {
  final user = appState.currentUser;
  return user == null || !user.role.isProfessional;
}

/// Lingua, carrello e pallino in alto a destra su telefono.
class _TopActions extends StatelessWidget {
  const _TopActions();

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final user = appState.currentUser;
          if (user == null) return const SizedBox.shrink();
          return InkWell(
            key: const ValueKey('user-avatar'),
            customBorder: const CircleBorder(),
            onTap: () => context
                .findAncestorStateOfType<_AppShellState>()
                ?.openAccount(),
            child: UserAvatar(user: user),
          );
        },
      );
}

/// Conta le pagine aperte sopra quella del menu, per mostrare l'intestazione.
class _DepthObserver extends NavigatorObserver {
  _DepthObserver(this.onChange);
  final ValueChanged<int> onChange;
  int _routes = 0;

  void _set(int routes) {
    _routes = routes;
    onChange((_routes - 1).clamp(0, 1 << 20));
  }

  // Solo le pagine: menu (lingua, città) e finestre a comparsa non contano,
  // altrimenti aprirli in home farebbe comparire una seconda intestazione.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _set(_routes + 1);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _set(_routes - 1);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _set(_routes - 1);
  }
}
