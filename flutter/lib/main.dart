import 'package:flutter/material.dart';

import 'models.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/search_screen.dart';
import 'screens/tourist_account_screen.dart';
import 'screens/tour_detail_screen.dart';
import 'screens/whatsapp_optin.dart';
import 'state.dart';
import 'widgets.dart';

void main() {
  runApp(const GuidaTourApp());
}

class GuidaTourApp extends StatelessWidget {
  const GuidaTourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GuidaTour',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimary),
        scaffoldBackgroundColor: const Color(0xFFF7F8F4),
        fontFamily: 'Arial',
      ),
      home: const AppShell(),
    );
  }
}

const _tabs = [
  ('Scopri', Icons.explore_outlined, Icons.explore),
  ('Tour', Icons.search, Icons.search),
  ('Account', Icons.person_outline, Icons.person),
];

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
    final pages = [
      HomeScreen(
          onOpenSearch: () => _select(1), onOpenAccount: () => _select(2)),
      const SearchScreen(),
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
          child: Row(
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
                    for (final t in _tabs)
                      NavigationRailDestination(
                        icon: Icon(t.$2),
                        selectedIcon: Icon(t.$3),
                        label: Text(t.$1),
                      ),
                  ],
                ),
              Expanded(child: pages[_index]),
            ],
          ),
        ),
        bottomNavigationBar: isDesktop
            ? null
            : NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  for (final t in _tabs)
                    NavigationDestination(
                      icon: Icon(t.$2),
                      selectedIcon: Icon(t.$3),
                      label: t.$1,
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
                      label: const Text('Accedi'),
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
                      label: Text(c),
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
                  title: 'Prossimi tour a Roma',
                  action: 'Vedi tutti',
                  onAction: onOpenSearch),
              const SizedBox(height: 16),
              ResponsiveGrid(children: [
                for (final t in upcoming.take(6))
                  TourCard(tour: t, onTap: () => openTour(context, t)),
              ]),
              const SizedBox(height: 36),
              const WhatsAppOptInCard(source: 'Home'),
              const SizedBox(height: 28),
              _operatorBanner(isDesktop),
              const PlatformDisclaimer(),
            ],
          ),
        );
      },
    );
  }

  Widget _hero(BuildContext context, bool isDesktop) {
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
          const Text(
              'Tour e visite guidate a Roma, con chi la conosce davvero.',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1)),
          const SizedBox(height: 10),
          const Text(
              'Guide abilitate, accompagnatori e tour operator verificati. Scegli, scrivi alla guida, parti.',
              style: TextStyle(color: Color(0xFFD7E9E3), fontSize: 16)),
          const SizedBox(height: 22),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: Colors.white, foregroundColor: kPrimary),
            onPressed: onOpenSearch,
            icon: const Icon(Icons.search),
            label: const Text('Cerca un tour'),
          ),
        ],
      ),
    );
  }

  Widget _operatorBanner(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9D9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sei una guida o un operatore?',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3C3427))),
          SizedBox(height: 6),
          Text(
              'Pubblica il tuo tour in pochi minuti: pagina pubblica, QR code e locandina. '
              'Vai su “Area guide”.',
              style: TextStyle(color: Color(0xFF625846))),
        ],
      ),
    );
  }
}
