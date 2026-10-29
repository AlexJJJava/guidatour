import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'auth_screen.dart';
import 'tour_detail_screen.dart';

/// Carrello dell'utente: se non è loggato mostra l'accesso, altrimenti
/// (per un account turista) le richieste da inviare, senza pagamento online.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final t = l10n(context);
        if (appState.currentUser == null) return const AuthScreen();
        if (!appState.isTourist) {
          return PageBody(
            maxWidth: 480,
            child: InfoBanner(t.cartTouristOnly),
          );
        }
        return const _CartBody();
      },
    );
  }
}

class _CartBody extends StatefulWidget {
  const _CartBody();

  @override
  State<_CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<_CartBody> {
  bool _privacy = false;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final items = appState.cart;
    if (items.isEmpty) {
      return Center(
          child: EmptyState(
              icon: Icons.shopping_cart_outlined, message: t.cartEmpty));
    }
    return PageBody(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.cartTitle,
              style: const TextStyle(
                  fontFamily: kSerif,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: kInk)),
          const SizedBox(height: 16),
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
            title:
                Text(t.cartShareConsent, style: const TextStyle(fontSize: 13)),
          ),
          FilledButton(
            onPressed: !_privacy
                ? null
                : () async {
                    try {
                      final n = await appState.checkoutCart();
                      if (!context.mounted) return;
                      snack(context, t.cartCheckoutDone(n, t.navBookings));
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
                  ? () => runOrSnack(context,
                      () => appState.setCartPeople(item, item.people - 1))
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text('${item.people}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            IconButton(
              onPressed: () => runOrSnack(
                  context, () => appState.setCartPeople(item, item.people + 1)),
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
