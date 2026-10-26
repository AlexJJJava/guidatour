import 'package:flutter/material.dart';

import '../l10n/labels.dart';
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
        final t = l10n(context);
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
                          Text(t.greetingHello(user.name),
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
                        onPressed: appState.logout, child: Text(t.logout)),
                  ],
                ),
              ),
              TabBar(
                tabs: [
                  Tab(text: t.navFavorites),
                  Tab(text: '${t.navCart} (${appState.cart.length})'),
                  Tab(text: t.bookingsTitleSent),
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
    final t = l10n(context);
    final favs = appState.favoriteTours;
    return PageBody(
      maxWidth: 900,
      child: favs.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text(t.favoritesEmpty)),
            )
          : ResponsiveGrid(children: [
              for (final tour in favs)
                TourCard(tour: tour, onTap: () => openTour(context, tour)),
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
    final t = l10n(context);
    final items = appState.cart;
    if (items.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(t.cartEmpty),
      ));
    }
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoBanner(t.cartNoPaymentInfo),
          const SizedBox(height: 16),
          for (final item in items) _line(context, item),
          const Divider(height: 32),
          Row(
            children: [
              Text(t.cartTotalLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
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
            title: Text(t.cartShareConsent, style: const TextStyle(fontSize: 13)),
          ),
          FilledButton(
            onPressed: !_privacy
                ? null
                : () async {
                    try {
                      final n = await appState.checkoutCart();
                      if (!context.mounted) return;
                      snack(context, t.cartCheckoutDone(n, t.bookingsTitleSent));
                      setState(() => _privacy = false);
                    } catch (e) {
                      if (context.mounted) snack(context, '$e');
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(t.cartSubmit),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, CartItem item) {
    final t = l10n(context);
    final tour = appState.tourById(item.tourId);
    if (tour == null) return const SizedBox.shrink();
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
                onTap: () => openTour(context, tour),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tour.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(
                        t.cartLinePricePerPerson(
                            fmtDate(tour.start), fmtPrice(tour.price)),
                        style: const TextStyle(color: kMuted, fontSize: 12)),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: item.people > 1
                  ? () => runOrSnack(context, () =>
                      appState.setCartPeople(item, item.people - 1))
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('${item.people}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            IconButton(
              onPressed: () => runOrSnack(context, () =>
                  appState.setCartPeople(item, item.people + 1)),
              icon: const Icon(Icons.add_circle_outline),
            ),
            IconButton(
              tooltip: t.remove,
              onPressed: () =>
                  runOrSnack(context, () => appState.removeFromCart(item)),
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
    final t = l10n(context);
    final reqs = appState.myRequests;
    return PageBody(
      maxWidth: 900,
      child: reqs.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text(t.historyEmpty)),
            )
          : Column(
              children: [
                for (final r in reqs)
                  Builder(builder: (context) {
                    final tour = appState.tourById(r.tourId);
                    final color = switch (r.status) {
                      'confermata' => kPrimary,
                      'rifiutata' => Colors.red,
                      _ => kMuted,
                    };
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history),
                      title: Text(tour?.title ?? t.tourUnavailable),
                      subtitle: Text(tour == null
                          ? t.historyLine(fmtDate(r.createdAt), r.people)
                          : t.historyLineWithTourDate(fmtDate(r.createdAt),
                              r.people, fmtDate(tour.start))),
                      trailing: Text(requestStatusLabel(context, r.status),
                          style: TextStyle(
                              color: color, fontWeight: FontWeight.w700)),
                      onTap: tour == null ? null : () => openTour(context, tour),
                    );
                  }),
              ],
            ),
    );
  }
}
