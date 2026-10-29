import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'auth_screen.dart';
import 'poster_screen.dart';
import 'tour_form_screen.dart';

/// Tour pubblicati dal professionista loggato: crea, modifica, elimina,
/// genera QR/locandina o propone il tour a un collega.
class MyToursScreen extends StatelessWidget {
  const MyToursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        if (user == null) return const AuthScreen();
        final t = l10n(context);
        final mine =
            appState.myTours.where((tour) => tour.guideId == user.id).toList();
        return PageBody(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.dashTabMyTours,
                  style: const TextStyle(
                      fontFamily: kSerif,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kInk)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TourFormScreen())),
                icon: const Icon(Icons.add),
                label: Text(t.newTour),
              ),
              const SizedBox(height: 16),
              if (mine.isEmpty) Text(t.dashNoToursYet),
              for (final tour in mine) _TourCard(user: user, tour: tour),
            ],
          ),
        );
      },
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({required this.user, required this.tour});
  final Guide user;
  final Tour tour;

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tour.title,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text(
                t.dashTourLine(fmtDate(tour.start), fmtPrice(tour.price),
                    tour.seats, tour.visits, tour.scans),
                style: const TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PosterScreen(tour: tour))),
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: Text(t.qrAndPoster),
                ),
                OutlinedButton.icon(
                  onPressed: () => _propose(context, tour),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: Text(t.proposeToColleague),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final updated = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                            builder: (_) => TourFormScreen(existing: tour)));
                    if (updated == true && context.mounted) {
                      snack(context, t.tourUpdated);
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(t.editTour),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _delete(context, tour),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(t.deleteTour),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Tour tour) async {
    final t = l10n(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.confirmDeleteTourTitle),
        content: Text(t.confirmDeleteTourBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.deleteTour),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await appState.deleteTour(tour.id);
      if (context.mounted) snack(context, t.tourDeleted);
    } catch (e) {
      if (context.mounted) snack(context, '$e');
    }
  }

  Future<void> _propose(BuildContext context, Tour tour) async {
    final t = l10n(context);
    final candidates = appState.guides
        .where((g) => g.id != user.id && g.role == Role.guida)
        .toList();
    final chosen = await showDialog<Guide>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(t.chooseRecipientGuide),
        children: [
          if (candidates.isEmpty)
            Padding(
                padding: const EdgeInsets.all(20),
                child: Text(t.noGuideAvailable)),
          for (final g in candidates)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, g),
              child: Text(
                  '${g.name} · ${g.languages.map((l) => languageLabel(context, l)).join(', ')}'),
            ),
        ],
      ),
    );
    if (chosen == null) return;
    try {
      await appState.proposeAssignment(tour, chosen);
      if (context.mounted) snack(context, t.proposalSentTo(chosen.name));
    } catch (e) {
      if (context.mounted) snack(context, '$e');
    }
  }
}
