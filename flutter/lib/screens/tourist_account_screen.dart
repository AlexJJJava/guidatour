import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'tour_detail_screen.dart';

/// Area personale del turista: preferiti, carrello e storico richieste.
class TouristAccountScreen extends StatelessWidget {
  const TouristAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        if (user == null) return const SizedBox.shrink();
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ciao ${user.name}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: kInk)),
                          Text(user.email,
                              style: const TextStyle(color: kMuted)),
                        ],
                      ),
                    ),
                    TextButton(
                        onPressed: appState.logout, child: const Text('Esci')),
                  ],
                ),
              ),
              TabBar(
                tabs: [
                  const Tab(text: 'Preferiti'),
                  Tab(text: 'Carrello (${appState.cart.length})'),
                  const Tab(text: 'Storico'),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [_Favorites(), _Cart(), _History()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Favorites extends StatelessWidget {
  const _Favorites();

  @override
  Widget build(BuildContext context) {
    final favs = appState.favoriteTours;
    return PageBody(
      maxWidth: 900,
      child: favs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child: Text(
                      'Nessun preferito. Tocca il cuore su un tour per salvarlo.')),
            )
          : ResponsiveGrid(children: [
              for (final t in favs)
                TourCard(tour: t, onTap: () => openTour(context, t)),
            ]),
    );
  }
}

class _Cart extends StatefulWidget {
  const _Cart();

  @override
  State<_Cart> createState() => _CartState();
}

class _CartState extends State<_Cart> {
  bool _privacy = false;

  @override
  Widget build(BuildContext context) {
    final items = appState.cart;
    if (items.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('Il carrello è vuoto. Aggiungi i tour che ti interessano '
            'dalla scheda del tour.'),
      ));
    }
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const InfoBanner(
              'Nessun pagamento online: inviamo una richiesta non vincolante per '
              'ogni tour. Ogni guida ti contatterà per confermare disponibilità e pagamento.'),
          const SizedBox(height: 16),
          for (final item in items) _line(context, item),
          const Divider(height: 32),
          Row(
            children: [
              const Text('Totale stimato',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(fmtPrice(appState.cartTotal),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kPrimary)),
            ],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _privacy,
            onChanged: (v) => setState(() => _privacy = v ?? false),
            title: const Text(
                'Acconsento a condividere nome ed email con le guide per essere '
                'ricontattato.',
                style: TextStyle(fontSize: 13)),
          ),
          FilledButton(
            onPressed: !_privacy
                ? null
                : () {
                    final n = appState.checkoutCart();
                    snack(context,
                        '$n richieste inviate. Le trovi nello Storico.');
                    setState(() => _privacy = false);
                  },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Invia le richieste'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, CartItem item) {
    final t = appState.tourById(item.tourId);
    if (t == null) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E8E3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => openTour(context, t),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('${fmtDate(t.start)} · ${fmtPrice(t.price)} a persona',
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: item.people > 1
                  ? () => appState.setCartPeople(item, item.people - 1)
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('${item.people}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            IconButton(
              onPressed: () => appState.setCartPeople(item, item.people + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
            IconButton(
              tooltip: 'Rimuovi',
              onPressed: () => appState.removeFromCart(item),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _History extends StatelessWidget {
  const _History();

  @override
  Widget build(BuildContext context) {
    final reqs = appState.myRequests;
    return PageBody(
      maxWidth: 900,
      child: reqs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Non hai ancora inviato richieste.')),
            )
          : Column(
              children: [
                for (final r in reqs)
                  Builder(builder: (context) {
                    final t = appState.tourById(r.tourId);
                    final color = switch (r.status) {
                      'Confermata' => kPrimary,
                      'Rifiutata' => Colors.red,
                      _ => kMuted,
                    };
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: Text(t?.title ?? 'Tour non più disponibile'),
                      subtitle: Text(
                          '${fmtDate(r.createdAt)} · ${r.people} persone'
                          '${t == null ? '' : ' · tour del ${fmtDate(t.start)}'}'),
                      trailing: Text(r.status,
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w700)),
                      onTap: t == null ? null : () => openTour(context, t),
                    );
                  }),
              ],
            ),
    );
  }
}
