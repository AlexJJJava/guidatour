import 'package:flutter/material.dart';

import '../l10n/labels.dart';
import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'auth_screen.dart';
import 'cart_screen.dart';
import 'tour_detail_screen.dart';

/// Richieste: per il professionista quelle ricevute; il turista trova le sue
/// nel carrello (non ha più questa voce di menu).
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final user = appState.currentUser;
        if (user == null) return const AuthScreen();
        return user.role.isProfessional
            ? const _ReceivedBookings()
            : const CartScreen();
      },
    );
  }
}

/// Etichetta colorata dello stato di una richiesta.
Widget _statusPill(BuildContext context, String status) => StatusPill(
      requestStatusLabel(context, status),
      tone: switch (status) {
        'confermata' => PillTone.ok,
        'rifiutata' => PillTone.alert,
        _ => PillTone.waiting,
      },
    );

/// Miniatura della categoria del tour, a sinistra delle schede.
Widget _thumb(Tour? tour) => ClipRRect(
      borderRadius: BorderRadius.circular(kRadiusSm),
      child: tour == null
          ? Container(
              width: 64,
              height: 64,
              color: kSand,
              child: const Icon(Icons.event_busy, color: kMuted))
          : Image.asset(categoryImage(tour.category),
              width: 64, height: 64, fit: BoxFit.cover),
    );

/// Richieste inviate dal turista, con lo stato; quelle con una risposta
/// nuova sono segnalate.
class SentRequestsList extends StatelessWidget {
  const SentRequestsList({super.key});

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final reqs = appState.myRequests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (reqs.isEmpty)
          EmptyState(icon: Icons.event_busy, message: t.historyEmpty)
        else
          for (final r in reqs)
            Builder(builder: (context) {
              final tour = appState.tourById(r.tourId);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: tour == null ? null : () => openTour(context, tour),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        _thumb(tour),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tour?.title ?? t.tourUnavailable,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                  tour == null
                                      ? t.historyLine(
                                          fmtDate(r.createdAt), r.people)
                                      : t.historyLineWithTourDate(
                                          fmtDate(r.createdAt),
                                          r.people,
                                          fmtDate(r.start ?? tour.nextStart)),
                                  style: const TextStyle(
                                      color: kMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _statusPill(context, r.status),
                            if (appState.isNewAnswer(r)) ...[
                              const SizedBox(height: 4),
                              Text(t.cartNewAnswer,
                                  key: ValueKey('new-answer-${r.id}'),
                                  style: const TextStyle(
                                      color: kPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
      ],
    );
  }
}

/// Richieste ricevute dal professionista per i propri tour.
class _ReceivedBookings extends StatelessWidget {
  const _ReceivedBookings();

  @override
  Widget build(BuildContext context) {
    final t = l10n(context);
    final reqs = appState.requests;
    return PageBody(
      maxWidth: 900,
      title: t.bookingsTitleReceived,
      subtitle: t.pageBookingsReceivedSub,
      icon: Icons.inbox_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reqs.isEmpty)
            EmptyState(icon: Icons.mail_outline, message: t.noRequestsReceived),
          for (final r in reqs)
            Builder(builder: (context) {
              final tour = appState.tourById(r.tourId);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _thumb(tour),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.nameAndPeople(r.name, r.people),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                Text(tour?.title ?? t.tourUnavailable,
                                    style: const TextStyle(color: kPrimary)),
                                if (r.start != null)
                                  Text(t.requestForDate(fmtDate(r.start!)),
                                      key: ValueKey('request-date-${r.id}'),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                Text(
                                    '${r.email}'
                                    '${r.phone.isEmpty ? '' : ' · ${r.phone}'}',
                                    style: const TextStyle(
                                        color: kMuted, fontSize: 13)),
                              ],
                            ),
                          ),
                          if (r.status != 'inviata') ...[
                            const SizedBox(width: 10),
                            _statusPill(context, r.status),
                          ],
                        ],
                      ),
                      if (r.message.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kPageYellow,
                            borderRadius: BorderRadius.circular(kRadiusSm),
                          ),
                          child: Text('“${r.message}”',
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic, height: 1.4)),
                        ),
                      ],
                      if (r.status == 'inviata') ...[
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: kDanger),
                              onPressed: () => runOrSnack(
                                  context,
                                  () => appState.setRequestStatus(
                                      r, 'rifiutata')),
                              icon: const Icon(Icons.close, size: 18),
                              label: Text(t.reject),
                            ),
                            FilledButton.icon(
                              onPressed: () => runOrSnack(
                                  context,
                                  () => appState.setRequestStatus(
                                      r, 'confermata')),
                              icon: const Icon(Icons.check, size: 18),
                              label: Text(t.confirm),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
