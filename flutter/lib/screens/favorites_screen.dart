import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../state.dart';
import '../widgets.dart';
import 'auth_screen.dart';
import 'tour_detail_screen.dart';

/// Preferiti dell'utente: se non è loggato mostra l'accesso, altrimenti
/// (per un account turista) la lista dei tour salvati.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
            child: InfoBanner(t.favoritesTouristOnly),
          );
        }
        final favs = appState.favoriteTours;
        return PageBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.favoritesTitle,
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kInk)),
              const SizedBox(height: 20),
              if (favs.isEmpty)
                EmptyState(
                    icon: Icons.favorite_border, message: t.favoritesEmpty)
              else
                ResponsiveGrid(children: [
                  for (final tour in favs)
                    TourCard(tour: tour, onTap: () => openTour(context, tour)),
                ]),
            ],
          ),
        );
      },
    );
  }
}
